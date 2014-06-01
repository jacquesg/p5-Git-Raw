#include <raw/index.h>

int git_index_matched_path_cbb(const char *path, const char *pathspec, void *payload) {
	dSP;

	int rv = 0;
	SV *callback = (SV *) payload;

	if (callback == NULL)
		return rv;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(newSVpv(path, 0));
	mXPUSHs(pathspec ? newSVpv(pathspec, 0) : &PL_sv_undef);
	PUTBACK;

	call_sv(callback, G_SCALAR|G_EVAL);

	SPAGAIN;

	if (SvTRUE(ERRSV)) {
		rv = -1;
		(void) POPs;
	} else
		rv = POPi;

	FREETMPS;
	LEAVE;

	return rv;
}

/* vim: set syntax=xs ts=4 sw=4: */
