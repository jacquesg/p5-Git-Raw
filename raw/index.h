#ifndef GIT_RAW_INDEX_H
#define GIT_RAW_INDEX_H

#include "raw.h"

int git_index_matched_path_cbb(const char *path, const char *pathspec, void *payload);

#endif

/* vim: set syntax=xs ts=4 sw=4: */
