//	saes32.v
//	2020-01-29	Markku-Juhani O. Saarinen <mjos@pqshield.com>
//	Copyright (c) 2020, PQShield Ltd. All rights reserved.

//	Proposed SAES32 instruction for lightweight AES, AES^-1, and SM4 (RV32).

//	Multiply by 0x02 in AES's GF(256) - LFSR style

module aes_xtime( output [7:0] out, input [7:0] in );
	assign	out = { in[6:0], 1'b0 } ^ ( in[7] ? 8'h1B : 8'h00 );
endmodule

//	aes encrypt

`ifndef SAES32_NO_AES

module aes_t( output [31:0] out, input [7:0] in, input f );

	wire [7:0] x;
	wire [7:0] x2;

	aes_sbox  sbox	( x,  in );
	aes_xtime lfsr1 ( x2, x	 );

	//	NOP / MixColumns MDS Matrix

	assign out = f ? { 24'b0, x } : { x ^ x2, x, x, x2 } ;

endmodule

`endif

//	aes decrypt

`ifndef SAES32_NO_AESI

module aesi_t( output [31:0] out, input [7:0] in, input f );

	wire [7:0] x;
	wire [7:0] x2;
	wire [7:0] x4;
	wire [7:0] x8;

	aesi_sbox  sbox	 ( x,  in );
	aes_xtime  lfsr1 ( x2, x  );			//	todo: reduce circuit depth
	aes_xtime  lfsr2 ( x4, x2 );
	aes_xtime  lfsr3 ( x8, x4 );

	//	NOP / Inverse MixColumns MDS Matrix

	assign out = f ? { 24'b0, x } :
		{ x ^ x2 ^ x8, x ^ x4 ^ x8, x ^ x8, x2 ^ x4 ^ x8 };

endmodule

`endif

//	sm4 encrypt / decrypt

`ifndef SAES32_NO_SM4

module sm4_t( output [31:0] out, input [7:0] in, input f );

	wire [7:0] x;

	sm4_sbox  sbox	( x,  in );

	//	Either L' or L linear layers (for keying and encrypt / decrypt)
	//	( this looks slightly odd due to the use of little-endian byte order )
	assign out = f ? { x[2:0], 5'b0, x[0], 2'b0 ,x[7:3], 1'b0, x[7:1], x } :
		{ x[5:0], x, x[7:6], x[7:2], x[1:0] ^ x[7:6], x[7:2] ^ x[5:0], x[1:0] };

endmodule

`endif

//	Combinatorial logic for the SAES32 instruction itself

module saes32(
	output	[31:0]	rd,					//	output register (wire!)
	input	[31:0]	rs1,				//	input register 1
	input	[31:0]	rs2,				//	input register 2
	input	[4:0]	fn					//	5-bit function specifier
);

	//	select input byte from rs2 according to fn[1:0]

	wire [7:0] x =	fn[1:0] == 2'b00 ?	rs2[ 7: 0] :
					fn[1:0] == 2'b01 ?	rs2[15: 8] :
					fn[1:0] == 2'b10 ?	rs2[23:16] :
										rs2[31:24];

	//	expand to 32 bits

`ifndef SAES32_NO_AES
	wire [31:0] aes_32;
	aes_t	aes		( aes_32,  x, fn[2] );
`endif

`ifndef SAES32_NO_AESI
	wire [31:0] aesi_32;
	aesi_t	aesi	( aesi_32, x, fn[2] );
`endif

`ifndef SAES32_NO_SM4
	wire [31:0] sm4_32;
	sm4_t	sm4		( sm4_32,  x, fn[2] );
`endif

	wire [31:0] y =
`ifndef SAES32_NO_AES
					fn[4:3] == 2'b00 ?	aes_32 :
`endif
`ifndef SAES32_NO_AESI
					fn[4:3] == 2'b01 ?	aesi_32 :
`endif
`ifndef SAES32_NO_SM4
					fn[4:3] == 2'b10 ?	sm4_32 :
`endif
					32'h00000000;

	//	rotate output

	wire [31:0] z = fn[1:0] == 2'b00 ?	y :
					fn[1:0] == 2'b01 ?	{ y[23: 0], y[31:24] } :
					fn[1:0] == 2'b10 ?	{ y[15: 0], y[31:16] } :
										{ y[ 7: 0], y[31: 8] };

	//	XOR the result with rs1

	assign	rd = z ^ rs1;

endmodule

