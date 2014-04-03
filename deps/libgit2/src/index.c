/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */

#include <stddef.h>

#include "common.h"
#include "repository.h"
#include "index.h"
#include "tree.h"
#include "tree-cache.h"
#include "hash.h"
#include "iterator.h"
#include "pathspec.h"
#include "ignore.h"
#include "blob.h"

#include "git2/odb.h"
#include "git2/oid.h"
#include "git2/blob.h"
#include "git2/config.h"
#include "git2/sys/index.h"

#define entry_size(type,len) ((offsetof(type, path) + (len) + 8) & ~7)
#define short_entry_size(len) entry_size(struct entry_short, len)
#define long_entry_size(len) entry_size(struct entry_long, len)

#define minimal_entry_size (offsetof(struct entry_short, path))

static const size_t INDEX_FOOTER_SIZE = GIT_OID_RAWSZ;
static const size_t INDEX_HEADER_SIZE = 12;

static const unsigned int INDEX_VERSION_NUMBER = 2;
static const unsigned int INDEX_VERSION_NUMBER_EXT = 3;

static const unsigned int INDEX_HEADER_SIG = 0x44495243;
static const char INDEX_EXT_TREECACHE_SIG[] = {'T', 'R', 'E', 'E'};
static const char INDEX_EXT_UNMERGED_SIG[] = {'R', 'E', 'U', 'C'};
static const char INDEX_EXT_CONFLICT_NAME_SIG[] = {'N', 'A', 'M', 'E'};

#define INDEX_OWNER(idx) ((git_repository *)(GIT_REFCOUNT_OWNER(idx)))

struct index_header {
	uint32_t signature;
	uint32_t version;
	uint32_t entry_count;
};

struct index_extension {
	char signature[4];
	uint32_t extension_size;
};

struct entry_time {
	uint32_t seconds;
	uint32_t nanoseconds;
};

struct entry_short {
	struct entry_time ctime;
	struct entry_time mtime;
	uint32_t dev;
	uint32_t ino;
	uint32_t mode;
	uint32_t uid;
	uint32_t gid;
	uint32_t file_size;
	git_oid oid;
	uint16_t flags;
	char path[1]; /* arbitrary length */
};

struct entry_long {
	struct entry_time ctime;
	struct entry_time mtime;
	uint32_t dev;
	uint32_t ino;
	uint32_t mode;
	uint32_t uid;
	uint32_t gid;
	uint32_t file_size;
	git_oid oid;
	uint16_t flags;
	uint16_t flags_extended;
	char path[1]; /* arbitrary length */
};

struct entry_srch_key {
	const char *path;
	size_t path_len;
	int stage;
};

/* local declarations */
static size_t read_extension(git_index *index, const char *buffer, size_t buffer_size);
static size_t read_entry(git_index_entry *dest, const void *buffer, size_t buffer_size);
static int read_header(struct index_header *dest, const void *buffer);

static int parse_index(git_index *index, const char *buffer, size_t buffer_size);
static bool is_index_extended(git_index *index);
static int write_index(git_index *index, git_filebuf *file);

static void index_entry_free(git_index_entry *entry);
static void index_entry_reuc_free(git_index_reuc_entry *reuc);

static int index_srch(const void *key, const void *array_member)
{
	const struct entry_srch_key *srch_key = key;
	const git_index_entry *entry = array_member;
	int cmp;
	size_t len1, len2, len;

	len1 = srch_key->path_len;
	len2 = strlen(entry->path);
	len = len1 < len2 ? len1 : len2;

	cmp = memcmp(srch_key->path, entry->path, len);
	if (cmp)
		return cmp;
	if (len1 < len2)
		return -1;
	if (len1 > len2)
		return 1;

	if (srch_key->stage != GIT_INDEX_STAGE_ANY)
		return srch_key->stage - GIT_IDXENTRY_STAGE(entry);

	return 0;
}

static int index_isrch(const void *key, const void *array_member)
{
	const struct entry_srch_key *srch_key = key;
	const git_index_entry *entry = array_member;
	int cmp;
	size_t len1, len2, len;

	len1 = srch_key->path_len;
	len2 = strlen(entry->path);
	len = len1 < len2 ? len1 : len2;

	cmp = strncasecmp(srch_key->path, entry->path, len);

	if (cmp)
		return cmp;
	if (len1 < len2)
		return -1;
	if (len1 > len2)
		return 1;

	if (srch_key->stage != GIT_INDEX_STAGE_ANY)
		return srch_key->stage - GIT_IDXENTRY_STAGE(entry);

	return 0;
}

static int index_cmp_path(const void *a, const void *b)
{
	return strcmp((const char *)a, (const char *)b);
}

static int index_icmp_path(const void *a, const void *b)
{
	return strcasecmp((const char *)a, (const char *)b);
}

static int index_srch_path(const void *path, const void *array_member)
{
	const git_index_entry *entry = array_member;

	return strcmp((const char *)path, entry->path);
}

static int index_isrch_path(const void *path, const void *array_member)
{
	const git_index_entry *entry = array_member;

	return strcasecmp((const char *)path, entry->path);
}

static int index_cmp(const void *a, const void *b)
{
	int diff;
	const git_index_entry *entry_a = a;
	const git_index_entry *entry_b = b;

	diff = strcmp(entry_a->path, entry_b->path);

	if (diff == 0)
		diff = (GIT_IDXENTRY_STAGE(entry_a) - GIT_IDXENTRY_STAGE(entry_b));

	return diff;
}

static int index_icmp(const void *a, const void *b)
{
	int diff;
	const git_index_entry *entry_a = a;
	const git_index_entry *entry_b = b;

	diff = strcasecmp(entry_a->path, entry_b->path);

	if (diff == 0)
		diff = (GIT_IDXENTRY_STAGE(entry_a) - GIT_IDXENTRY_STAGE(entry_b));

	return diff;
}

static int conflict_name_cmp(const void *a, const void *b)
{
	const git_index_name_entry *name_a = a;
	const git_index_name_entry *name_b = b;

	if (name_a->ancestor && !name_b->ancestor)
		return 1;

	if (!name_a->ancestor && name_b->ancestor)
		return -1;

	if (name_a->ancestor)
		return strcmp(name_a->ancestor, name_b->ancestor);

	if (!name_a->ours || !name_b->ours)
		return 0;

	return strcmp(name_a->ours, name_b->ours);
}

/**
 * TODO: enable this when resolving case insensitive conflicts
 */
#if 0
static int conflict_name_icmp(const void *a, const void *b)
{
	const git_index_name_entry *name_a = a;
	const git_index_name_entry *name_b = b;

	if (name_a->ancestor && !name_b->ancestor)
		return 1;

	if (!name_a->ancestor && name_b->ancestor)
		return -1;

	if (name_a->ancestor)
		return strcasecmp(name_a->ancestor, name_b->ancestor);

	if (!name_a->ours || !name_b->ours)
		return 0;

	return strcasecmp(name_a->ours, name_b->ours);
}
#endif

static int reuc_srch(const void *key, const void *array_member)
{
	const git_index_reuc_entry *reuc = array_member;

	return strcmp(key, reuc->path);
}

static int reuc_isrch(const void *key, const void *array_member)
{
	const git_index_reuc_entry *reuc = array_member;

	return strcasecmp(key, reuc->path);
}

static int reuc_cmp(const void *a, const void *b)
{
	const git_index_reuc_entry *info_a = a;
	const git_index_reuc_entry *info_b = b;

	return strcmp(info_a->path, info_b->path);
}

static int reuc_icmp(const void *a, const void *b)
{
	const git_index_reuc_entry *info_a = a;
	const git_index_reuc_entry *info_b = b;

	return strcasecmp(info_a->path, info_b->path);
}

static void index_entry_reuc_free(git_index_reuc_entry *reuc)
{
	if (!reuc)
		return;
	git__free(reuc->path);
	git__free(reuc);
}

static void index_entry_free(git_index_entry *entry)
{
	if (!entry)
		return;
	git__free(entry->path);
	git__free(entry);
}

unsigned int git_index__create_mode(unsigned int mode)
{
	if (S_ISLNK(mode))
		return S_IFLNK;

	if (S_ISDIR(mode) || (mode & S_IFMT) == (S_IFLNK | S_IFDIR))
		return (S_IFLNK | S_IFDIR);

	return S_IFREG | GIT_PERMS_CANONICAL(mode);
}

static unsigned int index_merge_mode(
	git_index *index, git_index_entry *existing, unsigned int mode)
{
	if (index->no_symlinks && S_ISREG(mode) &&
		existing && S_ISLNK(existing->mode))
		return existing->mode;

	if (index->distrust_filemode && S_ISREG(mode))
		return (existing && S_ISREG(existing->mode)) ?
			existing->mode : git_index__create_mode(0666);

	return git_index__create_mode(mode);
}

void git_index__set_ignore_case(git_index *index, bool ignore_case)
{
	index->ignore_case = ignore_case;

	index->entries_cmp_path = ignore_case ? index_icmp_path : index_cmp_path;
	index->entries_search = ignore_case ? index_isrch : index_srch;
	index->entries_search_path = ignore_case ? index_isrch_path : index_srch_path;

	git_vector_set_cmp(&index->entries, ignore_case ? index_icmp : index_cmp);
	git_vector_sort(&index->entries);

	index->reuc_search = ignore_case ? reuc_isrch : reuc_srch;

	git_vector_set_cmp(&index->reuc, ignore_case ? reuc_icmp : reuc_cmp);
	git_vector_sort(&index->reuc);
}

int git_index_open(git_index **index_out, const char *index_path)
{
	git_index *index;
	int error;

	assert(index_out);

	index = git__calloc(1, sizeof(git_index));
	GITERR_CHECK_ALLOC(index);

	if (index_path != NULL) {
		index->index_file_path = git__strdup(index_path);
		GITERR_CHECK_ALLOC(index->index_file_path);

		/* Check if index file is stored on disk already */
		if (git_path_exists(index->index_file_path) == true)
			index->on_disk = 1;
	}

	if (git_vector_init(&index->entries, 32, index_cmp) < 0 ||
		git_vector_init(&index->names, 32, conflict_name_cmp) < 0 ||
		git_vector_init(&index->reuc, 32, reuc_cmp) < 0)
		return -1;

	index->entries_cmp_path = index_cmp_path;
	index->entries_search = index_srch;
	index->entries_search_path = index_srch_path;
	index->reuc_search = reuc_srch;

	if ((index_path != NULL) && ((error = git_index_read(index, true)) < 0)) {
		git_index_free(index);
		return error;
	}

	*index_out = index;
	GIT_REFCOUNT_INC(index);

	return 0;
}

int git_index_new(git_index **out)
{
	return git_index_open(out, NULL);
}

static void index_free(git_index *index)
{
	git_index_clear(index);
	git_vector_free(&index->entries);
	git_vector_free(&index->names);
	git_vector_free(&index->reuc);

	git__free(index->index_file_path);

	git__memzero(index, sizeof(*index));
	git__free(index);
}

void git_index_free(git_index *index)
{
	if (index == NULL)
		return;

	GIT_REFCOUNT_DEC(index, index_free);
}

static void index_entries_free(git_vector *entries)
{
	size_t i;

	for (i = 0; i < entries->length; ++i)
		index_entry_free(git__swap(entries->contents[i], NULL));

	git_vector_clear(entries);
}

void git_index_clear(git_index *index)
{
	assert(index);

	index_entries_free(&index->entries);
	git_index_reuc_clear(index);
	git_index_name_clear(index);

	git_futils_filestamp_set(&index->stamp, NULL);

	git_tree_cache_free(index->tree);
	index->tree = NULL;
}

static int create_index_error(int error, const char *msg)
{
	giterr_set(GITERR_INDEX, msg);
	return error;
}

int git_index_set_caps(git_index *index, int caps)
{
	unsigned int old_ignore_case;

	assert(index);

	old_ignore_case = index->ignore_case;

	if (caps == GIT_INDEXCAP_FROM_OWNER) {
		git_repository *repo = INDEX_OWNER(index);
		int val;

		if (!repo)
			return create_index_error(
				-1, "Cannot access repository to set index caps");

		if (!git_repository__cvar(&val, repo, GIT_CVAR_IGNORECASE))
			index->ignore_case = (val != 0);
		if (!git_repository__cvar(&val, repo, GIT_CVAR_FILEMODE))
			index->distrust_filemode = (val == 0);
		if (!git_repository__cvar(&val, repo, GIT_CVAR_SYMLINKS))
			index->no_symlinks = (val == 0);
	}
	else {
		index->ignore_case = ((caps & GIT_INDEXCAP_IGNORE_CASE) != 0);
		index->distrust_filemode = ((caps & GIT_INDEXCAP_NO_FILEMODE) != 0);
		index->no_symlinks = ((caps & GIT_INDEXCAP_NO_SYMLINKS) != 0);
	}

	if (old_ignore_case != index->ignore_case) {
		git_index__set_ignore_case(index, (bool)index->ignore_case);
	}

	return 0;
}

int git_index_caps(const git_index *index)
{
	return ((index->ignore_case ? GIT_INDEXCAP_IGNORE_CASE : 0) |
			(index->distrust_filemode ? GIT_INDEXCAP_NO_FILEMODE : 0) |
			(index->no_symlinks ? GIT_INDEXCAP_NO_SYMLINKS : 0));
}

int git_index_read(git_index *index, int force)
{
	int error = 0, updated;
	git_buf buffer = GIT_BUF_INIT;
	git_futils_filestamp stamp = index->stamp;

	if (!index->index_file_path)
		return create_index_error(-1,
			"Failed to read index: The index is in-memory only");

	index->on_disk = git_path_exists(index->index_file_path);

	if (!index->on_disk) {
		if (force)
			git_index_clear(index);
		return 0;
	}

	updated = git_futils_filestamp_check(&stamp, index->index_file_path);
	if (updated < 0 || (!updated && !force))
		return updated;

	error = git_futils_readbuffer(&buffer, index->index_file_path);
	if (error < 0)
		return error;

	git_index_clear(index);
	error = parse_index(index, buffer.ptr, buffer.size);

	if (!error)
		git_futils_filestamp_set(&index->stamp, &stamp);

	git_buf_free(&buffer);
	return error;
}

int git_index_write(git_index *index)
{
	git_filebuf file = GIT_FILEBUF_INIT;
	int error;

	if (!index->index_file_path)
		return create_index_error(-1,
			"Failed to read index: The index is in-memory only");

	git_vector_sort(&index->entries);
	git_vector_sort(&index->reuc);

	if ((error = git_filebuf_open(
		&file, index->index_file_path, GIT_FILEBUF_HASH_CONTENTS, GIT_INDEX_FILE_MODE)) < 0) {
		if (error == GIT_ELOCKED)
			giterr_set(GITERR_INDEX, "The index is locked. This might be due to a concurrent or crashed process");

		return error;
	}

	if ((error = write_index(index, &file)) < 0) {
		git_filebuf_cleanup(&file);
		return error;
	}

	if ((error = git_filebuf_commit(&file)) < 0)
		return error;

	error = git_futils_filestamp_check(&index->stamp, index->index_file_path);
	if (error < 0)
		return error;

	index->on_disk = 1;
	return 0;
}

const char * git_index_path(git_index *index)
{
	assert(index);
	return index->index_file_path;
}

int git_index_write_tree(git_oid *oid, git_index *index)
{
	git_repository *repo;

	assert(oid && index);

	repo = INDEX_OWNER(index);

	if (repo == NULL)
		return create_index_error(-1, "Failed to write tree. "
		  "The index file is not backed up by an existing repository");

	return git_tree__write_index(oid, index, repo);
}

int git_index_write_tree_to(git_oid *oid, git_index *index, git_repository *repo)
{
	assert(oid && index && repo);
	return git_tree__write_index(oid, index, repo);
}

size_t git_index_entrycount(const git_index *index)
{
	assert(index);
	return index->entries.length;
}

const git_index_entry *git_index_get_byindex(
	git_index *index, size_t n)
{
	assert(index);
	git_vector_sort(&index->entries);
	return git_vector_get(&index->entries, n);
}

const git_index_entry *git_index_get_bypath(
	git_index *index, const char *path, int stage)
{
	size_t pos;

	assert(index);

	if (git_index__find(&pos, index, path, 0, stage) < 0) {
		giterr_set(GITERR_INDEX, "Index does not contain %s", path);
		return NULL;
	}

	return git_index_get_byindex(index, pos);
}

void git_index_entry__init_from_stat(
	git_index_entry *entry, struct stat *st, bool trust_mode)
{
	entry->ctime.seconds = (git_time_t)st->st_ctime;
	entry->mtime.seconds = (git_time_t)st->st_mtime;
	/* entry->mtime.nanoseconds = st->st_mtimensec; */
	/* entry->ctime.nanoseconds = st->st_ctimensec; */
	entry->dev  = st->st_rdev;
	entry->ino  = st->st_ino;
	entry->mode = (!trust_mode && S_ISREG(st->st_mode)) ?
		git_index__create_mode(0666) : git_index__create_mode(st->st_mode);
	entry->uid  = st->st_uid;
	entry->gid  = st->st_gid;
	entry->file_size = st->st_size;
}

int git_index_entry__cmp(const void *a, const void *b)
{
	const git_index_entry *entry_a = a;
	const git_index_entry *entry_b = b;

	return strcmp(entry_a->path, entry_b->path);
}

int git_index_entry__cmp_icase(const void *a, const void *b)
{
	const git_index_entry *entry_a = a;
	const git_index_entry *entry_b = b;

	return strcasecmp(entry_a->path, entry_b->path);
}

static int index_entry_init(
	git_index_entry **entry_out, git_index *index, const char *rel_path)
{
	int error = 0;
	git_index_entry *entry = NULL;
	struct stat st;
	git_oid oid;

	if (INDEX_OWNER(index) == NULL)
		return create_index_error(-1,
			"Could not initialize index entry. "
			"Index is not backed up by an existing repository.");

	/* write the blob to disk and get the oid and stat info */
	error = git_blob__create_from_paths(
		&oid, &st, INDEX_OWNER(index), NULL, rel_path, 0, true);
	if (error < 0)
		return error;

	entry = git__calloc(1, sizeof(git_index_entry));
	GITERR_CHECK_ALLOC(entry);

	git_index_entry__init_from_stat(entry, &st, !index->distrust_filemode);

	entry->id = oid;
	entry->path = git__strdup(rel_path);
	GITERR_CHECK_ALLOC(entry->path);

	*entry_out = entry;
	return 0;
}

static int index_entry_reuc_init(git_index_reuc_entry **reuc_out,
	const char *path,
	int ancestor_mode, const git_oid *ancestor_oid,
	int our_mode, const git_oid *our_oid,
	int their_mode, const git_oid *their_oid)
{
	git_index_reuc_entry *reuc = NULL;

	assert(reuc_out && path);

	*reuc_out = NULL;

	reuc = git__calloc(1, sizeof(git_index_reuc_entry));
	GITERR_CHECK_ALLOC(reuc);

	reuc->path = git__strdup(path);
	if (reuc->path == NULL)
		return -1;

	if ((reuc->mode[0] = ancestor_mode) > 0)
		git_oid_cpy(&reuc->oid[0], ancestor_oid);

	if ((reuc->mode[1] = our_mode) > 0)
		git_oid_cpy(&reuc->oid[1], our_oid);

	if ((reuc->mode[2] = their_mode) > 0)
		git_oid_cpy(&reuc->oid[2], their_oid);

	*reuc_out = reuc;
	return 0;
}

static git_index_entry *index_entry_dup(const git_index_entry *source_entry)
{
	git_index_entry *entry;

	entry = git__malloc(sizeof(git_index_entry));
	if (!entry)
		return NULL;

	memcpy(entry, source_entry, sizeof(git_index_entry));

	/* duplicate the path string so we own it */
	entry->path = git__strdup(entry->path);
	if (!entry->path)
		return NULL;

	return entry;
}

static int has_file_name(git_index *index,
	 const git_index_entry *entry, size_t pos, int ok_to_replace)
{
	int retval = 0;
	size_t len = strlen(entry->path);
	int stage = GIT_IDXENTRY_STAGE(entry);
	const char *name = entry->path;

	while (pos < index->entries.length) {
		git_index_entry *p = index->entries.contents[pos++];

		if (len >= strlen(p->path))
			break;
		if (memcmp(name, p->path, len))
			break;
		if (GIT_IDXENTRY_STAGE(p) != stage)
			continue;
		if (p->path[len] != '/')
			continue;
		retval = -1;
		if (!ok_to_replace)
			break;
		git_vector_remove(&index->entries, --pos);
	}
	return retval;
}

/*
 * Do we have another file with a pathname that is a proper
 * subset of the name we're trying to add?
 */
static int has_dir_name(git_index *index,
		const git_index_entry *entry, int ok_to_replace)
{
	int retval = 0;
	int stage = GIT_IDXENTRY_STAGE(entry);
	const char *name = entry->path;
	const char *slash = name + strlen(name);

	for (;;) {
		size_t len, position;

		for (;;) {
			if (*--slash == '/')
				break;
			if (slash <= entry->path)
				return retval;
		}
		len = slash - name;

		if (git_index__find(&position, index, name, len, stage) == 0) {
			retval = -1;
			if (!ok_to_replace)
				break;

			git_vector_remove(&index->entries, position);
			continue;
		}

		/*
		 * Trivial optimization: if we find an entry that
		 * already matches the sub-directory, then we know
		 * we're ok, and we can exit.
		 */
		while (position < index->entries.length) {
			git_index_entry *p = index->entries.contents[position];

			if ((strlen(p->path) <= len) ||
			    (p->path[len] != '/') ||
			    memcmp(p->path, name, len))
				break; /* not our subdirectory */

			if (GIT_IDXENTRY_STAGE(p) == stage)
				return retval;

			position++;
		}
	}
	return retval;
}

static int check_file_directory_collision(git_index *index,
		git_index_entry *entry, size_t pos, int ok_to_replace)
{
	int retval = has_file_name(index, entry, pos, ok_to_replace);
	retval = retval + has_dir_name(index, entry, ok_to_replace);

	if (retval) {
		giterr_set(GITERR_INDEX, "'%s' appears as both a file an a directory", entry->path);
		return -1;
	}

	return 0;
}

static int index_insert(git_index *index, git_index_entry *entry, int replace)
{
	size_t path_length, position;
	git_index_entry **existing = NULL;

	assert(index && entry && entry->path != NULL);

	/* make sure that the path length flag is correct */
	path_length = strlen(entry->path);

	entry->flags &= ~GIT_IDXENTRY_NAMEMASK;

	if (path_length < GIT_IDXENTRY_NAMEMASK)
		entry->flags |= path_length & GIT_IDXENTRY_NAMEMASK;
	else
		entry->flags |= GIT_IDXENTRY_NAMEMASK;

	/* look if an entry with this path already exists */
	if (!git_index__find(
			&position, index, entry->path, 0, GIT_IDXENTRY_STAGE(entry))) {
		existing = (git_index_entry **)&index->entries.contents[position];
		/* update filemode to existing values if stat is not trusted */
		entry->mode = index_merge_mode(index, *existing, entry->mode);
	}

	if (check_file_directory_collision(index, entry, position, replace) < 0)
		return -1;

	/* if replacing is not requested or no existing entry exists, just
	 * insert entry at the end; the index is no longer sorted
	 */
	if (!replace || !existing)
		return git_vector_insert(&index->entries, entry);

	/* exists, replace it (preserving name from existing entry) */
	git__free(entry->path);
	entry->path = (*existing)->path;
	git__free(*existing);
	*existing = entry;

	return 0;
}

static int index_conflict_to_reuc(git_index *index, const char *path)
{
	const git_index_entry *conflict_entries[3];
	int ancestor_mode, our_mode, their_mode;
	git_oid const *ancestor_oid, *our_oid, *their_oid;
	int ret;

	if ((ret = git_index_conflict_get(&conflict_entries[0],
		&conflict_entries[1], &conflict_entries[2], index, path)) < 0)
		return ret;

	ancestor_mode = conflict_entries[0] == NULL ? 0 : conflict_entries[0]->mode;
	our_mode = conflict_entries[1] == NULL ? 0 : conflict_entries[1]->mode;
	their_mode = conflict_entries[2] == NULL ? 0 : conflict_entries[2]->mode;

	ancestor_oid = conflict_entries[0] == NULL ? NULL : &conflict_entries[0]->id;
	our_oid = conflict_entries[1] == NULL ? NULL : &conflict_entries[1]->id;
	their_oid = conflict_entries[2] == NULL ? NULL : &conflict_entries[2]->id;

	if ((ret = git_index_reuc_add(index, path, ancestor_mode, ancestor_oid,
		our_mode, our_oid, their_mode, their_oid)) >= 0)
		ret = git_index_conflict_remove(index, path);

	return ret;
}

int git_index_add_bypath(git_index *index, const char *path)
{
	git_index_entry *entry = NULL;
	int ret;

	assert(index && path);

	if ((ret = index_entry_init(&entry, index, path)) < 0 ||
		(ret = index_insert(index, entry, 1)) < 0)
		goto on_error;

	/* Adding implies conflict was resolved, move conflict entries to REUC */
	if ((ret = index_conflict_to_reuc(index, path)) < 0 && ret != GIT_ENOTFOUND)
		goto on_error;

	git_tree_cache_invalidate_path(index->tree, entry->path);
	return 0;

on_error:
	index_entry_free(entry);
	return ret;
}

int git_index_remove_bypath(git_index *index, const char *path)
{
	int ret;

	assert(index && path);

	if (((ret = git_index_remove(index, path, 0)) < 0 &&
		ret != GIT_ENOTFOUND) ||
		((ret = index_conflict_to_reuc(index, path)) < 0 &&
		ret != GIT_ENOTFOUND))
		return ret;

	return 0;
}

int git_index_add(git_index *index, const git_index_entry *source_entry)
{
	git_index_entry *entry = NULL;
	int ret;

	entry = index_entry_dup(source_entry);
	if (entry == NULL)
		return -1;

	if ((ret = index_insert(index, entry, 1)) < 0) {
		index_entry_free(entry);
		return ret;
	}

	git_tree_cache_invalidate_path(index->tree, entry->path);
	return 0;
}

int git_index_remove(git_index *index, const char *path, int stage)
{
	size_t position;
	int error;
	git_index_entry *entry;

	if (git_index__find(&position, index, path, 0, stage) < 0) {
		giterr_set(GITERR_INDEX, "Index does not contain %s at stage %d",
			path, stage);
		return GIT_ENOTFOUND;
	}

	entry = git_vector_get(&index->entries, position);
	if (entry != NULL)
		git_tree_cache_invalidate_path(index->tree, entry->path);

	error = git_vector_remove(&index->entries, position);

	if (!error)
		index_entry_free(entry);

	return error;
}

int git_index_remove_directory(git_index *index, const char *dir, int stage)
{
	git_buf pfx = GIT_BUF_INIT;
	int error = 0;
	size_t pos;
	git_index_entry *entry;

	if (git_buf_sets(&pfx, dir) < 0 || git_path_to_dir(&pfx) < 0)
		return -1;

	git_vector_sort(&index->entries);

	pos = git_index__prefix_position(index, pfx.ptr);

	while (1) {
		entry = git_vector_get(&index->entries, pos);
		if (!entry || git__prefixcmp(entry->path, pfx.ptr) != 0)
			break;

		if (GIT_IDXENTRY_STAGE(entry) != stage) {
			++pos;
			continue;
		}

		git_tree_cache_invalidate_path(index->tree, entry->path);

		if ((error = git_vector_remove(&index->entries, pos)) < 0)
			break;
		index_entry_free(entry);

		/* removed entry at 'pos' so we don't need to increment it */
	}

	git_buf_free(&pfx);

	return error;
}

int git_index__find(
	size_t *out, git_index *index, const char *path, size_t path_len, int stage)
{
	struct entry_srch_key srch_key;

	assert(path);

	git_vector_sort(&index->entries);

	srch_key.path = path;
	srch_key.path_len = !path_len ? strlen(path) : path_len;
	srch_key.stage = stage;

	return git_vector_bsearch2(
		out, &index->entries, index->entries_search, &srch_key);
}

int git_index_find(size_t *at_pos, git_index *index, const char *path)
{
	size_t pos;

	assert(index && path);

	if (git_vector_bsearch2(&pos, &index->entries, index->entries_search_path, path) < 0) {
		giterr_set(GITERR_INDEX, "Index does not contain %s", path);
		return GIT_ENOTFOUND;
	}

	/* Since our binary search only looked at path, we may be in the
	 * middle of a list of stages.
	 */
	while (pos > 0) {
		const git_index_entry *prev = git_vector_get(&index->entries, pos-1);

		if (index->entries_cmp_path(prev->path, path) != 0)
			break;

		--pos;
	}

	if (at_pos)
		*at_pos = pos;

	return 0;
}

size_t git_index__prefix_position(git_index *index, const char *path)
{
	struct entry_srch_key srch_key;
	size_t pos;

	srch_key.path = path;
	srch_key.path_len = strlen(path);
	srch_key.stage = 0;

	git_vector_sort(&index->entries);
	git_vector_bsearch2(
		&pos, &index->entries, index->entries_search, &srch_key);

	return pos;
}

int git_index_conflict_add(git_index *index,
	const git_index_entry *ancestor_entry,
	const git_index_entry *our_entry,
	const git_index_entry *their_entry)
{
	git_index_entry *entries[3] = { 0 };
	unsigned short i;
	int ret = 0;

	assert (index);

	if ((ancestor_entry != NULL && (entries[0] = index_entry_dup(ancestor_entry)) == NULL) ||
		(our_entry != NULL && (entries[1] = index_entry_dup(our_entry)) == NULL) ||
		(their_entry != NULL && (entries[2] = index_entry_dup(their_entry)) == NULL))
		return -1;

	for (i = 0; i < 3; i++) {
		if (entries[i] == NULL)
			continue;

		/* Make sure stage is correct */
		entries[i]->flags = (entries[i]->flags & ~GIT_IDXENTRY_STAGEMASK) |
			((i+1) << GIT_IDXENTRY_STAGESHIFT);

		if ((ret = index_insert(index, entries[i], 1)) < 0)
			goto on_error;
	}

	return 0;

on_error:
	for (i = 0; i < 3; i++) {
		if (entries[i] != NULL)
			index_entry_free(entries[i]);
	}

	return ret;
}

static int index_conflict__get_byindex(
	const git_index_entry **ancestor_out,
	const git_index_entry **our_out,
	const git_index_entry **their_out,
	git_index *index,
	size_t n)
{
	const git_index_entry *conflict_entry;
	const char *path = NULL;
	size_t count;
	int stage, len = 0;

	assert(ancestor_out && our_out && their_out && index);

	*ancestor_out = NULL;
	*our_out = NULL;
	*their_out = NULL;

	for (count = git_index_entrycount(index); n < count; ++n) {
		conflict_entry = git_vector_get(&index->entries, n);

		if (path && index->entries_cmp_path(conflict_entry->path, path) != 0)
			break;

		stage = GIT_IDXENTRY_STAGE(conflict_entry);
		path = conflict_entry->path;

		switch (stage) {
		case 3:
			*their_out = conflict_entry;
			len++;
			break;
		case 2:
			*our_out = conflict_entry;
			len++;
			break;
		case 1:
			*ancestor_out = conflict_entry;
			len++;
			break;
		default:
			break;
		};
	}

	return len;
}

int git_index_conflict_get(
	const git_index_entry **ancestor_out,
	const git_index_entry **our_out,
	const git_index_entry **their_out,
	git_index *index,
	const char *path)
{
	size_t pos;
	int len = 0;

	assert(ancestor_out && our_out && their_out && index && path);

	*ancestor_out = NULL;
	*our_out = NULL;
	*their_out = NULL;

	if (git_index_find(&pos, index, path) < 0)
		return GIT_ENOTFOUND;

	if ((len = index_conflict__get_byindex(
		ancestor_out, our_out, their_out, index, pos)) < 0)
		return len;
	else if (len == 0)
		return GIT_ENOTFOUND;

	return 0;
}

int git_index_conflict_remove(git_index *index, const char *path)
{
	size_t pos, posmax;
	git_index_entry *conflict_entry;
	int error = 0;

	assert(index && path);

	if (git_index_find(&pos, index, path) < 0)
		return GIT_ENOTFOUND;

	posmax = git_index_entrycount(index);

	while (pos < posmax) {
		conflict_entry = git_vector_get(&index->entries, pos);

		if (index->entries_cmp_path(conflict_entry->path, path) != 0)
			break;

		if (GIT_IDXENTRY_STAGE(conflict_entry) == 0) {
			pos++;
			continue;
		}

		if ((error = git_vector_remove(&index->entries, pos)) < 0)
			return error;

		index_entry_free(conflict_entry);
		posmax--;
	}

	return 0;
}

static int index_conflicts_match(const git_vector *v, size_t idx)
{
	git_index_entry *entry = git_vector_get(v, idx);

	if (GIT_IDXENTRY_STAGE(entry) > 0) {
		index_entry_free(entry);
		return 1;
	}

	return 0;
}

void git_index_conflict_cleanup(git_index *index)
{
	assert(index);
	git_vector_remove_matching(&index->entries, index_conflicts_match);
}

int git_index_has_conflicts(const git_index *index)
{
	size_t i;
	git_index_entry *entry;

	assert(index);

	git_vector_foreach(&index->entries, i, entry) {
		if (GIT_IDXENTRY_STAGE(entry) > 0)
			return 1;
	}

	return 0;
}

int git_index_conflict_iterator_new(
	git_index_conflict_iterator **iterator_out,
	git_index *index)
{
	git_index_conflict_iterator *it = NULL;

	assert(iterator_out && index);

	it = git__calloc(1, sizeof(git_index_conflict_iterator));
	GITERR_CHECK_ALLOC(it);

	it->index = index;

	*iterator_out = it;
	return 0;
}

int git_index_conflict_next(
	const git_index_entry **ancestor_out,
	const git_index_entry **our_out,
	const git_index_entry **their_out,
	git_index_conflict_iterator *iterator)
{
	const git_index_entry *entry;
	int len;

	assert(ancestor_out && our_out && their_out && iterator);

	*ancestor_out = NULL;
	*our_out = NULL;
	*their_out = NULL;

	while (iterator->cur < iterator->index->entries.length) {
		entry = git_index_get_byindex(iterator->index, iterator->cur);

		if (git_index_entry_stage(entry) > 0) {
			if ((len = index_conflict__get_byindex(
				ancestor_out,
				our_out,
				their_out,
				iterator->index,
				iterator->cur)) < 0)
				return len;

			iterator->cur += len;
			return 0;
		}

		iterator->cur++;
	}

	return GIT_ITEROVER;
}

void git_index_conflict_iterator_free(git_index_conflict_iterator *iterator)
{
	if (iterator == NULL)
		return;

	git__free(iterator);
}

unsigned int git_index_name_entrycount(git_index *index)
{
	assert(index);
	return (unsigned int)index->names.length;
}

const git_index_name_entry *git_index_name_get_byindex(
	git_index *index, size_t n)
{
	assert(index);

	git_vector_sort(&index->names);
	return git_vector_get(&index->names, n);
}

int git_index_name_add(git_index *index,
	const char *ancestor, const char *ours, const char *theirs)
{
	git_index_name_entry *conflict_name;

	assert ((ancestor && ours) || (ancestor && theirs) || (ours && theirs));

	conflict_name = git__calloc(1, sizeof(git_index_name_entry));
	GITERR_CHECK_ALLOC(conflict_name);

	if (ancestor) {
		conflict_name->ancestor = git__strdup(ancestor);
		GITERR_CHECK_ALLOC(conflict_name->ancestor);
	}

	if (ours) {
		conflict_name->ours = git__strdup(ours);
		GITERR_CHECK_ALLOC(conflict_name->ours);
	}

	if (theirs) {
		conflict_name->theirs = git__strdup(theirs);
		GITERR_CHECK_ALLOC(conflict_name->theirs);
	}

	return git_vector_insert(&index->names, conflict_name);
}

void git_index_name_clear(git_index *index)
{
	size_t i;
	git_index_name_entry *conflict_name;

	assert(index);

	git_vector_foreach(&index->names, i, conflict_name) {
		if (conflict_name->ancestor)
			git__free(conflict_name->ancestor);

		if (conflict_name->ours)
			git__free(conflict_name->ours);

		if (conflict_name->theirs)
			git__free(conflict_name->theirs);

		git__free(conflict_name);
	}

	git_vector_clear(&index->names);
}

unsigned int git_index_reuc_entrycount(git_index *index)
{
	assert(index);
	return (unsigned int)index->reuc.length;
}

static int index_reuc_insert(
	git_index *index,
	git_index_reuc_entry *reuc,
	int replace)
{
	git_index_reuc_entry **existing = NULL;
	size_t position;

	assert(index && reuc && reuc->path != NULL);

	if (!git_index_reuc_find(&position, index, reuc->path))
		existing = (git_index_reuc_entry **)&index->reuc.contents[position];

	if (!replace || !existing)
		return git_vector_insert(&index->reuc, reuc);

	/* exists, replace it */
	git__free((*existing)->path);
	git__free(*existing);
	*existing = reuc;

	return 0;
}

int git_index_reuc_add(git_index *index, const char *path,
	int ancestor_mode, const git_oid *ancestor_oid,
	int our_mode, const git_oid *our_oid,
	int their_mode, const git_oid *their_oid)
{
	git_index_reuc_entry *reuc = NULL;
	int error = 0;

	assert(index && path);

	if ((error = index_entry_reuc_init(&reuc, path, ancestor_mode, ancestor_oid, our_mode, our_oid, their_mode, their_oid)) < 0 ||
		(error = index_reuc_insert(index, reuc, 1)) < 0)
	{
		index_entry_reuc_free(reuc);
		return error;
	}

	return error;
} 

int git_index_reuc_find(size_t *at_pos, git_index *index, const char *path)
{
	return git_vector_bsearch2(at_pos, &index->reuc, index->reuc_search, path);
}

const git_index_reuc_entry *git_index_reuc_get_bypath(
	git_index *index, const char *path)
{
	size_t pos;
	assert(index && path);

	if (!index->reuc.length)
		return NULL;

	git_vector_sort(&index->reuc);

	if (git_index_reuc_find(&pos, index, path) < 0)
		return NULL;

	return git_vector_get(&index->reuc, pos);
}

const git_index_reuc_entry *git_index_reuc_get_byindex(
	git_index *index, size_t n)
{
	assert(index);

	git_vector_sort(&index->reuc);
	return git_vector_get(&index->reuc, n);
}

int git_index_reuc_remove(git_index *index, size_t position)
{
	int error;
	git_index_reuc_entry *reuc;

	git_vector_sort(&index->reuc);

	reuc = git_vector_get(&index->reuc, position);
	error = git_vector_remove(&index->reuc, position);

	if (!error)
		index_entry_reuc_free(reuc);

	return error;
}

void git_index_reuc_clear(git_index *index)
{
	size_t i;

	assert(index);

	for (i = 0; i < index->reuc.length; ++i)
		index_entry_reuc_free(git__swap(index->reuc.contents[i], NULL));

	git_vector_clear(&index->reuc);
}

static int index_error_invalid(const char *message)
{
	giterr_set(GITERR_INDEX, "Invalid data in index - %s", message);
	return -1;
}

static int read_reuc(git_index *index, const char *buffer, size_t size)
{
	const char *endptr;
	size_t len;
	int i;

	/* If called multiple times, the vector might already be initialized */
	if (index->reuc._alloc_size == 0 &&
		git_vector_init(&index->reuc, 16, reuc_cmp) < 0)
		return -1;

	while (size) {
		git_index_reuc_entry *lost;

		len = p_strnlen(buffer, size) + 1;
		if (size <= len)
			return index_error_invalid("reading reuc entries");

		lost = git__calloc(1, sizeof(git_index_reuc_entry));
		GITERR_CHECK_ALLOC(lost);

		/* read NUL-terminated pathname for entry */
		lost->path = git__strdup(buffer);
		GITERR_CHECK_ALLOC(lost->path);

		size -= len;
		buffer += len;

		/* read 3 ASCII octal numbers for stage entries */
		for (i = 0; i < 3; i++) {
			int tmp;

			if (git__strtol32(&tmp, buffer, &endptr, 8) < 0 ||
				!endptr || endptr == buffer || *endptr ||
				(unsigned)tmp > UINT_MAX) {
				index_entry_reuc_free(lost);
				return index_error_invalid("reading reuc entry stage");
			}

			lost->mode[i] = tmp;

			len = (endptr + 1) - buffer;
			if (size <= len) {
				index_entry_reuc_free(lost);
				return index_error_invalid("reading reuc entry stage");
			}

			size -= len;
			buffer += len;
		}

		/* read up to 3 OIDs for stage entries */
		for (i = 0; i < 3; i++) {
			if (!lost->mode[i])
				continue;
			if (size < 20) {
				index_entry_reuc_free(lost);
				return index_error_invalid("reading reuc entry oid");
			}

			git_oid_fromraw(&lost->oid[i], (const unsigned char *) buffer);
			size -= 20;
			buffer += 20;
		}

		/* entry was read successfully - insert into reuc vector */
		if (git_vector_insert(&index->reuc, lost) < 0)
			return -1;
	}

	/* entries are guaranteed to be sorted on-disk */
	git_vector_set_sorted(&index->reuc, true);

	return 0;
}


static int read_conflict_names(git_index *index, const char *buffer, size_t size)
{
	size_t len;

	/* This gets called multiple times, the vector might already be initialized */
	if (index->names._alloc_size == 0 &&
		git_vector_init(&index->names, 16, conflict_name_cmp) < 0)
		return -1;

#define read_conflict_name(ptr) \
	len = p_strnlen(buffer, size) + 1; \
	if (size < len) \
		return index_error_invalid("reading conflict name entries"); \
	\
	if (len == 1) \
		ptr = NULL; \
	else { \
		ptr = git__malloc(len); \
		GITERR_CHECK_ALLOC(ptr); \
		memcpy(ptr, buffer, len); \
	} \
	\
	buffer += len; \
	size -= len;

	while (size) {
		git_index_name_entry *conflict_name = git__calloc(1, sizeof(git_index_name_entry));
		GITERR_CHECK_ALLOC(conflict_name);

		read_conflict_name(conflict_name->ancestor);
		read_conflict_name(conflict_name->ours);
		read_conflict_name(conflict_name->theirs);

		if (git_vector_insert(&index->names, conflict_name) < 0)
			return -1;
	}

#undef read_conflict_name

	/* entries are guaranteed to be sorted on-disk */
	git_vector_set_sorted(&index->names, true);

	return 0;
}

static size_t read_entry(git_index_entry *dest, const void *buffer, size_t buffer_size)
{
	size_t path_length, entry_size;
	uint16_t flags_raw;
	const char *path_ptr;
	const struct entry_short *source = buffer;

	if (INDEX_FOOTER_SIZE + minimal_entry_size > buffer_size)
		return 0;

	memset(dest, 0x0, sizeof(git_index_entry));

	dest->ctime.seconds = (git_time_t)ntohl(source->ctime.seconds);
	dest->ctime.nanoseconds = ntohl(source->ctime.nanoseconds);
	dest->mtime.seconds = (git_time_t)ntohl(source->mtime.seconds);
	dest->mtime.nanoseconds = ntohl(source->mtime.nanoseconds);
	dest->dev = ntohl(source->dev);
	dest->ino = ntohl(source->ino);
	dest->mode = ntohl(source->mode);
	dest->uid = ntohl(source->uid);
	dest->gid = ntohl(source->gid);
	dest->file_size = ntohl(source->file_size);
	git_oid_cpy(&dest->id, &source->oid);
	dest->flags = ntohs(source->flags);

	if (dest->flags & GIT_IDXENTRY_EXTENDED) {
		const struct entry_long *source_l = (const struct entry_long *)source;
		path_ptr = source_l->path;

		flags_raw = ntohs(source_l->flags_extended);
		memcpy(&dest->flags_extended, &flags_raw, 2);
	} else
		path_ptr = source->path;

	path_length = dest->flags & GIT_IDXENTRY_NAMEMASK;

	/* if this is a very long string, we must find its
	 * real length without overflowing */
	if (path_length == 0xFFF) {
		const char *path_end;

		path_end = memchr(path_ptr, '\0', buffer_size);
		if (path_end == NULL)
			return 0;

		path_length = path_end - path_ptr;
	}

	if (dest->flags & GIT_IDXENTRY_EXTENDED)
		entry_size = long_entry_size(path_length);
	else
		entry_size = short_entry_size(path_length);

	if (INDEX_FOOTER_SIZE + entry_size > buffer_size)
		return 0;

	dest->path = git__strdup(path_ptr);
	assert(dest->path);

	return entry_size;
}

static int read_header(struct index_header *dest, const void *buffer)
{
	const struct index_header *source = buffer;

	dest->signature = ntohl(source->signature);
	if (dest->signature != INDEX_HEADER_SIG)
		return index_error_invalid("incorrect header signature");

	dest->version = ntohl(source->version);
	if (dest->version != INDEX_VERSION_NUMBER_EXT &&
		dest->version != INDEX_VERSION_NUMBER)
		return index_error_invalid("incorrect header version");

	dest->entry_count = ntohl(source->entry_count);
	return 0;
}

static size_t read_extension(git_index *index, const char *buffer, size_t buffer_size)
{
	const struct index_extension *source;
	struct index_extension dest;
	size_t total_size;

	source = (const struct index_extension *)(buffer);

	memcpy(dest.signature, source->signature, 4);
	dest.extension_size = ntohl(source->extension_size);

	total_size = dest.extension_size + sizeof(struct index_extension);

	if (dest.extension_size > total_size ||
		buffer_size < total_size ||
		buffer_size - total_size < INDEX_FOOTER_SIZE)
		return 0;

	/* optional extension */
	if (dest.signature[0] >= 'A' && dest.signature[0] <= 'Z') {
		/* tree cache */
		if (memcmp(dest.signature, INDEX_EXT_TREECACHE_SIG, 4) == 0) {
			if (git_tree_cache_read(&index->tree, buffer + 8, dest.extension_size) < 0)
				return 0;
		} else if (memcmp(dest.signature, INDEX_EXT_UNMERGED_SIG, 4) == 0) {
			if (read_reuc(index, buffer + 8, dest.extension_size) < 0)
				return 0;
		} else if (memcmp(dest.signature, INDEX_EXT_CONFLICT_NAME_SIG, 4) == 0) {
			if (read_conflict_names(index, buffer + 8, dest.extension_size) < 0)
				return 0;
		}
		/* else, unsupported extension. We cannot parse this, but we can skip
		 * it by returning `total_size */
	} else {
		/* we cannot handle non-ignorable extensions;
		 * in fact they aren't even defined in the standard */
		return 0;
	}

	return total_size;
}

static int parse_index(git_index *index, const char *buffer, size_t buffer_size)
{
	unsigned int i;
	struct index_header header = { 0 };
	git_oid checksum_calculated, checksum_expected;

#define seek_forward(_increase) { \
	if (_increase >= buffer_size) \
		return index_error_invalid("ran out of data while parsing"); \
	buffer += _increase; \
	buffer_size -= _increase;\
}

	if (buffer_size < INDEX_HEADER_SIZE + INDEX_FOOTER_SIZE)
		return index_error_invalid("insufficient buffer space");

	/* Precalculate the SHA1 of the files's contents -- we'll match it to
	 * the provided SHA1 in the footer */
	git_hash_buf(&checksum_calculated, buffer, buffer_size - INDEX_FOOTER_SIZE);

	/* Parse header */
	if (read_header(&header, buffer) < 0)
		return -1;

	seek_forward(INDEX_HEADER_SIZE);

	git_vector_clear(&index->entries);

	/* Parse all the entries */
	for (i = 0; i < header.entry_count && buffer_size > INDEX_FOOTER_SIZE; ++i) {
		size_t entry_size;
		git_index_entry *entry;

		entry = git__malloc(sizeof(git_index_entry));
		GITERR_CHECK_ALLOC(entry);

		entry_size = read_entry(entry, buffer, buffer_size);

		/* 0 bytes read means an object corruption */
		if (entry_size == 0)
			return index_error_invalid("invalid entry");

		if (git_vector_insert(&index->entries, entry) < 0)
			return -1;

		seek_forward(entry_size);
	}

	if (i != header.entry_count)
		return index_error_invalid("header entries changed while parsing");

	/* There's still space for some extensions! */
	while (buffer_size > INDEX_FOOTER_SIZE) {
		size_t extension_size;

		extension_size = read_extension(index, buffer, buffer_size);

		/* see if we have read any bytes from the extension */
		if (extension_size == 0)
			return index_error_invalid("extension is truncated");

		seek_forward(extension_size);
	}

	if (buffer_size != INDEX_FOOTER_SIZE)
		return index_error_invalid("buffer size does not match index footer size");

	/* 160-bit SHA-1 over the content of the index file before this checksum. */
	git_oid_fromraw(&checksum_expected, (const unsigned char *)buffer);

	if (git_oid__cmp(&checksum_calculated, &checksum_expected) != 0)
		return index_error_invalid("calculated checksum does not match expected");

#undef seek_forward

	/* Entries are stored case-sensitively on disk, so re-sort now if
	 * in-memory index is supposed to be case-insensitive
	 */
	git_vector_set_sorted(&index->entries, !index->ignore_case);
	git_vector_sort(&index->entries);

	return 0;
}

static bool is_index_extended(git_index *index)
{
	size_t i, extended;
	git_index_entry *entry;

	extended = 0;

	git_vector_foreach(&index->entries, i, entry) {
		entry->flags &= ~GIT_IDXENTRY_EXTENDED;
		if (entry->flags_extended & GIT_IDXENTRY_EXTENDED_FLAGS) {
			extended++;
			entry->flags |= GIT_IDXENTRY_EXTENDED;
		}
	}

	return (extended > 0);
}

static int write_disk_entry(git_filebuf *file, git_index_entry *entry)
{
	void *mem = NULL;
	struct entry_short *ondisk;
	size_t path_len, disk_size;
	char *path;

	path_len = strlen(entry->path);

	if (entry->flags & GIT_IDXENTRY_EXTENDED)
		disk_size = long_entry_size(path_len);
	else
		disk_size = short_entry_size(path_len);

	if (git_filebuf_reserve(file, &mem, disk_size) < 0)
		return -1;

	ondisk = (struct entry_short *)mem;

	memset(ondisk, 0x0, disk_size);

	/**
	 * Yes, we have to truncate.
	 *
	 * The on-disk format for Index entries clearly defines
	 * the time and size fields to be 4 bytes each -- so even if
	 * we store these values with 8 bytes on-memory, they must
	 * be truncated to 4 bytes before writing to disk.
	 *
	 * In 2038 I will be either too dead or too rich to care about this
	 */
	ondisk->ctime.seconds = htonl((uint32_t)entry->ctime.seconds);
	ondisk->mtime.seconds = htonl((uint32_t)entry->mtime.seconds);
	ondisk->ctime.nanoseconds = htonl(entry->ctime.nanoseconds);
	ondisk->mtime.nanoseconds = htonl(entry->mtime.nanoseconds);
	ondisk->dev = htonl(entry->dev);
	ondisk->ino = htonl(entry->ino);
	ondisk->mode = htonl(entry->mode);
	ondisk->uid = htonl(entry->uid);
	ondisk->gid = htonl(entry->gid);
	ondisk->file_size = htonl((uint32_t)entry->file_size);

	git_oid_cpy(&ondisk->oid, &entry->id);

	ondisk->flags = htons(entry->flags);

	if (entry->flags & GIT_IDXENTRY_EXTENDED) {
		struct entry_long *ondisk_ext;
		ondisk_ext = (struct entry_long *)ondisk;
		ondisk_ext->flags_extended = htons(entry->flags_extended);
		path = ondisk_ext->path;
	}
	else
		path = ondisk->path;

	memcpy(path, entry->path, path_len);

	return 0;
}

static int write_entries(git_index *index, git_filebuf *file)
{
	int error = 0;
	size_t i;
	git_vector case_sorted;
	git_index_entry *entry;
	git_vector *out = &index->entries;

	/* If index->entries is sorted case-insensitively, then we need
	 * to re-sort it case-sensitively before writing */
	if (index->ignore_case) {
		git_vector_dup(&case_sorted, &index->entries, index_cmp);
		git_vector_sort(&case_sorted);
		out = &case_sorted;
	}

	git_vector_foreach(out, i, entry)
		if ((error = write_disk_entry(file, entry)) < 0)
			break;

	if (index->ignore_case)
		git_vector_free(&case_sorted);

	return error;
}

static int write_extension(git_filebuf *file, struct index_extension *header, git_buf *data)
{
	struct index_extension ondisk;
	int error = 0;

	memset(&ondisk, 0x0, sizeof(struct index_extension));
	memcpy(&ondisk, header, 4);
	ondisk.extension_size = htonl(header->extension_size);

	if ((error = git_filebuf_write(file, &ondisk, sizeof(struct index_extension))) == 0)
		error = git_filebuf_write(file, data->ptr, data->size);

	return error;
}

static int create_name_extension_data(git_buf *name_buf, git_index_name_entry *conflict_name)
{
	int error = 0;

	if (conflict_name->ancestor == NULL)
		error = git_buf_put(name_buf, "\0", 1);
	else
		error = git_buf_put(name_buf, conflict_name->ancestor, strlen(conflict_name->ancestor) + 1);

	if (error != 0)
		goto on_error;

	if (conflict_name->ours == NULL)
		error = git_buf_put(name_buf, "\0", 1);
	else
		error = git_buf_put(name_buf, conflict_name->ours, strlen(conflict_name->ours) + 1);

	if (error != 0)
		goto on_error;

	if (conflict_name->theirs == NULL)
		error = git_buf_put(name_buf, "\0", 1);
	else
		error = git_buf_put(name_buf, conflict_name->theirs, strlen(conflict_name->theirs) + 1);

on_error:
	return error;
}

static int write_name_extension(git_index *index, git_filebuf *file)
{
	git_buf name_buf = GIT_BUF_INIT;
	git_vector *out = &index->names;
	git_index_name_entry *conflict_name;
	struct index_extension extension;
	size_t i;
	int error = 0;

	git_vector_foreach(out, i, conflict_name) {
		if ((error = create_name_extension_data(&name_buf, conflict_name)) < 0)
			goto done;
	}

	memset(&extension, 0x0, sizeof(struct index_extension));
	memcpy(&extension.signature, INDEX_EXT_CONFLICT_NAME_SIG, 4);
	extension.extension_size = (uint32_t)name_buf.size;

	error = write_extension(file, &extension, &name_buf);

	git_buf_free(&name_buf);

done:
	return error;
}

static int create_reuc_extension_data(git_buf *reuc_buf, git_index_reuc_entry *reuc)
{
	int i;
	int error = 0;

	if ((error = git_buf_put(reuc_buf, reuc->path, strlen(reuc->path) + 1)) < 0)
		return error;

	for (i = 0; i < 3; i++) {
		if ((error = git_buf_printf(reuc_buf, "%o", reuc->mode[i])) < 0 ||
			(error = git_buf_put(reuc_buf, "\0", 1)) < 0)
			return error;
	}

	for (i = 0; i < 3; i++) {
		if (reuc->mode[i] && (error = git_buf_put(reuc_buf, (char *)&reuc->oid[i].id, GIT_OID_RAWSZ)) < 0)
			return error;
	}

	return 0;
}

static int write_reuc_extension(git_index *index, git_filebuf *file)
{
	git_buf reuc_buf = GIT_BUF_INIT;
	git_vector *out = &index->reuc;
	git_index_reuc_entry *reuc;
	struct index_extension extension;
	size_t i;
	int error = 0;

	git_vector_foreach(out, i, reuc) {
		if ((error = create_reuc_extension_data(&reuc_buf, reuc)) < 0)
			goto done;
	}

	memset(&extension, 0x0, sizeof(struct index_extension));
	memcpy(&extension.signature, INDEX_EXT_UNMERGED_SIG, 4);
	extension.extension_size = (uint32_t)reuc_buf.size;

	error = write_extension(file, &extension, &reuc_buf);

	git_buf_free(&reuc_buf);

done:
	return error;
}

static int write_index(git_index *index, git_filebuf *file)
{
	git_oid hash_final;
	struct index_header header;
	bool is_extended;
	uint32_t index_version_number;

	assert(index && file);

	is_extended = is_index_extended(index);
	index_version_number = is_extended ? INDEX_VERSION_NUMBER_EXT : INDEX_VERSION_NUMBER;

	header.signature = htonl(INDEX_HEADER_SIG);
	header.version = htonl(index_version_number);
	header.entry_count = htonl((uint32_t)index->entries.length);

	if (git_filebuf_write(file, &header, sizeof(struct index_header)) < 0)
		return -1;

	if (write_entries(index, file) < 0)
		return -1;

	/* TODO: write tree cache extension */

	/* write the rename conflict extension */
	if (index->names.length > 0 && write_name_extension(index, file) < 0)
		return -1;

	/* write the reuc extension */
	if (index->reuc.length > 0 && write_reuc_extension(index, file) < 0)
		return -1;

	/* get out the hash for all the contents we've appended to the file */
	git_filebuf_hash(&hash_final, file);

	/* write it at the end of the file */
	return git_filebuf_write(file, hash_final.id, GIT_OID_RAWSZ);
}

int git_index_entry_stage(const git_index_entry *entry)
{
	return GIT_IDXENTRY_STAGE(entry);
}

typedef struct read_tree_data {
	git_vector *old_entries;
	git_vector *new_entries;
	git_vector_cmp entries_search;
} read_tree_data;

static int read_tree_cb(
	const char *root, const git_tree_entry *tentry, void *payload)
{
	read_tree_data *data = payload;
	git_index_entry *entry = NULL, *old_entry;
	git_buf path = GIT_BUF_INIT;

	if (git_tree_entry__is_tree(tentry))
		return 0;

	if (git_buf_joinpath(&path, root, tentry->filename) < 0)
		return -1;

	entry = git__calloc(1, sizeof(git_index_entry));
	GITERR_CHECK_ALLOC(entry);

	entry->mode = tentry->attr;
	entry->id = tentry->oid;

	/* look for corresponding old entry and copy data to new entry */
	if (data->old_entries) {
		size_t pos;
		struct entry_srch_key skey;

		skey.path = path.ptr;
		skey.path_len = strlen(path.ptr);
		skey.stage = 0;

		if (!git_vector_bsearch2(
				&pos, data->old_entries, data->entries_search, &skey) &&
			(old_entry = git_vector_get(data->old_entries, pos)) != NULL &&
			entry->mode == old_entry->mode &&
			git_oid_equal(&entry->id, &old_entry->id))
		{
			memcpy(entry, old_entry, sizeof(*entry));
			entry->flags_extended = 0;
		}
	}

	if (path.size < GIT_IDXENTRY_NAMEMASK)
		entry->flags = path.size & GIT_IDXENTRY_NAMEMASK;
	else
		entry->flags = GIT_IDXENTRY_NAMEMASK;

	entry->path = git_buf_detach(&path);
	git_buf_free(&path);

	if (git_vector_insert(data->new_entries, entry) < 0) {
		index_entry_free(entry);
		return -1;
	}

	return 0;
}

int git_index_read_tree(git_index *index, const git_tree *tree)
{
	int error = 0;
	git_vector entries = GIT_VECTOR_INIT;
	read_tree_data data;

	git_vector_set_cmp(&entries, index->entries._cmp); /* match sort */

	data.old_entries = &index->entries;
	data.new_entries = &entries;
	data.entries_search = index->entries_search;

	git_vector_sort(&index->entries);

	error = git_tree_walk(tree, GIT_TREEWALK_POST, read_tree_cb, &data);

	if (!error) {
		git_vector_sort(&entries);
		git_index_clear(index);
		git_vector_swap(&entries, &index->entries);
	}

	git_vector_free(&entries);

	return error;
}

git_repository *git_index_owner(const git_index *index)
{
	return INDEX_OWNER(index);
}

int git_index_add_all(
	git_index *index,
	const git_strarray *paths,
	unsigned int flags,
	git_index_matched_path_cb cb,
	void *payload)
{
	int error;
	git_repository *repo;
	git_iterator *wditer = NULL;
	const git_index_entry *wd = NULL;
	git_index_entry *entry;
	git_pathspec ps;
	const char *match;
	size_t existing;
	bool no_fnmatch = (flags & GIT_INDEX_ADD_DISABLE_PATHSPEC_MATCH) != 0;
	int ignorecase;
	git_oid blobid;

	assert(index);

	if (INDEX_OWNER(index) == NULL)
		return create_index_error(-1,
			"Could not add paths to index. "
			"Index is not backed up by an existing repository.");

	repo = INDEX_OWNER(index);
	if ((error = git_repository__ensure_not_bare(repo, "index add all")) < 0)
		return error;

	if (git_repository__cvar(&ignorecase, repo, GIT_CVAR_IGNORECASE) < 0)
		return -1;

	if ((error = git_pathspec__init(&ps, paths)) < 0)
		return error;

	/* optionally check that pathspec doesn't mention any ignored files */
	if ((flags & GIT_INDEX_ADD_CHECK_PATHSPEC) != 0 &&
		(flags & GIT_INDEX_ADD_FORCE) == 0 &&
		(error = git_ignore__check_pathspec_for_exact_ignores(
			repo, &ps.pathspec, no_fnmatch)) < 0)
		goto cleanup;

	if ((error = git_iterator_for_workdir(
			&wditer, repo, 0, ps.prefix, ps.prefix)) < 0)
		goto cleanup;

	while (!(error = git_iterator_advance(&wd, wditer))) {

		/* check if path actually matches */
		if (!git_pathspec__match(
				&ps.pathspec, wd->path, no_fnmatch, (bool)ignorecase, &match, NULL))
			continue;

		/* skip ignored items that are not already in the index */
		if ((flags & GIT_INDEX_ADD_FORCE) == 0 &&
			git_iterator_current_is_ignored(wditer) &&
			git_index__find(&existing, index, wd->path, 0, 0) < 0)
			continue;

		/* issue notification callback if requested */
		if (cb && (error = cb(wd->path, match, payload)) != 0) {
			if (error > 0) /* return > 0 means skip this one */
				continue;
			if (error < 0) { /* return < 0 means abort */
				giterr_set_after_callback(error);
				break;
			}
		}

		/* TODO: Should we check if the file on disk is already an exact
		 * match to the file in the index and skip this work if it is?
		 */

		/* write the blob to disk and get the oid */
		if ((error = git_blob_create_fromworkdir(&blobid, repo, wd->path)) < 0)
			break;

		/* make the new entry to insert */
		if ((entry = index_entry_dup(wd)) == NULL) {
			error = -1;
			break;
		}
		entry->id = blobid;

		/* add working directory item to index */
		if ((error = index_insert(index, entry, 1)) < 0) {
			index_entry_free(entry);
			break;
		}

		git_tree_cache_invalidate_path(index->tree, wd->path);

		/* add implies conflict resolved, move conflict entries to REUC */
		if ((error = index_conflict_to_reuc(index, wd->path)) < 0) {
			if (error != GIT_ENOTFOUND)
				break;
			giterr_clear();
		}
	}

	if (error == GIT_ITEROVER)
		error = 0;

cleanup:
	git_iterator_free(wditer);
	git_pathspec__clear(&ps);

	return error;
}

enum {
	INDEX_ACTION_NONE = 0,
	INDEX_ACTION_UPDATE = 1,
	INDEX_ACTION_REMOVE = 2,
};

static int index_apply_to_all(
	git_index *index,
	int action,
	const git_strarray *paths,
	git_index_matched_path_cb cb,
	void *payload)
{
	int error = 0;
	size_t i;
	git_pathspec ps;
	const char *match;
	git_buf path = GIT_BUF_INIT;

	assert(index);

	if ((error = git_pathspec__init(&ps, paths)) < 0)
		return error;

	git_vector_sort(&index->entries);

	for (i = 0; !error && i < index->entries.length; ++i) {
		git_index_entry *entry = git_vector_get(&index->entries, i);

		/* check if path actually matches */
		if (!git_pathspec__match(
				&ps.pathspec, entry->path, false, (bool)index->ignore_case,
				&match, NULL))
			continue;

		/* issue notification callback if requested */
		if (cb && (error = cb(entry->path, match, payload)) != 0) {
			if (error > 0) { /* return > 0 means skip this one */
				error = 0;
				continue;
			}
			if (error < 0)   /* return < 0 means abort */
				break;
		}

		/* index manipulation may alter entry, so don't depend on it */
		if ((error = git_buf_sets(&path, entry->path)) < 0)
			break;

		switch (action) {
		case INDEX_ACTION_NONE:
			break;
		case INDEX_ACTION_UPDATE:
			error = git_index_add_bypath(index, path.ptr);

			if (error == GIT_ENOTFOUND) {
				giterr_clear();

				error = git_index_remove_bypath(index, path.ptr);

				if (!error) /* back up foreach if we removed this */
					i--;
			}
			break;
		case INDEX_ACTION_REMOVE:
			if (!(error = git_index_remove_bypath(index, path.ptr)))
				i--; /* back up foreach if we removed this */
			break;
		default:
			giterr_set(GITERR_INVALID, "Unknown index action %d", action);
			error = -1;
			break;
		}
	}

	git_buf_free(&path);
	git_pathspec__clear(&ps);

	return error;
}

int git_index_remove_all(
	git_index *index,
	const git_strarray *pathspec,
	git_index_matched_path_cb cb,
	void *payload)
{
	int error = index_apply_to_all(
		index, INDEX_ACTION_REMOVE, pathspec, cb, payload);

	if (error) /* make sure error is set if callback stopped iteration */
		giterr_set_after_callback(error);

	return error;
}

int git_index_update_all(
	git_index *index,
	const git_strarray *pathspec,
	git_index_matched_path_cb cb,
	void *payload)
{
	int error = index_apply_to_all(
		index, INDEX_ACTION_UPDATE, pathspec, cb, payload);

	if (error) /* make sure error is set if callback stopped iteration */
		giterr_set_after_callback(error);

	return error;
}
