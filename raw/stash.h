#ifndef GIT_RAW_STASH_H
#define GIT_RAW_STASH_H

#include "raw.h"

int git_stash_foreach_cb(size_t i, const char *msg, const git_oid *oid, void *payload);

#endif

/* vim: set syntax=xs ts=4 sw=4: */
