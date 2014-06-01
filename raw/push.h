#ifndef GIT_RAW_PUSH_H
#define GIT_RAW_PUSH_H

#include "raw.h"

typedef struct {
	SV *packbuilder_progress;
	SV *transfer_progress;
	SV *status;
} git_raw_push_callbacks;

typedef struct {
	git_push *push;
	git_raw_push_callbacks callbacks;
} git_raw_push;

void git_init_push_callbacks(git_raw_push_callbacks *cbs);
void git_clean_push_callbacks(git_raw_push_callbacks *cbs);

int git_push_transfer_progress_cbb(unsigned int current, unsigned int total, size_t bytes, void *cbs);
int git_packbuilder_progress_cbb(int stage, unsigned int current, unsigned int total, void *cbs);
int git_push_status_cbb(const char *ref, const char *msg, void *cbs);

#endif

/* vim: set syntax=xs ts=4 sw=4: */
