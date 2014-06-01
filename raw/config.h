#ifndef GIT_RAW_CONFIG_H
#define GIT_RAW_CONFIG_H

#include "raw.h"

int git_config_foreach_cbb(const git_config_entry *entry, void *payload);

#endif

/* vim: set syntax=xs ts=4 sw=4: */
