//	aes_enc.h
//	2019-10-23	Markku-Juhani O. Saarinen <mjos@pqshield.com>
//	Copyright (c) 2019, PQShield Ltd. All rights reserved.

//	AES 128/192/256 block encryption (no dependencies)

#ifndef _AES_ENC_H_
#define _AES_ENC_H_

#include <stdint.h>
#include <stddef.h>

//	number of rounds
#define AES128_ROUNDS 10
#define AES192_ROUNDS 12
#define AES256_ROUNDS 14

//	expanded key size
#define AES128_RK_WORDS (4 * (AES128_ROUNDS + 1))
#define AES192_RK_WORDS (4 * (AES192_ROUNDS + 1))
#define AES256_RK_WORDS (4 * (AES256_ROUNDS + 1))

//	set encryption key
void aes128_enc_key(uint32_t rk[AES128_RK_WORDS], const uint8_t key[16]);
void aes192_enc_key(uint32_t rk[AES192_RK_WORDS], const uint8_t key[24]);
void aes256_enc_key(uint32_t rk[AES256_RK_WORDS], const uint8_t key[32]);

//	encrypt a block
void aes_enc_rounds(uint8_t ct[16], const uint8_t pt[16],
					const uint32_t rk[], int nr);

//	aliases
#define aes128_enc_ecb(ct, pt, rk) aes_enc_rounds(ct, pt, rk, AES128_ROUNDS);
#define aes192_enc_ecb(ct, pt, rk) aes_enc_rounds(ct, pt, rk, AES192_ROUNDS);
#define aes256_enc_ecb(ct, pt, rk) aes_enc_rounds(ct, pt, rk, AES256_ROUNDS);

#endif							/* _AES_ENC_H_ */
