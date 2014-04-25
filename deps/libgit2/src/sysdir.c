/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */

#include "common.h"
#include "sysdir.h"
#include "global.h"
#include "buffer.h"
#include "path.h"
#include <ctype.h>
#if GIT_WIN32
#include "win32/findfile.h"
#endif

static int git_sysdir_guess_system_dirs(git_buf *out)
{
#ifdef GIT_WIN32
	return git_win32__find_system_dirs(out, L"etc\\");
#else
	return git_buf_sets(out, "/etc");
#endif
}

static int git_sysdir_guess_global_dirs(git_buf *out)
{
#ifdef GIT_WIN32
	return git_win32__find_global_dirs(out);
#else
	return git_buf_sets(out, getenv("HOME"));
#endif
}

static int git_sysdir_guess_xdg_dirs(git_buf *out)
{
#ifdef GIT_WIN32
	return git_win32__find_xdg_dirs(out);
#else
	const char *env = NULL;

	if ((env = getenv("XDG_CONFIG_HOME")) != NULL)
		return git_buf_joinpath(out, env, "git");
	else if ((env = getenv("HOME")) != NULL)
		return git_buf_joinpath(out, env, ".config/git");

	git_buf_clear(out);
	return 0;
#endif
}

static int git_sysdir_guess_template_dirs(git_buf *out)
{
#ifdef GIT_WIN32
	return git_win32__find_system_dirs(out, L"share\\git-core\\templates");
#else
	return git_buf_sets(out, "/usr/share/git-core/templates");
#endif
}

typedef int (*git_sysdir_guess_cb)(git_buf *out);

static git_buf git_sysdir__dirs[GIT_SYSDIR__MAX] =
	{ GIT_BUF_INIT, GIT_BUF_INIT, GIT_BUF_INIT, GIT_BUF_INIT };

static git_sysdir_guess_cb git_sysdir__dir_guess[GIT_SYSDIR__MAX] = {
	git_sysdir_guess_system_dirs,
	git_sysdir_guess_global_dirs,
	git_sysdir_guess_xdg_dirs,
	git_sysdir_guess_template_dirs,
};

static int git_sysdir__dirs_shutdown_set = 0;

int git_sysdir_global_init(void)
{
	git_sysdir_t i;
	const git_buf *path;
	int error = 0;

	for (i = 0; !error && i < GIT_SYSDIR__MAX; i++)
		error = git_sysdir_get(&path, i);

	return error;
}

void git_sysdir_global_shutdown(void)
{
	int i;
	for (i = 0; i < GIT_SYSDIR__MAX; ++i)
		git_buf_free(&git_sysdir__dirs[i]);
}

static int git_sysdir_check_selector(git_sysdir_t which)
{
	if (which < GIT_SYSDIR__MAX)
		return 0;

	giterr_set(GITERR_INVALID, "config directory selector out of range");
	return -1;
}


int git_sysdir_get(const git_buf **out, git_sysdir_t which)
{
	assert(out);

	*out = NULL;

	GITERR_CHECK_ERROR(git_sysdir_check_selector(which));

	if (!git_buf_len(&git_sysdir__dirs[which])) {
		/* prepare shutdown if we're going to need it */
		if (!git_sysdir__dirs_shutdown_set) {
			git__on_shutdown(git_sysdir_global_shutdown);
			git_sysdir__dirs_shutdown_set = 1;
		}

		GITERR_CHECK_ERROR(
			git_sysdir__dir_guess[which](&git_sysdir__dirs[which]));
	}

	*out = &git_sysdir__dirs[which];
	return 0;
}

int git_sysdir_get_str(
	char *out,
	size_t outlen,
	git_sysdir_t which)
{
	const git_buf *path = NULL;

	GITERR_CHECK_ERROR(git_sysdir_check_selector(which));
	GITERR_CHECK_ERROR(git_sysdir_get(&path, which));

	if (!out || path->size >= outlen) {
		giterr_set(GITERR_NOMEMORY, "Buffer is too short for the path");
		return GIT_EBUFS;
	}

	git_buf_copy_cstr(out, outlen, path);
	return 0;
}

#define PATH_MAGIC "$PATH"

int git_sysdir_set(git_sysdir_t which, const char *search_path)
{
	const char *expand_path = NULL;
	git_buf merge = GIT_BUF_INIT;

	GITERR_CHECK_ERROR(git_sysdir_check_selector(which));

	if (search_path != NULL)
		expand_path = strstr(search_path, PATH_MAGIC);

	/* init with default if not yet done and needed (ignoring error) */
	if ((!search_path || expand_path) &&
		!git_buf_len(&git_sysdir__dirs[which]))
		git_sysdir__dir_guess[which](&git_sysdir__dirs[which]);

	/* if $PATH is not referenced, then just set the path */
	if (!expand_path)
		return git_buf_sets(&git_sysdir__dirs[which], search_path);

	/* otherwise set to join(before $PATH, old value, after $PATH) */
	if (expand_path > search_path)
		git_buf_set(&merge, search_path, expand_path - search_path);

	if (git_buf_len(&git_sysdir__dirs[which]))
		git_buf_join(&merge, GIT_PATH_LIST_SEPARATOR,
			merge.ptr, git_sysdir__dirs[which].ptr);

	expand_path += strlen(PATH_MAGIC);
	if (*expand_path)
		git_buf_join(&merge, GIT_PATH_LIST_SEPARATOR, merge.ptr, expand_path);

	git_buf_swap(&git_sysdir__dirs[which], &merge);
	git_buf_free(&merge);

	return git_buf_oom(&git_sysdir__dirs[which]) ? -1 : 0;
}

static int git_sysdir_find_in_dirlist(
	git_buf *path,
	const char *name,
	git_sysdir_t which,
	const char *label)
{
	size_t len;
	const char *scan, *next = NULL;
	const git_buf *syspath;

	GITERR_CHECK_ERROR(git_sysdir_get(&syspath, which));

	for (scan = git_buf_cstr(syspath); scan; scan = next) {
		for (next = strchr(scan, GIT_PATH_LIST_SEPARATOR);
			 next && next > scan && next[-1] == '\\';
			 next = strchr(next + 1, GIT_PATH_LIST_SEPARATOR))
			/* find unescaped separator or end of string */;

		len = next ? (size_t)(next++ - scan) : strlen(scan);
		if (!len)
			continue;

		GITERR_CHECK_ERROR(git_buf_set(path, scan, len));
		if (name)
			GITERR_CHECK_ERROR(git_buf_joinpath(path, path->ptr, name));

		if (git_path_exists(path->ptr))
			return 0;
	}

	git_buf_free(path);
	giterr_set(GITERR_OS, "The %s file '%s' doesn't exist", label, name);
	return GIT_ENOTFOUND;
}

int git_sysdir_find_system_file(git_buf *path, const char *filename)
{
	return git_sysdir_find_in_dirlist(
		path, filename, GIT_SYSDIR_SYSTEM, "system");
}

int git_sysdir_find_global_file(git_buf *path, const char *filename)
{
	return git_sysdir_find_in_dirlist(
		path, filename, GIT_SYSDIR_GLOBAL, "global");
}

int git_sysdir_find_xdg_file(git_buf *path, const char *filename)
{
	return git_sysdir_find_in_dirlist(
		path, filename, GIT_SYSDIR_XDG, "global/xdg");
}

int git_sysdir_find_template_dir(git_buf *path)
{
	return git_sysdir_find_in_dirlist(
		path, NULL, GIT_SYSDIR_TEMPLATE, "template");
}

