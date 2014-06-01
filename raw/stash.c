#include <raw/stash.h>

int git_stash_foreach_cb(size_t i, const char *msg, const git_oid *oid, void *payload) {
	dSP;
	int rv = 0;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(newSVuv(i));
	mXPUSHs(newSVpv(msg, 0));
	mXPUSHs(git_oid_to_sv((git_oid *) oid));
	PUTBACK;

	call_sv((SV *) payload, G_SCALAR);

	SPAGAIN;

	rv = POPi;

	FREETMPS;
	LEAVE;

	return rv;
}

/* vim: set syntax=xs ts=4 sw=4: */
