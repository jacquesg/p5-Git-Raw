#ifndef GIT_RAW_TAG_H
#define GIT_RAW_TAG_H

#include "raw.h"

typedef struct {
	SV *repo;
	SV *cb;
	const char *class;
} git_tag_foreach_payload;

int git_tag_foreach_cbb(const char *name, git_oid *oid, void *payload);

#endif

/* vim: set syntax=xs ts=4 sw=4: */
