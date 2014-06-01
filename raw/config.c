#include <raw/config.h>

int git_config_foreach_cbb(const git_config_entry *entry, void *payload) {
	dSP;
	int rv = 0;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(newSVpv(entry -> name, 0));
	mXPUSHs(newSVpv(entry -> value, 0));
	mXPUSHs(newSVuv(entry -> level));
	PUTBACK;

	call_sv((SV *) payload, G_SCALAR);

	SPAGAIN;

	rv = POPi;

	FREETMPS;
	LEAVE;

	return rv;
}

/* vim: set syntax=xs ts=4 sw=4: */
