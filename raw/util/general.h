#ifndef GIT_RAW_UTIL_GENERAL_H
#define GIT_RAW_UTIL_GENERAL_H

#include <raw/raw.h>

void dummy_free(void *ptr);

void git_flag_opt(HV *value, const char *name, int mask, unsigned *out);
SV *get_callback_option(HV *callbacks, const char *name);
void git_list_to_paths(AV *list, git_strarray *paths);

#endif

/* vim: set syntax=xs ts=4 sw=4: */
