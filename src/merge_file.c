/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */

#include "common.h"
#include "repository.h"
#include "merge_file.h"
#include "posix.h"
#include "fileops.h"
#include "index.h"

#include "git2/repository.h"
#include "git2/object.h"
#include "git2/index.h"

#include "xdiff/xdiff.h"

#define GIT_MERGE_FILE_SIDE_EXISTS(X)	((X)->mode != 0)

GIT_INLINE(const char *) merge_file_best_path(
	const git_merge_file_input *ancestor,
	const git_merge_file_input *ours,
	const git_merge_file_input *theirs)
{
	if (!ancestor) {
		if (ours && theirs && strcmp(ours->path, theirs->path) == 0)
			return ours->path;

		return NULL;
	}

	if (ours && strcmp(ancestor->path, ours->path) == 0)
		return theirs ? theirs->path : NULL;
	else if(theirs && strcmp(ancestor->path, theirs->path) == 0)
		return ours ? ours->path : NULL;

	return NULL;
}

GIT_INLINE(int) merge_file_best_mode(
	const git_merge_file_input *ancestor,
	const git_merge_file_input *ours,
	const git_merge_file_input *theirs)
{
	/*
	 * If ancestor didn't exist and either ours or theirs is executable,
	 * assume executable.  Otherwise, if any mode changed from the ancestor,
	 * use that one.
	 */
	if (!ancestor) {
		if ((ours && ours->mode == GIT_FILEMODE_BLOB_EXECUTABLE) ||
			(theirs && theirs->mode == GIT_FILEMODE_BLOB_EXECUTABLE))
			return GIT_FILEMODE_BLOB_EXECUTABLE;

		return GIT_FILEMODE_BLOB;
	} else if (ours && theirs) {
		if (ancestor->mode == ours->mode)
			return theirs->mode;

		return ours->mode;
	}

	return 0;
}

int git_merge_file__input_from_index(
	git_merge_file_input *input_out,
	git_odb_object **odb_object_out,
	git_odb *odb,
	const git_index_entry *entry)
{
	int error = 0;

	assert(input_out && odb_object_out && odb && entry);

	if ((error = git_odb_read(odb_object_out, odb, &entry->id)) < 0)
		goto done;

	input_out->path = entry->path;
	input_out->mode = entry->mode;
	input_out->ptr = (char *)git_odb_object_data(*odb_object_out);
	input_out->size = git_odb_object_size(*odb_object_out);

done:
	return error;
}

static void merge_file_normalize_opts(
	git_merge_file_options *out,
	const git_merge_file_options *given_opts)
{
	if (given_opts)
		memcpy(out, given_opts, sizeof(git_merge_file_options));
	else {
		git_merge_file_options default_opts = GIT_MERGE_FILE_OPTIONS_INIT;
		memcpy(out, &default_opts, sizeof(git_merge_file_options));
	}
}

static int git_merge_file__from_inputs(
	git_merge_file_result *out,
	const git_merge_file_input *ancestor,
	const git_merge_file_input *ours,
	const git_merge_file_input *theirs,
	const git_merge_file_options *given_opts)
{
	xmparam_t xmparam;
	mmfile_t ancestor_mmfile = {0}, our_mmfile = {0}, their_mmfile = {0};
	mmbuffer_t mmbuffer;
	git_merge_file_options options = GIT_MERGE_FILE_OPTIONS_INIT;
	const char *path;
	int xdl_result;
	int error = 0;

	memset(out, 0x0, sizeof(git_merge_file_result));

	merge_file_normalize_opts(&options, given_opts);

	memset(&xmparam, 0x0, sizeof(xmparam_t));

	if (ancestor) {
		xmparam.ancestor = (options.ancestor_label) ?
			options.ancestor_label : ancestor->path;
		ancestor_mmfile.ptr = (char *)ancestor->ptr;
		ancestor_mmfile.size = ancestor->size;
	}

	xmparam.file1 = (options.our_label) ?
		options.our_label : ours->path;
	our_mmfile.ptr = (char *)ours->ptr;
	our_mmfile.size = ours->size;

	xmparam.file2 = (options.their_label) ?
		options.their_label : theirs->path;
	their_mmfile.ptr = (char *)theirs->ptr;
	their_mmfile.size = theirs->size;

	if (options.favor == GIT_MERGE_FILE_FAVOR_OURS)
		xmparam.favor = XDL_MERGE_FAVOR_OURS;
	else if (options.favor == GIT_MERGE_FILE_FAVOR_THEIRS)
		xmparam.favor = XDL_MERGE_FAVOR_THEIRS;
	else if (options.favor == GIT_MERGE_FILE_FAVOR_UNION)
		xmparam.favor = XDL_MERGE_FAVOR_UNION;

	xmparam.level = (options.flags & GIT_MERGE_FILE_SIMPLIFY_ALNUM) ?
		XDL_MERGE_ZEALOUS_ALNUM : XDL_MERGE_ZEALOUS;

	if (options.flags & GIT_MERGE_FILE_STYLE_DIFF3)
		xmparam.style = XDL_MERGE_DIFF3;

	if ((xdl_result = xdl_merge(&ancestor_mmfile, &our_mmfile,
		&their_mmfile, &xmparam, &mmbuffer)) < 0) {
		giterr_set(GITERR_MERGE, "Failed to merge files.");
		error = -1;
		goto done;
	}

	if ((path = merge_file_best_path(ancestor, ours, theirs)) != NULL &&
		(out->path = strdup(path)) == NULL) {
		error = -1;
		goto done;
	}

	out->automergeable = (xdl_result == 0);
	out->ptr = (const char *)mmbuffer.ptr;
	out->len = mmbuffer.size;
	out->mode = merge_file_best_mode(ancestor, ours, theirs);

done:
	if (error < 0)
		git_merge_file_result_free(out);

	return error;
}

static git_merge_file_input *git_merge_file__normalize_inputs(
	git_merge_file_input *out,
	const git_merge_file_input *given)
{
	memcpy(out, given, sizeof(git_merge_file_input));

	if (!out->path)
		out->path = "file.txt";

	if (!out->mode)
		out->mode = 0100644;

	return out;
}

int git_merge_file(
	git_merge_file_result *out,
	const git_merge_file_input *ancestor,
	const git_merge_file_input *ours,
	const git_merge_file_input *theirs,
	const git_merge_file_options *options)
{
	git_merge_file_input inputs[3] = { {0} };

	assert(out && ours && theirs);

	memset(out, 0x0, sizeof(git_merge_file_result));

	if (ancestor)
		ancestor = git_merge_file__normalize_inputs(&inputs[0], ancestor);

	ours = git_merge_file__normalize_inputs(&inputs[1], ours);
	theirs = git_merge_file__normalize_inputs(&inputs[2], theirs);

	return git_merge_file__from_inputs(out, ancestor, ours, theirs, options);
}

int git_merge_file_from_index(
	git_merge_file_result *out,
	git_repository *repo,
	const git_index_entry *ancestor,
	const git_index_entry *ours,
	const git_index_entry *theirs,
	const git_merge_file_options *options)
{
	git_merge_file_input inputs[3] = { {0} },
		*ancestor_input = NULL, *our_input = NULL, *their_input = NULL;
	git_odb *odb = NULL;
	git_odb_object *odb_object[3] = { 0 };
	int error = 0;

	assert(out && repo && ours && theirs);

	memset(out, 0x0, sizeof(git_merge_file_result));

	if ((error = git_repository_odb(&odb, repo)) < 0)
		goto done;

	if (ancestor) {
		if ((error = git_merge_file__input_from_index(
			&inputs[0], &odb_object[0], odb, ancestor)) < 0)
			goto done;

		ancestor_input = &inputs[0];
	}

	if ((error = git_merge_file__input_from_index(
		&inputs[1], &odb_object[1], odb, ours)) < 0)
		goto done;

	our_input = &inputs[1];

	if ((error = git_merge_file__input_from_index(
		&inputs[2], &odb_object[2], odb, theirs)) < 0)
		goto done;

	their_input = &inputs[2];

	if ((error = git_merge_file__from_inputs(out,
		ancestor_input, our_input, their_input, options)) < 0)
		goto done;

done:
	git_odb_object_free(odb_object[0]);
	git_odb_object_free(odb_object[1]);
	git_odb_object_free(odb_object[2]);
	git_odb_free(odb);

	return error;
}

void git_merge_file_result_free(git_merge_file_result *result)
{
	if (result == NULL)
		return;

	git__free((char *)result->path);

	/* xdiff uses malloc() not git_malloc, so we use free(), not git_free() */
	free((char *)result->ptr);
}
