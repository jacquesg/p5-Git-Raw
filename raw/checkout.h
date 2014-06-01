#ifndef GIT_RAW_CHECKOUT_H
#define GIT_RAW_CHECKOUT_H

#include "raw.h"

unsigned git_hv_to_checkout_strategy(HV *strategy);
void git_hv_to_checkout_opts(HV *opts, git_checkout_options *checkout_opts);

int git_checkout_notify_cbb(git_checkout_notify_t why, const char *path, const git_diff_file *baseline,
	const git_diff_file *target, const git_diff_file *workdir, void *payload);
void git_checkout_progress_cbb(const char *path, size_t completed_steps,
	size_t total_steps, void *payload);

#endif

/* vim: set syntax=xs ts=4 sw=4: */
