#ifndef GIT_RAW_CRED_H
#define GIT_RAW_CRED_H

#include "raw.h"

typedef struct {
	git_cred *cred;
	SV *callback;
} git_raw_cred;

#ifndef GIT_SSH
/* Reduces further conditional compile problems */
typedef struct _LIBSSH2_USERAUTH_KBDINT_PROMPT
{
	char* text;
	unsigned int length;
	unsigned char echo;
} LIBSSH2_USERAUTH_KBDINT_PROMPT;

typedef struct _LIBSSH2_USERAUTH_KBDINT_RESPONSE
{
	char* text;
	unsigned int length;
} LIBSSH2_USERAUTH_KBDINT_RESPONSE;
#endif


void git_ssh_interactive_cbb(const char *name, int name_len,
	const char *instruction, int instruction_len, int num_prompts,
	const LIBSSH2_USERAUTH_KBDINT_PROMPT *prompts, LIBSSH2_USERAUTH_KBDINT_RESPONSE *responses,
	void **abstract);

typedef git_raw_cred * Cred;

#endif

/* vim: set syntax=xs ts=4 sw=4: */
