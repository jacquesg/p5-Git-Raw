#include <raw/push.h>

void git_init_push_callbacks(git_raw_push_callbacks *cbs) {
	cbs -> packbuilder_progress = NULL;
	cbs -> transfer_progress = NULL;
	cbs -> status = NULL;
}

void git_clean_push_callbacks(git_raw_push_callbacks *cbs) {
	if (cbs -> packbuilder_progress) {
		SvREFCNT_dec(cbs -> packbuilder_progress);
		cbs -> packbuilder_progress = NULL;
	}

	if (cbs -> transfer_progress) {
		SvREFCNT_dec(cbs -> transfer_progress);
		cbs -> transfer_progress = NULL;
	}

	if (cbs -> status) {
		SvREFCNT_dec(cbs -> status);
		cbs -> status = NULL;
	}
}

int git_push_transfer_progress_cbb(unsigned int current, unsigned int total, size_t bytes, void *cbs) {
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(newSVuv(current));
	mXPUSHs(newSVuv(total));
	mXPUSHs(newSVuv(bytes));
	PUTBACK;

	call_sv(((git_raw_push_callbacks *) cbs) -> transfer_progress, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;

	return 0;
}

int git_packbuilder_progress_cbb(int stage, unsigned int current, unsigned int total, void *cbs) {
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(newSViv(stage));
	mXPUSHs(newSVuv(current));
	mXPUSHs(newSVuv(total));
	PUTBACK;

	call_sv(((git_raw_push_callbacks *) cbs) -> packbuilder_progress, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;

	return 0;
}

int git_push_status_cbb(const char *ref, const char *msg, void *cbs) {
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(newSVpv(ref, 0));
	mXPUSHs(newSVpv(msg, 0));
	PUTBACK;

	call_sv(((git_raw_push_callbacks *) cbs) -> status, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;

	return 0;
}

/* vim: set syntax=xs ts=4 sw=4: */
