/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */
#include "common.h"
#include "diff.h"
#include "fileops.h"
#include "config.h"
#include "attr_file.h"
#include "filter.h"
#include "pathspec.h"
#include "index.h"
#include "odb.h"
#include "submodule.h"

#define DIFF_FLAG_IS_SET(DIFF,FLAG) (((DIFF)->opts.flags & (FLAG)) != 0)
#define DIFF_FLAG_ISNT_SET(DIFF,FLAG) (((DIFF)->opts.flags & (FLAG)) == 0)
#define DIFF_FLAG_SET(DIFF,FLAG,VAL) (DIFF)->opts.flags = \
	(VAL) ? ((DIFF)->opts.flags | (FLAG)) : ((DIFF)->opts.flags & ~(VAL))

static git_diff_delta *diff_delta__alloc(
	git_diff *diff,
	git_delta_t status,
	const char *path)
{
	git_diff_delta *delta = git__calloc(1, sizeof(git_diff_delta));
	if (!delta)
		return NULL;

	delta->old_file.path = git_pool_strdup(&diff->pool, path);
	if (delta->old_file.path == NULL) {
		git__free(delta);
		return NULL;
	}

	delta->new_file.path = delta->old_file.path;

	if (DIFF_FLAG_IS_SET(diff, GIT_DIFF_REVERSE)) {
		switch (status) {
		case GIT_DELTA_ADDED:   status = GIT_DELTA_DELETED; break;
		case GIT_DELTA_DELETED: status = GIT_DELTA_ADDED; break;
		default: break; /* leave other status values alone */
		}
	}
	delta->status = status;

	return delta;
}

static int diff_insert_delta(
	git_diff *diff, git_diff_delta *delta, const char *matched_pathspec)
{
	int error = 0;

	if (diff->opts.notify_cb) {
		error = diff->opts.notify_cb(
			diff, delta, matched_pathspec, diff->opts.notify_payload);

		if (error) {
			git__free(delta);

			if (error > 0)	/* positive value means to skip this delta */
				return 0;
			else			/* negative value means to cancel diff */
				return giterr_set_after_callback_function(error, "git_diff");
		}
	}

	if ((error = git_vector_insert(&diff->deltas, delta)) < 0)
		git__free(delta);

	return error;
}

static int diff_delta__from_one(
	git_diff *diff,
	git_delta_t status,
	const git_index_entry *entry)
{
	git_diff_delta *delta;
	const char *matched_pathspec;

	if ((entry->flags & GIT_IDXENTRY_VALID) != 0)
		return 0;

	if (status == GIT_DELTA_IGNORED &&
		DIFF_FLAG_ISNT_SET(diff, GIT_DIFF_INCLUDE_IGNORED))
		return 0;

	if (status == GIT_DELTA_UNTRACKED &&
		DIFF_FLAG_ISNT_SET(diff, GIT_DIFF_INCLUDE_UNTRACKED))
		return 0;

	if (!git_pathspec__match(
			&diff->pathspec, entry->path,
			DIFF_FLAG_IS_SET(diff, GIT_DIFF_DISABLE_PATHSPEC_MATCH),
			DIFF_FLAG_IS_SET(diff, GIT_DIFF_IGNORE_CASE),
			&matched_pathspec, NULL))
		return 0;

	delta = diff_delta__alloc(diff, status, entry->path);
	GITERR_CHECK_ALLOC(delta);

	/* This fn is just for single-sided diffs */
	assert(status != GIT_DELTA_MODIFIED);
	delta->nfiles = 1;

	if (delta->status == GIT_DELTA_DELETED) {
		delta->old_file.mode = entry->mode;
		delta->old_file.size = entry->file_size;
		git_oid_cpy(&delta->old_file.id, &entry->id);
	} else /* ADDED, IGNORED, UNTRACKED */ {
		delta->new_file.mode = entry->mode;
		delta->new_file.size = entry->file_size;
		git_oid_cpy(&delta->new_file.id, &entry->id);
	}

	delta->old_file.flags |= GIT_DIFF_FLAG_VALID_ID;

	if (delta->status == GIT_DELTA_DELETED ||
		!git_oid_iszero(&delta->new_file.id))
		delta->new_file.flags |= GIT_DIFF_FLAG_VALID_ID;

	return diff_insert_delta(diff, delta, matched_pathspec);
}

static int diff_delta__from_two(
	git_diff *diff,
	git_delta_t status,
	const git_index_entry *old_entry,
	uint32_t old_mode,
	const git_index_entry *new_entry,
	uint32_t new_mode,
	git_oid *new_oid,
	const char *matched_pathspec)
{
	git_diff_delta *delta;
	const char *canonical_path = old_entry->path;

	if (status == GIT_DELTA_UNMODIFIED &&
		DIFF_FLAG_ISNT_SET(diff, GIT_DIFF_INCLUDE_UNMODIFIED))
		return 0;

	if (DIFF_FLAG_IS_SET(diff, GIT_DIFF_REVERSE)) {
		uint32_t temp_mode = old_mode;
		const git_index_entry *temp_entry = old_entry;
		old_entry = new_entry;
		new_entry = temp_entry;
		old_mode = new_mode;
		new_mode = temp_mode;
	}

	delta = diff_delta__alloc(diff, status, canonical_path);
	GITERR_CHECK_ALLOC(delta);
	delta->nfiles = 2;

	git_oid_cpy(&delta->old_file.id, &old_entry->id);
	delta->old_file.size = old_entry->file_size;
	delta->old_file.mode = old_mode;
	delta->old_file.flags |= GIT_DIFF_FLAG_VALID_ID;

	git_oid_cpy(&delta->new_file.id, &new_entry->id);
	delta->new_file.size = new_entry->file_size;
	delta->new_file.mode = new_mode;

	if (new_oid) {
		if (DIFF_FLAG_IS_SET(diff, GIT_DIFF_REVERSE))
			git_oid_cpy(&delta->old_file.id, new_oid);
		else
			git_oid_cpy(&delta->new_file.id, new_oid);
	}

	if (new_oid || !git_oid_iszero(&new_entry->id))
		delta->new_file.flags |= GIT_DIFF_FLAG_VALID_ID;

	return diff_insert_delta(diff, delta, matched_pathspec);
}

static git_diff_delta *diff_delta__last_for_item(
	git_diff *diff,
	const git_index_entry *item)
{
	git_diff_delta *delta = git_vector_last(&diff->deltas);
	if (!delta)
		return NULL;

	switch (delta->status) {
	case GIT_DELTA_UNMODIFIED:
	case GIT_DELTA_DELETED:
		if (git_oid__cmp(&delta->old_file.id, &item->id) == 0)
			return delta;
		break;
	case GIT_DELTA_ADDED:
		if (git_oid__cmp(&delta->new_file.id, &item->id) == 0)
			return delta;
		break;
	case GIT_DELTA_UNTRACKED:
		if (diff->strcomp(delta->new_file.path, item->path) == 0 &&
			git_oid__cmp(&delta->new_file.id, &item->id) == 0)
			return delta;
		break;
	case GIT_DELTA_MODIFIED:
		if (git_oid__cmp(&delta->old_file.id, &item->id) == 0 ||
			git_oid__cmp(&delta->new_file.id, &item->id) == 0)
			return delta;
		break;
	default:
		break;
	}

	return NULL;
}

static char *diff_strdup_prefix(git_pool *pool, const char *prefix)
{
	size_t len = strlen(prefix);

	/* append '/' at end if needed */
	if (len > 0 && prefix[len - 1] != '/')
		return git_pool_strcat(pool, prefix, "/");
	else
		return git_pool_strndup(pool, prefix, len + 1);
}

GIT_INLINE(const char *) diff_delta__path(const git_diff_delta *delta)
{
	const char *str = delta->old_file.path;

	if (!str ||
		delta->status == GIT_DELTA_ADDED ||
		delta->status == GIT_DELTA_RENAMED ||
		delta->status == GIT_DELTA_COPIED)
		str = delta->new_file.path;

	return str;
}

const char *git_diff_delta__path(const git_diff_delta *delta)
{
	return diff_delta__path(delta);
}

int git_diff_delta__cmp(const void *a, const void *b)
{
	const git_diff_delta *da = a, *db = b;
	int val = strcmp(diff_delta__path(da), diff_delta__path(db));
	return val ? val : ((int)da->status - (int)db->status);
}

int git_diff_delta__casecmp(const void *a, const void *b)
{
	const git_diff_delta *da = a, *db = b;
	int val = strcasecmp(diff_delta__path(da), diff_delta__path(db));
	return val ? val : ((int)da->status - (int)db->status);
}

GIT_INLINE(const char *) diff_delta__i2w_path(const git_diff_delta *delta)
{
	return delta->old_file.path ?
		delta->old_file.path : delta->new_file.path;
}

int git_diff_delta__i2w_cmp(const void *a, const void *b)
{
	const git_diff_delta *da = a, *db = b;
	int val = strcmp(diff_delta__i2w_path(da), diff_delta__i2w_path(db));
	return val ? val : ((int)da->status - (int)db->status);
}

int git_diff_delta__i2w_casecmp(const void *a, const void *b)
{
	const git_diff_delta *da = a, *db = b;
	int val = strcasecmp(diff_delta__i2w_path(da), diff_delta__i2w_path(db));
	return val ? val : ((int)da->status - (int)db->status);
}

bool git_diff_delta__should_skip(
	const git_diff_options *opts, const git_diff_delta *delta)
{
	uint32_t flags = opts ? opts->flags : 0;

	if (delta->status == GIT_DELTA_UNMODIFIED &&
		(flags & GIT_DIFF_INCLUDE_UNMODIFIED) == 0)
		return true;

	if (delta->status == GIT_DELTA_IGNORED &&
		(flags & GIT_DIFF_INCLUDE_IGNORED) == 0)
		return true;

	if (delta->status == GIT_DELTA_UNTRACKED &&
		(flags & GIT_DIFF_INCLUDE_UNTRACKED) == 0)
		return true;

	return false;
}


static const char *diff_mnemonic_prefix(
	git_iterator_type_t type, bool left_side)
{
	const char *pfx = "";

	switch (type) {
	case GIT_ITERATOR_TYPE_EMPTY:   pfx = "c"; break;
	case GIT_ITERATOR_TYPE_TREE:    pfx = "c"; break;
	case GIT_ITERATOR_TYPE_INDEX:   pfx = "i"; break;
	case GIT_ITERATOR_TYPE_WORKDIR: pfx = "w"; break;
	case GIT_ITERATOR_TYPE_FS:      pfx = left_side ? "1" : "2"; break;
	default: break;
	}

	/* note: without a deeper look at pathspecs, there is no easy way
	 * to get the (o)bject / (w)ork tree mnemonics working...
	 */

	return pfx;
}

static git_diff *diff_list_alloc(
	git_repository *repo,
	git_iterator *old_iter,
	git_iterator *new_iter)
{
	git_diff_options dflt = GIT_DIFF_OPTIONS_INIT;
	git_diff *diff = git__calloc(1, sizeof(git_diff));
	if (!diff)
		return NULL;

	assert(repo && old_iter && new_iter);

	GIT_REFCOUNT_INC(diff);
	diff->repo = repo;
	diff->old_src = old_iter->type;
	diff->new_src = new_iter->type;
	memcpy(&diff->opts, &dflt, sizeof(diff->opts));

	if (git_vector_init(&diff->deltas, 0, git_diff_delta__cmp) < 0 ||
		git_pool_init(&diff->pool, 1, 0) < 0) {
		git_diff_free(diff);
		return NULL;
	}

	/* Use case-insensitive compare if either iterator has
	 * the ignore_case bit set */
	if (!git_iterator_ignore_case(old_iter) &&
		!git_iterator_ignore_case(new_iter)) {
		diff->opts.flags &= ~GIT_DIFF_IGNORE_CASE;

		diff->strcomp    = git__strcmp;
		diff->strncomp   = git__strncmp;
		diff->pfxcomp    = git__prefixcmp;
		diff->entrycomp  = git_index_entry__cmp;
	} else {
		diff->opts.flags |= GIT_DIFF_IGNORE_CASE;

		diff->strcomp    = git__strcasecmp;
		diff->strncomp   = git__strncasecmp;
		diff->pfxcomp    = git__prefixcmp_icase;
		diff->entrycomp  = git_index_entry__cmp_icase;

		git_vector_set_cmp(&diff->deltas, git_diff_delta__casecmp);
	}

	return diff;
}

static int diff_list_apply_options(
	git_diff *diff,
	const git_diff_options *opts)
{
	git_config *cfg;
	git_repository *repo = diff->repo;
	git_pool *pool = &diff->pool;
	int val;

	if (opts) {
		/* copy user options (except case sensitivity info from iterators) */
		bool icase = DIFF_FLAG_IS_SET(diff, GIT_DIFF_IGNORE_CASE);
		memcpy(&diff->opts, opts, sizeof(diff->opts));
		DIFF_FLAG_SET(diff, GIT_DIFF_IGNORE_CASE, icase);

		/* initialize pathspec from options */
		if (git_pathspec__vinit(&diff->pathspec, &opts->pathspec, pool) < 0)
			return -1;
	}

	/* flag INCLUDE_TYPECHANGE_TREES implies INCLUDE_TYPECHANGE */
	if (DIFF_FLAG_IS_SET(diff, GIT_DIFF_INCLUDE_TYPECHANGE_TREES))
		diff->opts.flags |= GIT_DIFF_INCLUDE_TYPECHANGE;

	/* flag INCLUDE_UNTRACKED_CONTENT implies INCLUDE_UNTRACKED */
	if (DIFF_FLAG_IS_SET(diff, GIT_DIFF_SHOW_UNTRACKED_CONTENT))
		diff->opts.flags |= GIT_DIFF_INCLUDE_UNTRACKED;

	/* load config values that affect diff behavior */
	if ((val = git_repository_config__weakptr(&cfg, repo)) < 0)
		return val;

	if (!git_repository__cvar(&val, repo, GIT_CVAR_SYMLINKS) && val)
		diff->diffcaps = diff->diffcaps | GIT_DIFFCAPS_HAS_SYMLINKS;

	if (!git_repository__cvar(&val, repo, GIT_CVAR_IGNORESTAT) && val)
		diff->diffcaps = diff->diffcaps | GIT_DIFFCAPS_IGNORE_STAT;

	if ((diff->opts.flags & GIT_DIFF_IGNORE_FILEMODE) == 0 &&
		!git_repository__cvar(&val, repo, GIT_CVAR_FILEMODE) && val)
		diff->diffcaps = diff->diffcaps | GIT_DIFFCAPS_TRUST_MODE_BITS;

	if (!git_repository__cvar(&val, repo, GIT_CVAR_TRUSTCTIME) && val)
		diff->diffcaps = diff->diffcaps | GIT_DIFFCAPS_TRUST_CTIME;

	/* Don't set GIT_DIFFCAPS_USE_DEV - compile time option in core git */

	/* Set GIT_DIFFCAPS_TRUST_NANOSECS on a platform basis */
	diff->diffcaps = diff->diffcaps | GIT_DIFFCAPS_TRUST_NANOSECS;

	/* If not given explicit `opts`, check `diff.xyz` configs */
	if (!opts) {
		int context = git_config__get_int_force(cfg, "diff.context", 3);
		diff->opts.context_lines = context >= 0 ? (uint16_t)context : 3;

		/* add other defaults here */
	}

	/* Reverse src info if diff is reversed */
	if (DIFF_FLAG_IS_SET(diff, GIT_DIFF_REVERSE)) {
		git_iterator_type_t tmp_src = diff->old_src;
		diff->old_src = diff->new_src;
		diff->new_src = tmp_src;
	}

	/* if ignore_submodules not explicitly set, check diff config */
	if (diff->opts.ignore_submodules <= 0) {
		const git_config_entry *entry;
		git_config__lookup_entry(&entry, cfg, "diff.ignoresubmodules", true);

		if (entry && git_submodule_parse_ignore(
				&diff->opts.ignore_submodules, entry->value) < 0)
			giterr_clear();
	}

	/* if either prefix is not set, figure out appropriate value */
	if (!diff->opts.old_prefix || !diff->opts.new_prefix) {
		const char *use_old = DIFF_OLD_PREFIX_DEFAULT;
		const char *use_new = DIFF_NEW_PREFIX_DEFAULT;

		if (git_config__get_bool_force(cfg, "diff.noprefix", 0))
			use_old = use_new = "";
		else if (git_config__get_bool_force(cfg, "diff.mnemonicprefix", 0)) {
			use_old = diff_mnemonic_prefix(diff->old_src, true);
			use_new = diff_mnemonic_prefix(diff->new_src, false);
		}

		if (!diff->opts.old_prefix)
			diff->opts.old_prefix = use_old;
		if (!diff->opts.new_prefix)
			diff->opts.new_prefix = use_new;
	}

	/* strdup prefix from pool so we're not dependent on external data */
	diff->opts.old_prefix = diff_strdup_prefix(pool, diff->opts.old_prefix);
	diff->opts.new_prefix = diff_strdup_prefix(pool, diff->opts.new_prefix);
	if (!diff->opts.old_prefix || !diff->opts.new_prefix)
		return -1;

	if (DIFF_FLAG_IS_SET(diff, GIT_DIFF_REVERSE)) {
		const char *tmp_prefix = diff->opts.old_prefix;
		diff->opts.old_prefix  = diff->opts.new_prefix;
		diff->opts.new_prefix  = tmp_prefix;
	}

	return 0;
}

static void diff_list_free(git_diff *diff)
{
	git_vector_free_deep(&diff->deltas);

	git_pathspec__vfree(&diff->pathspec);
	git_pool_clear(&diff->pool);

	git__memzero(diff, sizeof(*diff));
	git__free(diff);
}

void git_diff_free(git_diff *diff)
{
	if (!diff)
		return;

	GIT_REFCOUNT_DEC(diff, diff_list_free);
}

void git_diff_addref(git_diff *diff)
{
	GIT_REFCOUNT_INC(diff);
}

int git_diff__oid_for_file(
	git_repository *repo,
	const char *path,
	uint16_t  mode,
	git_off_t size,
	git_oid *oid)
{
	int result = 0;
	git_buf full_path = GIT_BUF_INIT;

	if (git_buf_joinpath(
		&full_path, git_repository_workdir(repo), path) < 0)
		return -1;

	if (!mode) {
		struct stat st;

		if (p_stat(path, &st) < 0) {
			giterr_set(GITERR_OS, "Could not stat '%s'", path);
			result = -1;
			goto cleanup;
		}

		mode = st.st_mode;
		size = st.st_size;
	}

	/* calculate OID for file if possible */
	if (S_ISGITLINK(mode)) {
		git_submodule *sm;

		memset(oid, 0, sizeof(*oid));

		if (!git_submodule_lookup(&sm, repo, path)) {
			const git_oid *sm_oid = git_submodule_wd_id(sm);
			if (sm_oid)
				git_oid_cpy(oid, sm_oid);
			git_submodule_free(sm);
		} else {
			/* if submodule lookup failed probably just in an intermediate
			 * state where some init hasn't happened, so ignore the error
			 */
			giterr_clear();
			memset(oid, 0, sizeof(*oid));
		}
	} else if (S_ISLNK(mode)) {
		result = git_odb__hashlink(oid, full_path.ptr);
	} else if (!git__is_sizet(size)) {
		giterr_set(GITERR_OS, "File size overflow (for 32-bits) on '%s'", path);
		result = -1;
	} else {
		git_filter_list *fl = NULL;

		result = git_filter_list_load(&fl, repo, NULL, path, GIT_FILTER_TO_ODB);
		if (!result) {
			int fd = git_futils_open_ro(full_path.ptr);
			if (fd < 0)
				result = fd;
			else {
				result = git_odb__hashfd_filtered(
					oid, fd, (size_t)size, GIT_OBJ_BLOB, fl);
				p_close(fd);
			}

			git_filter_list_free(fl);
		}
	}

cleanup:
	git_buf_free(&full_path);
	return result;
}

static bool diff_time_eq(
	const git_index_time *a, const git_index_time *b, bool use_nanos)
{
	return a->seconds == b->seconds &&
		(!use_nanos || a->nanoseconds == b->nanoseconds);
}

typedef struct {
	git_repository *repo;
	git_iterator *old_iter;
	git_iterator *new_iter;
	const git_index_entry *oitem;
	const git_index_entry *nitem;
	git_buf ignore_prefix;
} diff_in_progress;

#define MODE_BITS_MASK 0000777

static int maybe_modified_submodule(
	git_delta_t *status,
	git_oid *found_oid,
	git_diff *diff,
	diff_in_progress *info)
{
	int error = 0;
	git_submodule *sub;
	unsigned int sm_status = 0;
	git_submodule_ignore_t ign = diff->opts.ignore_submodules;

	*status = GIT_DELTA_UNMODIFIED;

	if (DIFF_FLAG_IS_SET(diff, GIT_DIFF_IGNORE_SUBMODULES) ||
		ign == GIT_SUBMODULE_IGNORE_ALL)
		return 0;

	if ((error = git_submodule_lookup(
			&sub, diff->repo, info->nitem->path)) < 0) {

		/* GIT_EEXISTS means dir with .git in it was found - ignore it */
		if (error == GIT_EEXISTS) {
			giterr_clear();
			error = 0;
		}
		return error;
	}

	if (ign <= 0 && git_submodule_ignore(sub) == GIT_SUBMODULE_IGNORE_ALL)
		/* ignore it */;
	else if ((error = git_submodule__status(
			&sm_status, NULL, NULL, found_oid, sub, ign)) < 0)
		/* return error below */;

	/* check IS_WD_UNMODIFIED because this case is only used
	 * when the new side of the diff is the working directory
	 */
	else if (!GIT_SUBMODULE_STATUS_IS_WD_UNMODIFIED(sm_status))
		*status = GIT_DELTA_MODIFIED;

	/* now that we have a HEAD OID, check if HEAD moved */
	else if ((sm_status & GIT_SUBMODULE_STATUS_IN_WD) != 0 &&
		!git_oid_equal(&info->oitem->id, found_oid))
		*status = GIT_DELTA_MODIFIED;

	git_submodule_free(sub);
	return error;
}

static int maybe_modified(
	git_diff *diff,
	diff_in_progress *info)
{
	git_oid noid;
	git_delta_t status = GIT_DELTA_MODIFIED;
	const git_index_entry *oitem = info->oitem;
	const git_index_entry *nitem = info->nitem;
	unsigned int omode = oitem->mode;
	unsigned int nmode = nitem->mode;
	bool new_is_workdir = (info->new_iter->type == GIT_ITERATOR_TYPE_WORKDIR);
	const char *matched_pathspec;
	int error = 0;

	if (!git_pathspec__match(
			&diff->pathspec, oitem->path,
			DIFF_FLAG_IS_SET(diff, GIT_DIFF_DISABLE_PATHSPEC_MATCH),
			DIFF_FLAG_IS_SET(diff, GIT_DIFF_IGNORE_CASE),
			&matched_pathspec, NULL))
		return 0;

	memset(&noid, 0, sizeof(noid));

	/* on platforms with no symlinks, preserve mode of existing symlinks */
	if (S_ISLNK(omode) && S_ISREG(nmode) && new_is_workdir &&
		!(diff->diffcaps & GIT_DIFFCAPS_HAS_SYMLINKS))
		nmode = omode;

	/* on platforms with no execmode, just preserve old mode */
	if (!(diff->diffcaps & GIT_DIFFCAPS_TRUST_MODE_BITS) &&
		(nmode & MODE_BITS_MASK) != (omode & MODE_BITS_MASK) &&
		new_is_workdir)
		nmode = (nmode & ~MODE_BITS_MASK) | (omode & MODE_BITS_MASK);

	/* support "assume unchanged" (poorly, b/c we still stat everything) */
	if ((oitem->flags & GIT_IDXENTRY_VALID) != 0)
		status = GIT_DELTA_UNMODIFIED;

	/* support "skip worktree" index bit */
	else if ((oitem->flags_extended & GIT_IDXENTRY_SKIP_WORKTREE) != 0)
		status = GIT_DELTA_UNMODIFIED;

	/* if basic type of file changed, then split into delete and add */
	else if (GIT_MODE_TYPE(omode) != GIT_MODE_TYPE(nmode)) {
		if (DIFF_FLAG_IS_SET(diff, GIT_DIFF_INCLUDE_TYPECHANGE))
			status = GIT_DELTA_TYPECHANGE;
		else {
			if (!(error = diff_delta__from_one(diff, GIT_DELTA_DELETED, oitem)))
				error = diff_delta__from_one(diff, GIT_DELTA_ADDED, nitem);
			return error;
		}
	}

	/* if oids and modes match (and are valid), then file is unmodified */
	else if (git_oid_equal(&oitem->id, &nitem->id) &&
			 omode == nmode &&
			 !git_oid_iszero(&oitem->id))
		status = GIT_DELTA_UNMODIFIED;

	/* if we have an unknown OID and a workdir iterator, then check some
	 * circumstances that can accelerate things or need special handling
	 */
	else if (git_oid_iszero(&nitem->id) && new_is_workdir) {
		bool use_ctime = ((diff->diffcaps & GIT_DIFFCAPS_TRUST_CTIME) != 0);
		bool use_nanos = ((diff->diffcaps & GIT_DIFFCAPS_TRUST_NANOSECS) != 0);

		status = GIT_DELTA_UNMODIFIED;

		/* TODO: add check against index file st_mtime to avoid racy-git */

		if (S_ISGITLINK(nmode)) {
			if ((error = maybe_modified_submodule(&status, &noid, diff, info)) < 0)
				return error;
		}

		/* if the stat data looks different, then mark modified - this just
		 * means that the OID will be recalculated below to confirm change
		 */
		else if (omode != nmode ||
			oitem->file_size != nitem->file_size ||
			!diff_time_eq(&oitem->mtime, &nitem->mtime, use_nanos) ||
			(use_ctime &&
			 !diff_time_eq(&oitem->ctime, &nitem->ctime, use_nanos)) ||
			oitem->ino != nitem->ino ||
			oitem->uid != nitem->uid ||
			oitem->gid != nitem->gid)
			status = GIT_DELTA_MODIFIED;
	}

	/* if mode is GITLINK and submodules are ignored, then skip */
	else if (S_ISGITLINK(nmode) &&
			 DIFF_FLAG_IS_SET(diff, GIT_DIFF_IGNORE_SUBMODULES))
		status = GIT_DELTA_UNMODIFIED;

	/* if we got here and decided that the files are modified, but we
	 * haven't calculated the OID of the new item, then calculate it now
	 */
	if (status == GIT_DELTA_MODIFIED && git_oid_iszero(&nitem->id)) {
		if (git_oid_iszero(&noid)) {
			if ((error = git_diff__oid_for_file(diff->repo,
					nitem->path, nitem->mode, nitem->file_size, &noid)) < 0)
				return error;
		}

		/* if oid matches, then mark unmodified (except submodules, where
		 * the filesystem content may be modified even if the oid still
		 * matches between the index and the workdir HEAD)
		 */
		if (omode == nmode && !S_ISGITLINK(omode) &&
			git_oid_equal(&oitem->id, &noid))
			status = GIT_DELTA_UNMODIFIED;
	}

	return diff_delta__from_two(
		diff, status, oitem, omode, nitem, nmode,
		git_oid_iszero(&noid) ? NULL : &noid, matched_pathspec);
}

static bool entry_is_prefixed(
	git_diff *diff,
	const git_index_entry *item,
	const git_index_entry *prefix_item)
{
	size_t pathlen;

	if (!item || diff->pfxcomp(item->path, prefix_item->path) != 0)
		return false;

	pathlen = strlen(prefix_item->path);

	return (prefix_item->path[pathlen - 1] == '/' ||
			item->path[pathlen] == '\0' ||
			item->path[pathlen] == '/');
}

static int diff_scan_inside_untracked_dir(
	git_diff *diff, diff_in_progress *info, git_delta_t *delta_type)
{
	int error = 0;
	git_buf base = GIT_BUF_INIT;
	bool is_ignored;

	*delta_type = GIT_DELTA_IGNORED;
	git_buf_sets(&base, info->nitem->path);

	/* advance into untracked directory */
	if ((error = git_iterator_advance_into(&info->nitem, info->new_iter)) < 0) {

		/* skip ahead if empty */
		if (error == GIT_ENOTFOUND) {
			giterr_clear();
			error = git_iterator_advance(&info->nitem, info->new_iter);
		}

		goto done;
	}

	/* look for actual untracked file */
	while (info->nitem != NULL &&
		   !diff->pfxcomp(info->nitem->path, git_buf_cstr(&base))) {
		is_ignored = git_iterator_current_is_ignored(info->new_iter);

		/* need to recurse into non-ignored directories */
		if (!is_ignored && S_ISDIR(info->nitem->mode)) {
			error = git_iterator_advance_into(&info->nitem, info->new_iter);

			if (!error)
				continue;
			else if (error == GIT_ENOTFOUND) {
				error = 0;
				is_ignored = true; /* treat empty as ignored */
			} else
				break; /* real error, must stop */
		}

		/* found a non-ignored item - treat parent dir as untracked */
		if (!is_ignored) {
			*delta_type = GIT_DELTA_UNTRACKED;
			break;
		}

		if ((error = git_iterator_advance(&info->nitem, info->new_iter)) < 0)
			break;
	}

	/* finish off scan */
	while (info->nitem != NULL &&
		   !diff->pfxcomp(info->nitem->path, git_buf_cstr(&base))) {
		if ((error = git_iterator_advance(&info->nitem, info->new_iter)) < 0)
			break;
	}

done:
	git_buf_free(&base);

	if (error == GIT_ITEROVER)
		error = 0;

	return error;
}

static int handle_unmatched_new_item(
	git_diff *diff, diff_in_progress *info)
{
	int error = 0;
	const git_index_entry *nitem = info->nitem;
	git_delta_t delta_type = GIT_DELTA_UNTRACKED;
	bool contains_oitem;

	/* check if this is a prefix of the other side */
	contains_oitem = entry_is_prefixed(diff, info->oitem, nitem);

	/* check if this is contained in an ignored parent directory */
	if (git_buf_len(&info->ignore_prefix)) {
		if (diff->pfxcomp(nitem->path, git_buf_cstr(&info->ignore_prefix)) == 0)
			delta_type = GIT_DELTA_IGNORED;
		else
			git_buf_clear(&info->ignore_prefix);
	}

	if (nitem->mode == GIT_FILEMODE_TREE) {
		bool recurse_into_dir = contains_oitem;

		/* if not already inside an ignored dir, check if this is ignored */
		if (delta_type != GIT_DELTA_IGNORED &&
			git_iterator_current_is_ignored(info->new_iter)) {
			delta_type = GIT_DELTA_IGNORED;
			git_buf_sets(&info->ignore_prefix, nitem->path);
		}

		/* check if user requests recursion into this type of dir */
		recurse_into_dir = contains_oitem ||
			(delta_type == GIT_DELTA_UNTRACKED &&
			 DIFF_FLAG_IS_SET(diff, GIT_DIFF_RECURSE_UNTRACKED_DIRS)) ||
			(delta_type == GIT_DELTA_IGNORED &&
			 DIFF_FLAG_IS_SET(diff, GIT_DIFF_RECURSE_IGNORED_DIRS));

		/* do not advance into directories that contain a .git file */
		if (recurse_into_dir && !contains_oitem) {
			git_buf *full = NULL;
			if (git_iterator_current_workdir_path(&full, info->new_iter) < 0)
				return -1;
			if (full && git_path_contains(full, DOT_GIT)) {
				/* TODO: warning if not a valid git repository */
				recurse_into_dir = false;
			}
		}

		/* still have to look into untracked directories to match core git -
		 * with no untracked files, directory is treated as ignored
		 */
		if (!recurse_into_dir &&
			delta_type == GIT_DELTA_UNTRACKED &&
			DIFF_FLAG_ISNT_SET(diff, GIT_DIFF_ENABLE_FAST_UNTRACKED_DIRS))
		{
			git_diff_delta *last;

			/* attempt to insert record for this directory */
			if ((error = diff_delta__from_one(diff, delta_type, nitem)) != 0)
				return error;

			/* if delta wasn't created (because of rules), just skip ahead */
			last = diff_delta__last_for_item(diff, nitem);
			if (!last)
				return git_iterator_advance(&info->nitem, info->new_iter);

			/* iterate into dir looking for an actual untracked file */
			if (diff_scan_inside_untracked_dir(diff, info, &delta_type) < 0)
				return -1;

			/* it iteration changed delta type, the update the record */
			if (delta_type == GIT_DELTA_IGNORED) {
				last->status = GIT_DELTA_IGNORED;

				/* remove the record if we don't want ignored records */
				if (DIFF_FLAG_ISNT_SET(diff, GIT_DIFF_INCLUDE_IGNORED)) {
					git_vector_pop(&diff->deltas);
					git__free(last);
				}
			}

			return 0;
		}

		/* try to advance into directory if necessary */
		if (recurse_into_dir) {
			error = git_iterator_advance_into(&info->nitem, info->new_iter);

			/* if real error or no error, proceed with iteration */
			if (error != GIT_ENOTFOUND)
				return error;
			giterr_clear();

			/* if directory is empty, can't advance into it, so either skip
			 * it or ignore it
			 */
			if (contains_oitem)
				return git_iterator_advance(&info->nitem, info->new_iter);
			delta_type = GIT_DELTA_IGNORED;
		}
	}

	/* In core git, the next two checks are effectively reversed --
	 * i.e. when an file contained in an ignored directory is explicitly
	 * ignored, it shows up as an ignored file in the diff list, even though
	 * other untracked files in the same directory are skipped completely.
	 *
	 * To me, this seems odd.  If the directory is ignored and the file is
	 * untracked, we should skip it consistently, regardless of whether it
	 * happens to match a pattern in the ignore file.
	 *
	 * To match the core git behavior, reverse the following two if checks
	 * so that individual file ignores are checked before container
	 * directory exclusions are used to skip the file.
	 */
	else if (delta_type == GIT_DELTA_IGNORED &&
		DIFF_FLAG_ISNT_SET(diff, GIT_DIFF_RECURSE_IGNORED_DIRS))
		/* item contained in ignored directory, so skip over it */
		return git_iterator_advance(&info->nitem, info->new_iter);

	else if (git_iterator_current_is_ignored(info->new_iter))
		delta_type = GIT_DELTA_IGNORED;

	else if (info->new_iter->type != GIT_ITERATOR_TYPE_WORKDIR)
		delta_type = GIT_DELTA_ADDED;

	else if (nitem->mode == GIT_FILEMODE_COMMIT) {
		/* ignore things that are not actual submodules */
		if (git_submodule_lookup(NULL, info->repo, nitem->path) != 0) {
			giterr_clear();
			delta_type = GIT_DELTA_IGNORED;

			/* if this contains a tracked item, treat as normal TREE */
			if (contains_oitem) {
				error = git_iterator_advance_into(&info->nitem, info->new_iter);
				if (error != GIT_ENOTFOUND)
					return error;

				giterr_clear();
				return git_iterator_advance(&info->nitem, info->new_iter);
			}
		}
	}

	/* Actually create the record for this item if necessary */
	if ((error = diff_delta__from_one(diff, delta_type, nitem)) != 0)
		return error;

	/* If user requested TYPECHANGE records, then check for that instead of
	 * just generating an ADDED/UNTRACKED record
	 */
	if (delta_type != GIT_DELTA_IGNORED &&
		DIFF_FLAG_IS_SET(diff, GIT_DIFF_INCLUDE_TYPECHANGE_TREES) &&
		contains_oitem)
	{
		/* this entry was prefixed with a tree - make TYPECHANGE */
		git_diff_delta *last = diff_delta__last_for_item(diff, nitem);
		if (last) {
			last->status = GIT_DELTA_TYPECHANGE;
			last->old_file.mode = GIT_FILEMODE_TREE;
		}
	}

	return git_iterator_advance(&info->nitem, info->new_iter);
}

static int handle_unmatched_old_item(
	git_diff *diff, diff_in_progress *info)
{
	int error = diff_delta__from_one(diff, GIT_DELTA_DELETED, info->oitem);
	if (error != 0)
		return error;

	/* if we are generating TYPECHANGE records then check for that
	 * instead of just generating a DELETE record
	 */
	if (DIFF_FLAG_IS_SET(diff, GIT_DIFF_INCLUDE_TYPECHANGE_TREES) &&
		entry_is_prefixed(diff, info->nitem, info->oitem))
	{
		/* this entry has become a tree! convert to TYPECHANGE */
		git_diff_delta *last = diff_delta__last_for_item(diff, info->oitem);
		if (last) {
			last->status = GIT_DELTA_TYPECHANGE;
			last->new_file.mode = GIT_FILEMODE_TREE;
		}

		/* If new_iter is a workdir iterator, then this situation
		 * will certainly be followed by a series of untracked items.
		 * Unless RECURSE_UNTRACKED_DIRS is set, skip over them...
		 */
		if (S_ISDIR(info->nitem->mode) &&
			DIFF_FLAG_ISNT_SET(diff, GIT_DIFF_RECURSE_UNTRACKED_DIRS))
			return git_iterator_advance(&info->nitem, info->new_iter);
	}

	return git_iterator_advance(&info->oitem, info->old_iter);
}

static int handle_matched_item(
	git_diff *diff, diff_in_progress *info)
{
	int error = 0;

	if ((error = maybe_modified(diff, info)) < 0)
		return error;

	if (!(error = git_iterator_advance(&info->oitem, info->old_iter)) ||
		error == GIT_ITEROVER)
		error = git_iterator_advance(&info->nitem, info->new_iter);

	return error;
}

int git_diff__from_iterators(
	git_diff **diff_ptr,
	git_repository *repo,
	git_iterator *old_iter,
	git_iterator *new_iter,
	const git_diff_options *opts)
{
	int error = 0;
	diff_in_progress info;
	git_diff *diff;

	*diff_ptr = NULL;

	diff = diff_list_alloc(repo, old_iter, new_iter);
	GITERR_CHECK_ALLOC(diff);

	info.repo = repo;
	info.old_iter = old_iter;
	info.new_iter = new_iter;
	git_buf_init(&info.ignore_prefix, 0);

	/* make iterators have matching icase behavior */
	if (DIFF_FLAG_IS_SET(diff, GIT_DIFF_IGNORE_CASE)) {
		if ((error = git_iterator_set_ignore_case(old_iter, true)) < 0 ||
			(error = git_iterator_set_ignore_case(new_iter, true)) < 0)
			goto cleanup;
	}

	/* finish initialization */
	if ((error = diff_list_apply_options(diff, opts)) < 0)
		goto cleanup;

	if ((error = git_iterator_current(&info.oitem, old_iter)) < 0 &&
		error != GIT_ITEROVER)
		goto cleanup;
	if ((error = git_iterator_current(&info.nitem, new_iter)) < 0 &&
		error != GIT_ITEROVER)
		goto cleanup;
	error = 0;

	/* run iterators building diffs */
	while (!error && (info.oitem || info.nitem)) {
		int cmp = info.oitem ?
			(info.nitem ? diff->entrycomp(info.oitem, info.nitem) : -1) : 1;

		/* create DELETED records for old items not matched in new */
		if (cmp < 0)
			error = handle_unmatched_old_item(diff, &info);

		/* create ADDED, TRACKED, or IGNORED records for new items not
		 * matched in old (and/or descend into directories as needed)
		 */
		else if (cmp > 0)
			error = handle_unmatched_new_item(diff, &info);

		/* otherwise item paths match, so create MODIFIED record
		 * (or ADDED and DELETED pair if type changed)
		 */
		else
			error = handle_matched_item(diff, &info);

		/* because we are iterating over two lists, ignore ITEROVER */
		if (error == GIT_ITEROVER)
			error = 0;
	}

cleanup:
	if (!error)
		*diff_ptr = diff;
	else
		git_diff_free(diff);

	git_buf_free(&info.ignore_prefix);

	return error;
}

#define DIFF_FROM_ITERATORS(MAKE_FIRST, MAKE_SECOND) do { \
	git_iterator *a = NULL, *b = NULL; \
	char *pfx = opts ? git_pathspec_prefix(&opts->pathspec) : NULL; \
	GITERR_CHECK_VERSION(opts, GIT_DIFF_OPTIONS_VERSION, "git_diff_options"); \
	if (!(error = MAKE_FIRST) && !(error = MAKE_SECOND)) \
		error = git_diff__from_iterators(diff, repo, a, b, opts); \
	git__free(pfx); git_iterator_free(a); git_iterator_free(b); \
} while (0)

int git_diff_tree_to_tree(
	git_diff **diff,
	git_repository *repo,
	git_tree *old_tree,
	git_tree *new_tree,
	const git_diff_options *opts)
{
	int error = 0;
	git_iterator_flag_t iflag = GIT_ITERATOR_DONT_IGNORE_CASE;

	assert(diff && repo);

	/* for tree to tree diff, be case sensitive even if the index is
	 * currently case insensitive, unless the user explicitly asked
	 * for case insensitivity
	 */
	if (opts && (opts->flags & GIT_DIFF_IGNORE_CASE) != 0)
		iflag = GIT_ITERATOR_IGNORE_CASE;

	DIFF_FROM_ITERATORS(
		git_iterator_for_tree(&a, old_tree, iflag, pfx, pfx),
		git_iterator_for_tree(&b, new_tree, iflag, pfx, pfx)
	);

	return error;
}

static int diff_load_index(git_index **index, git_repository *repo)
{
	int error = git_repository_index__weakptr(index, repo);

	/* reload the repository index when user did not pass one in */
	if (!error && git_index_read(*index, false) < 0)
		giterr_clear();

	return error;
}

int git_diff_tree_to_index(
	git_diff **diff,
	git_repository *repo,
	git_tree *old_tree,
	git_index *index,
	const git_diff_options *opts)
{
	int error = 0;
	bool reset_index_ignore_case = false;

	assert(diff && repo);

	if (!index && (error = diff_load_index(&index, repo)) < 0)
		return error;

	if (index->ignore_case) {
		git_index__set_ignore_case(index, false);
		reset_index_ignore_case = true;
	}

	DIFF_FROM_ITERATORS(
		git_iterator_for_tree(&a, old_tree, 0, pfx, pfx),
		git_iterator_for_index(&b, index, 0, pfx, pfx)
	);

	if (reset_index_ignore_case) {
		git_index__set_ignore_case(index, true);

		if (!error) {
			git_diff *d = *diff;

			d->opts.flags |= GIT_DIFF_IGNORE_CASE;
			d->strcomp    = git__strcasecmp;
			d->strncomp   = git__strncasecmp;
			d->pfxcomp    = git__prefixcmp_icase;
			d->entrycomp  = git_index_entry__cmp_icase;

			git_vector_set_cmp(&d->deltas, git_diff_delta__casecmp);
			git_vector_sort(&d->deltas);
		}
	}

	return error;
}

int git_diff_index_to_workdir(
	git_diff **diff,
	git_repository *repo,
	git_index *index,
	const git_diff_options *opts)
{
	int error = 0;

	assert(diff && repo);

	if (!index && (error = diff_load_index(&index, repo)) < 0)
		return error;

	DIFF_FROM_ITERATORS(
		git_iterator_for_index(&a, index, 0, pfx, pfx),
		git_iterator_for_workdir(
			&b, repo, GIT_ITERATOR_DONT_AUTOEXPAND, pfx, pfx)
	);

	return error;
}

int git_diff_tree_to_workdir(
	git_diff **diff,
	git_repository *repo,
	git_tree *old_tree,
	const git_diff_options *opts)
{
	int error = 0;

	assert(diff && repo);

	DIFF_FROM_ITERATORS(
		git_iterator_for_tree(&a, old_tree, 0, pfx, pfx),
		git_iterator_for_workdir(
			&b, repo, GIT_ITERATOR_DONT_AUTOEXPAND, pfx, pfx)
	);

	return error;
}

int git_diff_tree_to_workdir_with_index(
	git_diff **diff,
	git_repository *repo,
	git_tree *old_tree,
	const git_diff_options *opts)
{
	int error = 0;
	git_diff *d1 = NULL, *d2 = NULL;
	git_index *index = NULL;

	assert(diff && repo);

	if ((error = diff_load_index(&index, repo)) < 0)
		return error;

	if (!(error = git_diff_tree_to_index(&d1, repo, old_tree, index, opts)) &&
		!(error = git_diff_index_to_workdir(&d2, repo, index, opts)))
		error = git_diff_merge(d1, d2);

	git_diff_free(d2);

	if (error) {
		git_diff_free(d1);
		d1 = NULL;
	}

	*diff = d1;
	return error;
}

int git_diff_options_init(git_diff_options *options, unsigned int version)
{
	git_diff_options template = GIT_DIFF_OPTIONS_INIT;

	if (version != template.version) {
		giterr_set(GITERR_INVALID,
			"Invalid version %d for git_diff_options", (int)version);
		return -1;
	}

	memcpy(options, &template, sizeof(*options));
	return 0;
}

size_t git_diff_num_deltas(const git_diff *diff)
{
	assert(diff);
	return diff->deltas.length;
}

size_t git_diff_num_deltas_of_type(const git_diff *diff, git_delta_t type)
{
	size_t i, count = 0;
	const git_diff_delta *delta;

	assert(diff);

	git_vector_foreach(&diff->deltas, i, delta) {
		count += (delta->status == type);
	}

	return count;
}

const git_diff_delta *git_diff_get_delta(const git_diff *diff, size_t idx)
{
	assert(diff);
	return git_vector_get(&diff->deltas, idx);
}

int git_diff_is_sorted_icase(const git_diff *diff)
{
	return (diff->opts.flags & GIT_DIFF_IGNORE_CASE) != 0;
}

int git_diff__paired_foreach(
	git_diff *head2idx,
	git_diff *idx2wd,
	int (*cb)(git_diff_delta *h2i, git_diff_delta *i2w, void *payload),
	void *payload)
{
	int cmp, error = 0;
	git_diff_delta *h2i, *i2w;
	size_t i, j, i_max, j_max;
	int (*strcomp)(const char *, const char *) = git__strcmp;
	bool h2i_icase, i2w_icase, icase_mismatch;

	i_max = head2idx ? head2idx->deltas.length : 0;
	j_max = idx2wd ? idx2wd->deltas.length : 0;
	if (!i_max && !j_max)
		return 0;

	/* At some point, tree-to-index diffs will probably never ignore case,
	 * even if that isn't true now.  Index-to-workdir diffs may or may not
	 * ignore case, but the index filename for the idx2wd diff should
	 * still be using the canonical case-preserving name.
	 *
	 * Therefore the main thing we need to do here is make sure the diffs
	 * are traversed in a compatible order.  To do this, we temporarily
	 * resort a mismatched diff to get the order correct.
	 *
	 * In order to traverse renames in the index->workdir, we need to
	 * ensure that we compare the index name on both sides, so we
	 * always sort by the old name in the i2w list.
	 */
	h2i_icase = head2idx != NULL &&
		(head2idx->opts.flags & GIT_DIFF_IGNORE_CASE) != 0;

	i2w_icase = idx2wd != NULL &&
		(idx2wd->opts.flags & GIT_DIFF_IGNORE_CASE) != 0;

	icase_mismatch =
		(head2idx != NULL && idx2wd != NULL && h2i_icase != i2w_icase);

	if (icase_mismatch && h2i_icase) {
		git_vector_set_cmp(&head2idx->deltas, git_diff_delta__cmp);
		git_vector_sort(&head2idx->deltas);
	}

	if (i2w_icase && !icase_mismatch) {
		strcomp = git__strcasecmp;

		git_vector_set_cmp(&idx2wd->deltas, git_diff_delta__i2w_casecmp);
		git_vector_sort(&idx2wd->deltas);
	} else if (idx2wd != NULL) {
		git_vector_set_cmp(&idx2wd->deltas, git_diff_delta__i2w_cmp);
		git_vector_sort(&idx2wd->deltas);
	}

	for (i = 0, j = 0; i < i_max || j < j_max; ) {
		h2i = head2idx ? GIT_VECTOR_GET(&head2idx->deltas, i) : NULL;
		i2w = idx2wd ? GIT_VECTOR_GET(&idx2wd->deltas, j) : NULL;

		cmp = !i2w ? -1 : !h2i ? 1 :
			strcomp(h2i->new_file.path, i2w->old_file.path);

		if (cmp < 0) {
			i++; i2w = NULL;
		} else if (cmp > 0) {
			j++; h2i = NULL;
		} else {
			i++; j++;
		}

		if ((error = cb(h2i, i2w, payload)) != 0) {
			giterr_set_after_callback(error);
			break;
		}
	}

	/* restore case-insensitive delta sort */
	if (icase_mismatch && h2i_icase) {
		git_vector_set_cmp(&head2idx->deltas, git_diff_delta__casecmp);
		git_vector_sort(&head2idx->deltas);
	}

	/* restore idx2wd sort by new path */
	if (idx2wd != NULL) {
		git_vector_set_cmp(&idx2wd->deltas,
			i2w_icase ? git_diff_delta__casecmp : git_diff_delta__cmp);
		git_vector_sort(&idx2wd->deltas);
	}

	return error;
}

int git_diff_init_options(git_diff_options* opts, int version)
{
	if (version != GIT_DIFF_OPTIONS_VERSION) {
		giterr_set(GITERR_INVALID, "Invalid version %d for git_diff_options", version);
		return -1;
	} else {
		git_diff_options o = GIT_DIFF_OPTIONS_INIT;
		memcpy(opts, &o, sizeof(o));
		return 0;
	}
}

int git_diff_find_init_options(git_diff_find_options* opts, int version)
{
	if (version != GIT_DIFF_FIND_OPTIONS_VERSION) {
		giterr_set(GITERR_INVALID, "Invalid version %d for git_diff_find_options", version);
		return -1;
	} else {
		git_diff_find_options o = GIT_DIFF_FIND_OPTIONS_INIT;
		memcpy(opts, &o, sizeof(o));
		return 0;
	}
}
