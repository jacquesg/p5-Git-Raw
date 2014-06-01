#include <raw/filter.h>

void git_clean_filter_callbacks(git_filter_callbacks *cbs) {
	if (cbs -> initialize) {
		SvREFCNT_dec(cbs -> initialize);
		cbs -> initialize = NULL;
	}

	if (cbs -> shutdown) {
		SvREFCNT_dec(cbs -> shutdown);
		cbs -> shutdown = NULL;
	}

	if (cbs -> check) {
		SvREFCNT_dec(cbs -> check);
		cbs -> check = NULL;
	}

	if (cbs -> apply) {
		SvREFCNT_dec(cbs -> apply);
		cbs -> apply = NULL;
	}

	if (cbs -> cleanup) {
		SvREFCNT_dec(cbs -> cleanup);
		cbs -> cleanup = NULL;
	}
}

int git_filter_init_cbb(git_filter *filter) {
	dSP;

	int rv = 0;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUTBACK;

	call_sv(((git_raw_filter *) filter) -> callbacks.initialize, G_EVAL|G_SCALAR);

	SPAGAIN;

	if (SvTRUE(ERRSV)) {
		rv = -1;
		(void) POPs;
	} else {
		rv = POPi;
	}

	FREETMPS;
	LEAVE;

	return rv;
}

void git_filter_shutdown_cbb(git_filter *filter) {
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUTBACK;

	call_sv(((git_raw_filter *) filter) -> callbacks.shutdown, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;
}

int git_filter_check_cbb(git_filter *filter, void **payload,
	const git_filter_source *src, const char **attr_values) {
	dSP;

	int rv = 0;
	SV *filter_source = NULL;

	GIT_NEW_OBJ(
		filter_source, "Git::Raw::Filter::Source", (void *) src
	);

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(filter_source);
	PUTBACK;

	call_sv(((git_raw_filter *) filter) -> callbacks.check, G_EVAL|G_SCALAR);

	SPAGAIN;

	if (SvTRUE(ERRSV)) {
		rv = -1;
		(void) POPs;
	} else {
		rv = POPi;
	}

	FREETMPS;
	LEAVE;

	return rv;
}

int git_filter_apply_cbb(git_filter *filter, void **payload,
	git_buf *to, const git_buf *from, const git_filter_source *src) {
	dSP;

	int rv;
	SV *filter_source = NULL;
	SV *result = newSV(from -> size);

	GIT_NEW_OBJ(
		filter_source, "Git::Raw::Filter::Source", (void *) src
	);

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(filter_source);
	mXPUSHs(newSVpv(from -> ptr, from -> size));
	mXPUSHs(newRV_noinc(result));
	PUTBACK;

	call_sv(((git_raw_filter *) filter) -> callbacks.apply, G_EVAL|G_SCALAR);

	SPAGAIN;

	if (SvTRUE(ERRSV)) {
		rv = -1;
		(void) POPs;
	} else {
		rv = POPi;
	}

	if (rv == GIT_OK) {
		STRLEN len;
		const char *ptr = SvPV(result, len);

		git_buf_set(to, ptr, len);
	}

	FREETMPS;
	LEAVE;

	return rv;
}

void git_filter_cleanup_cbb(git_filter *filter, void *payload) {
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUTBACK;

	call_sv(((git_raw_filter *) filter) -> callbacks.cleanup, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;
}

/* vim: set syntax=xs ts=4 sw=4: */
