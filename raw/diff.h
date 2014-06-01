#ifndef GIT_RAW_DIFF_H
#define GIT_RAW_DIFF_H

#include "raw.h"

unsigned git_hv_to_diff_flag(HV *flags);
unsigned git_hv_to_diff_find_flag(HV *flags);

int git_diff_cb(const git_diff_delta *delta, const git_diff_hunk *hunk,
	const git_diff_line *line, void *data);

#endif

/* vim: set syntax=xs ts=4 sw=4: */
