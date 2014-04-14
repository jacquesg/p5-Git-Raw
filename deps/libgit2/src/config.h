/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */
#ifndef INCLUDE_config_h__
#define INCLUDE_config_h__

#include "git2.h"
#include "git2/config.h"
#include "vector.h"
#include "repository.h"

#define GIT_CONFIG_FILENAME_SYSTEM "gitconfig"
#define GIT_CONFIG_FILENAME_GLOBAL ".gitconfig"
#define GIT_CONFIG_FILENAME_XDG    "config"

#define GIT_CONFIG_FILENAME_INREPO "config"
#define GIT_CONFIG_FILE_MODE 0666

struct git_config {
	git_refcount rc;
	git_vector files;
};

extern int git_config__global_location(git_buf *buf);

extern int git_config_rename_section(
	git_repository *repo,
	const char *old_section_name,	/* eg "branch.dummy" */
	const char *new_section_name);	/* NULL to drop the old section */

/**
 * Create a configuration file backend for ondisk files
 *
 * These are the normal `.gitconfig` files that Core Git
 * processes. Note that you first have to add this file to a
 * configuration object before you can query it for configuration
 * variables.
 *
 * @param out the new backend
 * @param path where the config file is located
 */
extern int git_config_file__ondisk(git_config_backend **out, const char *path);

extern int git_config__normalize_name(const char *in, char **out);

/* internal only: does not normalize key and sets out to NULL if not found */
extern int git_config__lookup_entry(
	const git_config_entry **out,
	const git_config *cfg,
	const char *key,
	bool no_errors);

/* internal only: update and/or delete entry string with constraints */
extern int git_config__update_entry(
	git_config *cfg,
	const char *key,
	const char *value,
	bool overwrite_existing,
	bool only_if_existing);

/*
 * Lookup functions that cannot fail.  These functions look up a config
 * value and return a fallback value if the value is missing or if any
 * failures occur while trying to access the value.
 */

extern const char *git_config__get_string_force(
	const git_config *cfg, const char *key, const char *fallback_value);

extern int git_config__get_bool_force(
	const git_config *cfg, const char *key, int fallback_value);

extern int git_config__get_int_force(
	const git_config *cfg, const char *key, int fallback_value);

#endif
