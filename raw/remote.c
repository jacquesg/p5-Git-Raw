#include <raw/cred.h>
#include <raw/remote.h>

void git_init_remote_callbacks(git_raw_remote_callbacks *cbs) {
	cbs -> credentials = NULL;
	cbs -> progress = NULL;
	cbs -> transfer_progress = NULL;
	cbs -> update_tips = NULL;
}

void git_clean_remote_callbacks(git_raw_remote_callbacks *cbs) {
	if (cbs -> credentials) {
		SvREFCNT_dec(cbs -> credentials);
		cbs -> credentials = NULL;
	}

	if (cbs -> progress) {
		SvREFCNT_dec(cbs -> progress);
		cbs -> progress = NULL;
	}

	if (cbs -> transfer_progress) {
		SvREFCNT_dec(cbs -> transfer_progress);
		cbs -> transfer_progress = NULL;
	}

	if (cbs -> update_tips) {
		SvREFCNT_dec(cbs -> update_tips);
		cbs -> update_tips = NULL;
	}
}

int git_progress_cbb(const char *str, int len, void *cbs) {
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(newSVpv(str, len));
	PUTBACK;

	call_sv(((git_raw_remote_callbacks *) cbs) -> progress, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;

	return 0;
}

int git_transfer_progress_cbb(const git_transfer_progress *stats, void *cbs) {
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(newSViv(stats -> total_objects));
	mXPUSHs(newSViv(stats -> received_objects));
	mXPUSHs(newSViv(stats -> local_objects));
	mXPUSHs(newSViv(stats -> total_deltas));
	mXPUSHs(newSViv(stats -> indexed_deltas));
	mXPUSHs(newSVuv(stats -> received_bytes));
	PUTBACK;

	call_sv(((git_raw_remote_callbacks *) cbs) -> transfer_progress, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;

	return 0;
}

int git_update_tips_cbb(const char *name, const git_oid *a,
	const git_oid *b, void *cbs) {
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(newSVpv(name, 0));
	XPUSHs(a != NULL ? sv_2mortal(git_oid_to_sv(a)) : &PL_sv_undef);
	XPUSHs(b != NULL ? sv_2mortal(git_oid_to_sv(b)) : &PL_sv_undef);
	PUTBACK;

	call_sv(((git_raw_remote_callbacks *) cbs) -> update_tips, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;

	return 0;
}

int git_credentials_cbb(git_cred **cred, const char *url,
		const char *usr_from_url, unsigned int allow, void *cbs) {
	dSP;
	int rv = 0;
	Cred creds;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(newSVpv(url, 0));
	mXPUSHs(newSVpv(usr_from_url, 0));
	PUTBACK;

	call_sv(((git_raw_remote_callbacks *) cbs) -> credentials, G_EVAL|G_SCALAR);

	SPAGAIN;

	if (SvTRUE(ERRSV)) {
		rv = -1;
		(void) POPs;
	} else {
		creds = GIT_SV_TO_PTR(Cred, POPs);
		*cred = creds -> cred;
	}

	FREETMPS;
	LEAVE;

	return rv;
}

void git_raw_remote_free(git_raw_remote *remote) {
	git_remote_free(remote -> remote);
	git_clean_remote_callbacks(&remote -> callbacks);
	Safefree(remote);
}

/* vim: set syntax=xs ts=4 sw=4: */
