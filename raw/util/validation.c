#include <raw/util/validation.h>

AV *git_ensure_av(SV *sv, const char *identifier) {
	if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV)
		Perl_croak(aTHX_ "Invalid type for '%s', expected a list", identifier);

	return (AV *) SvRV(sv);
}

HV *git_ensure_hv(SV *sv, const char *identifier) {
	if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV)
		Perl_croak(aTHX_ "Invalid type for '%s', expected a hash", identifier);

	return (HV *) SvRV(sv);
}

SV *git_ensure_cv(SV *sv, const char *identifier) {
	if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVCV)
		Perl_croak(aTHX_ "Invalid type for '%s', expected a code reference", identifier);

	return sv;
}

I32 git_ensure_iv(SV *sv, const char *identifier) {
	if (!SvIOK(sv))
		Perl_croak(aTHX_ "Invalid type for '%s', expected an integer", identifier);

	return SvIV(sv);
}

const char *git_ensure_pv_with_len(SV *sv, const char *identifier, STRLEN *len) {
	const char *pv = NULL;
	STRLEN real_len;

	if (SvPOK(sv)) {
		pv = SvPVbyte(sv, real_len);
	} else if (SvTYPE(sv) == SVt_PVLV) {
		pv = SvPVbyte_force(sv, real_len);
	} else
		Perl_croak(aTHX_ "Invalid type for '%s', expected a string", identifier);

	if (len)
		*len = real_len;

	return pv;
}

const char *git_ensure_pv(SV *sv, const char *identifier) {
	return git_ensure_pv_with_len(sv, identifier, NULL);
}

SV *git_hv_sv_entry(HV *hv, const char *name) {
	SV **opt;

	if ((opt = hv_fetch(hv, name, strlen(name), 0)))
		return *opt;

	return NULL;
}

SV *git_hv_int_entry(HV *hv, const char *name) {
	SV **opt;

	if ((opt = hv_fetch(hv, name, strlen(name), 0))) {
		if (!SvIOK(*opt))
			Perl_croak(aTHX_ "Expected an integer for '%s'", name);

		return *opt;
	}

	return NULL;
}

SV *git_hv_string_entry(HV *hv, const char *name) {
	SV **opt;

	if ((opt = hv_fetch(hv, name, strlen(name), 0))) {
		if (!SvPOK(*opt))
			Perl_croak(aTHX_ "Expected a string for '%s'", name);

		return *opt;
	}

	return NULL;
}

SV *git_hv_code_entry(HV *hv, const char *name) {
	SV **opt;

	if ((opt = hv_fetch(hv, name, strlen(name), 0)))
		return git_ensure_cv(*opt, name);

	return NULL;
}

HV *git_hv_hash_entry(HV *hv, const char *name) {
	SV **opt;

	if ((opt = hv_fetch(hv, name, strlen(name), 0)))
		return git_ensure_hv(*opt, name);

	return NULL;
}

AV *git_hv_list_entry(HV *hv, const char *name) {
	SV **opt;

	if ((opt = hv_fetch(hv, name, strlen(name), 0)))
		return git_ensure_av(*opt, name);

	return NULL;
}

/* vim: set syntax=xs ts=4 sw=4: */
