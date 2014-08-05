#ifndef LIBSSH2_COMPAT_H
#define LIBSSH2_COMPAT_H

struct _LIBSSH2_USERAUTH_KBDINT_PROMPT
{
	char* text;
	unsigned int length;
	unsigned char echo;
};

struct _LIBSSH2_USERAUTH_KBDINT_RESPONSE
{
	char* text;
	unsigned int length;
};

#endif
