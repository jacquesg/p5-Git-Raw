#ifndef GIT_RAW_UTIL_VALIDATION_H
#define GIT_RAW_UTIL_VALIDATION_H

#include <raw/raw.h>

AV *git_ensure_av(SV *sv, const char *identifier);
HV *git_ensure_hv(SV *sv, const char *identifier);
SV *git_ensure_cv(SV *sv, const char *identifier);
I32 git_ensure_iv(SV *sv, const char *identifier);
const char *git_ensure_pv(SV *sv, const char *identifier);
const char *git_ensure_pv_with_len(SV *sv, const char *identifier, STRLEN *len);

SV *git_hv_sv_entry(HV *hv, const char *name);
SV *git_hv_int_entry(HV *hv, const char *name);
SV *git_hv_string_entry(HV *hv, const char *name);
SV *git_hv_code_entry(HV *hv, const char *name);
HV *git_hv_hash_entry(HV *hv, const char *name);
AV *git_hv_list_entry(HV *hv, const char *name);

#endif

/* vim: set syntax=xs ts=4 sw=4: */
