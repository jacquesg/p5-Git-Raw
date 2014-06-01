#ifndef GIT_RAW_FILTER_H
#define GIT_RAW_FILTER_H

#include "raw.h"

typedef struct {
	SV *initialize;
	SV *shutdown;
	SV *check;
	SV *apply;
	SV *cleanup;
} git_filter_callbacks;

typedef struct {
	git_filter filter;
	git_filter_callbacks callbacks;
	char *name;
	char *attributes;
} git_raw_filter;

void git_clean_filter_callbacks(git_filter_callbacks *cbs);

int git_filter_init_cbb(git_filter *filter);
void git_filter_shutdown_cbb(git_filter *filter);
int git_filter_check_cbb(git_filter *filter, void **payload,
	const git_filter_source *src, const char **attr_values);
int git_filter_apply_cbb(git_filter *filter, void **payload,
	git_buf *to, const git_buf *from, const git_filter_source *src);
void git_filter_shutdown_cbb(git_filter *filter);
void git_filter_cleanup_cbb(git_filter *filter, void *payload);

#endif

/* vim: set syntax=xs ts=4 sw=4: */
