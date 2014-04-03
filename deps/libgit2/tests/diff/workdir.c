#include "clar_libgit2.h"
#include "diff_helpers.h"
#include "repository.h"

static git_repository *g_repo = NULL;

void test_diff_workdir__initialize(void)
{
}

void test_diff_workdir__cleanup(void)
{
	cl_git_sandbox_cleanup();
}

void test_diff_workdir__to_index(void)
{
	git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
	git_diff *diff = NULL;
	diff_expects exp;
	int use_iterator;

	g_repo = cl_git_sandbox_init("status");

	opts.context_lines = 3;
	opts.interhunk_lines = 1;
	opts.flags |= GIT_DIFF_INCLUDE_IGNORED | GIT_DIFF_INCLUDE_UNTRACKED;

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	for (use_iterator = 0; use_iterator <= 1; use_iterator++) {
		memset(&exp, 0, sizeof(exp));

		if (use_iterator)
			cl_git_pass(diff_foreach_via_iterator(
				diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));
		else
			cl_git_pass(git_diff_foreach(
				diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

		/* to generate these values:
		 * - cd to tests/resources/status,
		 * - mv .gitted .git
		 * - git diff --name-status
		 * - git diff
		 * - mv .git .gitted
		 */
		cl_assert_equal_i(13, exp.files);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
		cl_assert_equal_i(4, exp.file_status[GIT_DELTA_DELETED]);
		cl_assert_equal_i(4, exp.file_status[GIT_DELTA_MODIFIED]);
		cl_assert_equal_i(1, exp.file_status[GIT_DELTA_IGNORED]);
		cl_assert_equal_i(4, exp.file_status[GIT_DELTA_UNTRACKED]);

		cl_assert_equal_i(8, exp.hunks);

		cl_assert_equal_i(14, exp.lines);
		cl_assert_equal_i(5, exp.line_ctxt);
		cl_assert_equal_i(4, exp.line_adds);
		cl_assert_equal_i(5, exp.line_dels);
	}

	git_diff_free(diff);
}

void test_diff_workdir__to_index_with_assume_unchanged(void)
{
	git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
	git_diff *diff = NULL;
	git_index *idx = NULL;
	diff_expects exp;
	const git_index_entry *iep;
	git_index_entry ie;

	g_repo = cl_git_sandbox_init("status");

	/* do initial diff */

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));
	memset(&exp, 0, sizeof(exp));
	cl_git_pass(git_diff_foreach(
		diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));
	cl_assert_equal_i(8, exp.files);
	cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
	cl_assert_equal_i(4, exp.file_status[GIT_DELTA_DELETED]);
	cl_assert_equal_i(4, exp.file_status[GIT_DELTA_MODIFIED]);
	git_diff_free(diff);

	/* mark a couple of entries with ASSUME_UNCHANGED */

	cl_git_pass(git_repository_index(&idx, g_repo));

	cl_assert((iep = git_index_get_bypath(idx, "modified_file", 0)) != NULL);
	memcpy(&ie, iep, sizeof(ie));
	ie.flags |= GIT_IDXENTRY_VALID;
	cl_git_pass(git_index_add(idx, &ie));

	cl_assert((iep = git_index_get_bypath(idx, "file_deleted", 0)) != NULL);
	memcpy(&ie, iep, sizeof(ie));
	ie.flags |= GIT_IDXENTRY_VALID;
	cl_git_pass(git_index_add(idx, &ie));

	cl_git_pass(git_index_write(idx));
	git_index_free(idx);

	/* redo diff and see that entries are skipped */

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));
	memset(&exp, 0, sizeof(exp));
	cl_git_pass(git_diff_foreach(
		diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));
	cl_assert_equal_i(6, exp.files);
	cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
	cl_assert_equal_i(3, exp.file_status[GIT_DELTA_DELETED]);
	cl_assert_equal_i(3, exp.file_status[GIT_DELTA_MODIFIED]);
	git_diff_free(diff);

}

void test_diff_workdir__to_tree(void)
{
	/* grabbed a couple of commit oids from the history of the attr repo */
	const char *a_commit = "26a125ee1bf"; /* the current HEAD */
	const char *b_commit = "0017bd4ab1ec3"; /* the start */
	git_tree *a, *b;
	git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
	git_diff *diff = NULL;
	git_diff *diff2 = NULL;
	diff_expects exp;
	int use_iterator;

	g_repo = cl_git_sandbox_init("status");

	a = resolve_commit_oid_to_tree(g_repo, a_commit);
	b = resolve_commit_oid_to_tree(g_repo, b_commit);

	opts.context_lines = 3;
	opts.interhunk_lines = 1;
	opts.flags |= GIT_DIFF_INCLUDE_IGNORED | GIT_DIFF_INCLUDE_UNTRACKED;

	/* You can't really generate the equivalent of git_diff_tree_to_workdir()
	 * using C git.  It really wants to interpose the index into the diff.
	 *
	 * To validate the following results with command line git, I ran the
	 * following:
	 * - git ls-tree 26a125
	 * - find . ! -path ./.git/\* -a -type f | git hash-object --stdin-paths
	 * The results are documented at the bottom of this file in the
	 * long comment entitled "PREPARATION OF TEST DATA".
	 */
	cl_git_pass(git_diff_tree_to_workdir(&diff, g_repo, a, &opts));

	for (use_iterator = 0; use_iterator <= 1; use_iterator++) {
		memset(&exp, 0, sizeof(exp));

		if (use_iterator)
			cl_git_pass(diff_foreach_via_iterator(
				diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));
		else
			cl_git_pass(git_diff_foreach(
				diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

		cl_assert_equal_i(14, exp.files);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
		cl_assert_equal_i(4, exp.file_status[GIT_DELTA_DELETED]);
		cl_assert_equal_i(4, exp.file_status[GIT_DELTA_MODIFIED]);
		cl_assert_equal_i(1, exp.file_status[GIT_DELTA_IGNORED]);
		cl_assert_equal_i(5, exp.file_status[GIT_DELTA_UNTRACKED]);
	}

	/* Since there is no git diff equivalent, let's just assume that the
	 * text diffs produced by git_diff_foreach are accurate here.  We will
	 * do more apples-to-apples test comparison below.
	 */

	git_diff_free(diff);
	diff = NULL;
	memset(&exp, 0, sizeof(exp));

	/* This is a compatible emulation of "git diff <sha>" which looks like
	 * a workdir to tree diff (even though it is not really).  This is what
	 * you would get from "git diff --name-status 26a125ee1bf"
	 */
	cl_git_pass(git_diff_tree_to_index(&diff, g_repo, a, NULL, &opts));
	cl_git_pass(git_diff_index_to_workdir(&diff2, g_repo, NULL, &opts));
	cl_git_pass(git_diff_merge(diff, diff2));
	git_diff_free(diff2);

	for (use_iterator = 0; use_iterator <= 1; use_iterator++) {
		memset(&exp, 0, sizeof(exp));

		if (use_iterator)
			cl_git_pass(diff_foreach_via_iterator(
				diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));
		else
			cl_git_pass(git_diff_foreach(
				diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

		cl_assert_equal_i(15, exp.files);
		cl_assert_equal_i(2, exp.file_status[GIT_DELTA_ADDED]);
		cl_assert_equal_i(5, exp.file_status[GIT_DELTA_DELETED]);
		cl_assert_equal_i(4, exp.file_status[GIT_DELTA_MODIFIED]);
		cl_assert_equal_i(1, exp.file_status[GIT_DELTA_IGNORED]);
		cl_assert_equal_i(3, exp.file_status[GIT_DELTA_UNTRACKED]);

		cl_assert_equal_i(11, exp.hunks);

		cl_assert_equal_i(17, exp.lines);
		cl_assert_equal_i(4, exp.line_ctxt);
		cl_assert_equal_i(8, exp.line_adds);
		cl_assert_equal_i(5, exp.line_dels);
	}

	git_diff_free(diff);
	diff = NULL;
	memset(&exp, 0, sizeof(exp));

	/* Again, emulating "git diff <sha>" for testing purposes using
	 * "git diff --name-status 0017bd4ab1ec3" instead.
	 */
	cl_git_pass(git_diff_tree_to_index(&diff, g_repo, b, NULL, &opts));
	cl_git_pass(git_diff_index_to_workdir(&diff2, g_repo, NULL, &opts));
	cl_git_pass(git_diff_merge(diff, diff2));
	git_diff_free(diff2);

	for (use_iterator = 0; use_iterator <= 1; use_iterator++) {
		memset(&exp, 0, sizeof(exp));

		if (use_iterator)
			cl_git_pass(diff_foreach_via_iterator(
				diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));
		else
			cl_git_pass(git_diff_foreach(
				diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

		cl_assert_equal_i(16, exp.files);
		cl_assert_equal_i(5, exp.file_status[GIT_DELTA_ADDED]);
		cl_assert_equal_i(4, exp.file_status[GIT_DELTA_DELETED]);
		cl_assert_equal_i(3, exp.file_status[GIT_DELTA_MODIFIED]);
		cl_assert_equal_i(1, exp.file_status[GIT_DELTA_IGNORED]);
		cl_assert_equal_i(3, exp.file_status[GIT_DELTA_UNTRACKED]);

		cl_assert_equal_i(12, exp.hunks);

		cl_assert_equal_i(19, exp.lines);
		cl_assert_equal_i(3, exp.line_ctxt);
		cl_assert_equal_i(12, exp.line_adds);
		cl_assert_equal_i(4, exp.line_dels);
	}

	git_diff_free(diff);

	/* Let's try that once more with a reversed diff */

	opts.flags |= GIT_DIFF_REVERSE;

	cl_git_pass(git_diff_tree_to_index(&diff, g_repo, b, NULL, &opts));
	cl_git_pass(git_diff_index_to_workdir(&diff2, g_repo, NULL, &opts));
	cl_git_pass(git_diff_merge(diff, diff2));
	git_diff_free(diff2);

	memset(&exp, 0, sizeof(exp));

	cl_git_pass(git_diff_foreach(
		diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

	cl_assert_equal_i(16, exp.files);
	cl_assert_equal_i(5, exp.file_status[GIT_DELTA_DELETED]);
	cl_assert_equal_i(4, exp.file_status[GIT_DELTA_ADDED]);
	cl_assert_equal_i(3, exp.file_status[GIT_DELTA_MODIFIED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_IGNORED]);
	cl_assert_equal_i(3, exp.file_status[GIT_DELTA_UNTRACKED]);

	cl_assert_equal_i(12, exp.hunks);

	cl_assert_equal_i(19, exp.lines);
	cl_assert_equal_i(3, exp.line_ctxt);
	cl_assert_equal_i(12, exp.line_dels);
	cl_assert_equal_i(4, exp.line_adds);

	git_diff_free(diff);

	/* all done now */

	git_tree_free(a);
	git_tree_free(b);
}

void test_diff_workdir__to_index_with_pathspec(void)
{
	git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
	git_diff *diff = NULL;
	diff_expects exp;
	char *pathspec = NULL;
	int use_iterator;

	g_repo = cl_git_sandbox_init("status");

	opts.context_lines = 3;
	opts.interhunk_lines = 1;
	opts.flags |= GIT_DIFF_INCLUDE_IGNORED | GIT_DIFF_INCLUDE_UNTRACKED;
	opts.pathspec.strings = &pathspec;
	opts.pathspec.count   = 1;

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	for (use_iterator = 0; use_iterator <= 1; use_iterator++) {
		memset(&exp, 0, sizeof(exp));

		if (use_iterator)
			cl_git_pass(diff_foreach_via_iterator(
				diff, diff_file_cb, NULL, NULL, &exp));
		else
			cl_git_pass(git_diff_foreach(diff, diff_file_cb, NULL, NULL, &exp));

		cl_assert_equal_i(13, exp.files);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
		cl_assert_equal_i(4, exp.file_status[GIT_DELTA_DELETED]);
		cl_assert_equal_i(4, exp.file_status[GIT_DELTA_MODIFIED]);
		cl_assert_equal_i(1, exp.file_status[GIT_DELTA_IGNORED]);
		cl_assert_equal_i(4, exp.file_status[GIT_DELTA_UNTRACKED]);
	}

	git_diff_free(diff);

	pathspec = "modified_file";

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	for (use_iterator = 0; use_iterator <= 1; use_iterator++) {
		memset(&exp, 0, sizeof(exp));

		if (use_iterator)
			cl_git_pass(diff_foreach_via_iterator(
				diff, diff_file_cb, NULL, NULL, &exp));
		else
			cl_git_pass(git_diff_foreach(diff, diff_file_cb, NULL, NULL, &exp));

		cl_assert_equal_i(1, exp.files);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_DELETED]);
		cl_assert_equal_i(1, exp.file_status[GIT_DELTA_MODIFIED]);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_IGNORED]);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_UNTRACKED]);
	}

	git_diff_free(diff);

	pathspec = "subdir";

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	for (use_iterator = 0; use_iterator <= 1; use_iterator++) {
		memset(&exp, 0, sizeof(exp));

		if (use_iterator)
			cl_git_pass(diff_foreach_via_iterator(
				diff, diff_file_cb, NULL, NULL, &exp));
		else
			cl_git_pass(git_diff_foreach(diff, diff_file_cb, NULL, NULL, &exp));

		cl_assert_equal_i(3, exp.files);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
		cl_assert_equal_i(1, exp.file_status[GIT_DELTA_DELETED]);
		cl_assert_equal_i(1, exp.file_status[GIT_DELTA_MODIFIED]);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_IGNORED]);
		cl_assert_equal_i(1, exp.file_status[GIT_DELTA_UNTRACKED]);
	}

	git_diff_free(diff);

	pathspec = "*_deleted";

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	for (use_iterator = 0; use_iterator <= 1; use_iterator++) {
		memset(&exp, 0, sizeof(exp));

		if (use_iterator)
			cl_git_pass(diff_foreach_via_iterator(
				diff, diff_file_cb, NULL, NULL, &exp));
		else
			cl_git_pass(git_diff_foreach(diff, diff_file_cb, NULL, NULL, &exp));

		cl_assert_equal_i(2, exp.files);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
		cl_assert_equal_i(2, exp.file_status[GIT_DELTA_DELETED]);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_MODIFIED]);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_IGNORED]);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_UNTRACKED]);
	}

	git_diff_free(diff);
}

void test_diff_workdir__filemode_changes(void)
{
	git_diff *diff = NULL;
	diff_expects exp;
	int use_iterator;

	if (!cl_is_chmod_supported())
		return;

	g_repo = cl_git_sandbox_init("issue_592");

	cl_repo_set_bool(g_repo, "core.filemode", true);

	/* test once with no mods */

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, NULL));

	for (use_iterator = 0; use_iterator <= 1; use_iterator++) {
		memset(&exp, 0, sizeof(exp));

		if (use_iterator)
			cl_git_pass(diff_foreach_via_iterator(
				diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));
		else
			cl_git_pass(git_diff_foreach(
				diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

		cl_assert_equal_i(0, exp.files);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_MODIFIED]);
		cl_assert_equal_i(0, exp.hunks);
	}

	git_diff_free(diff);

	/* chmod file and test again */

	cl_assert(cl_toggle_filemode("issue_592/a.txt"));

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, NULL));

	for (use_iterator = 0; use_iterator <= 1; use_iterator++) {
		memset(&exp, 0, sizeof(exp));

		if (use_iterator)
			cl_git_pass(diff_foreach_via_iterator(
				diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));
		else
			cl_git_pass(git_diff_foreach(
				diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

		cl_assert_equal_i(1, exp.files);
		cl_assert_equal_i(1, exp.file_status[GIT_DELTA_MODIFIED]);
		cl_assert_equal_i(0, exp.hunks);
	}

	git_diff_free(diff);

	cl_assert(cl_toggle_filemode("issue_592/a.txt"));
}

void test_diff_workdir__filemode_changes_with_filemode_false(void)
{
	git_diff *diff = NULL;
	diff_expects exp;

	if (!cl_is_chmod_supported())
		return;

	g_repo = cl_git_sandbox_init("issue_592");

	cl_repo_set_bool(g_repo, "core.filemode", false);

	/* test once with no mods */

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, NULL));

	memset(&exp, 0, sizeof(exp));
	cl_git_pass(git_diff_foreach(
		diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

	cl_assert_equal_i(0, exp.files);
	cl_assert_equal_i(0, exp.file_status[GIT_DELTA_MODIFIED]);
	cl_assert_equal_i(0, exp.hunks);

	git_diff_free(diff);

	/* chmod file and test again */

	cl_assert(cl_toggle_filemode("issue_592/a.txt"));

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, NULL));

	memset(&exp, 0, sizeof(exp));
	cl_git_pass(git_diff_foreach(
		diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

	cl_assert_equal_i(0, exp.files);
	cl_assert_equal_i(0, exp.file_status[GIT_DELTA_MODIFIED]);
	cl_assert_equal_i(0, exp.hunks);

	git_diff_free(diff);

	cl_assert(cl_toggle_filemode("issue_592/a.txt"));
}

void test_diff_workdir__head_index_and_workdir_all_differ(void)
{
	git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
	git_diff *diff_i2t = NULL, *diff_w2i = NULL;
	diff_expects exp;
	char *pathspec = "staged_changes_modified_file";
	git_tree *tree;
	int use_iterator;

	/* For this file,
	 * - head->index diff has 1 line of context, 1 line of diff
	 * - index->workdir diff has 2 lines of context, 1 line of diff
	 * but
	 * - head->workdir diff has 1 line of context, 2 lines of diff
	 * Let's make sure the right one is returned from each fn.
	 */

	g_repo = cl_git_sandbox_init("status");

	tree = resolve_commit_oid_to_tree(g_repo, "26a125ee1bfc5df1e1b2e9441bbe63c8a7ae989f");

	opts.pathspec.strings = &pathspec;
	opts.pathspec.count   = 1;

	cl_git_pass(git_diff_tree_to_index(&diff_i2t, g_repo, tree, NULL, &opts));
	cl_git_pass(git_diff_index_to_workdir(&diff_w2i, g_repo, NULL, &opts));

	for (use_iterator = 0; use_iterator <= 1; use_iterator++) {
		memset(&exp, 0, sizeof(exp));

		if (use_iterator)
			cl_git_pass(diff_foreach_via_iterator(
				diff_i2t, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));
		else
			cl_git_pass(git_diff_foreach(
				diff_i2t, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

		cl_assert_equal_i(1, exp.files);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_DELETED]);
		cl_assert_equal_i(1, exp.file_status[GIT_DELTA_MODIFIED]);
		cl_assert_equal_i(1, exp.hunks);
		cl_assert_equal_i(2, exp.lines);
		cl_assert_equal_i(1, exp.line_ctxt);
		cl_assert_equal_i(1, exp.line_adds);
		cl_assert_equal_i(0, exp.line_dels);
	}

	for (use_iterator = 0; use_iterator <= 1; use_iterator++) {
		memset(&exp, 0, sizeof(exp));

		if (use_iterator)
			cl_git_pass(diff_foreach_via_iterator(
				diff_w2i, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));
		else
			cl_git_pass(git_diff_foreach(
				diff_w2i, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

		cl_assert_equal_i(1, exp.files);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_DELETED]);
		cl_assert_equal_i(1, exp.file_status[GIT_DELTA_MODIFIED]);
		cl_assert_equal_i(1, exp.hunks);
		cl_assert_equal_i(3, exp.lines);
		cl_assert_equal_i(2, exp.line_ctxt);
		cl_assert_equal_i(1, exp.line_adds);
		cl_assert_equal_i(0, exp.line_dels);
	}

	cl_git_pass(git_diff_merge(diff_i2t, diff_w2i));

	for (use_iterator = 0; use_iterator <= 1; use_iterator++) {
		memset(&exp, 0, sizeof(exp));

		if (use_iterator)
			cl_git_pass(diff_foreach_via_iterator(
				diff_i2t, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));
		else
			cl_git_pass(git_diff_foreach(
				diff_i2t, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

		cl_assert_equal_i(1, exp.files);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_DELETED]);
		cl_assert_equal_i(1, exp.file_status[GIT_DELTA_MODIFIED]);
		cl_assert_equal_i(1, exp.hunks);
		cl_assert_equal_i(3, exp.lines);
		cl_assert_equal_i(1, exp.line_ctxt);
		cl_assert_equal_i(2, exp.line_adds);
		cl_assert_equal_i(0, exp.line_dels);
	}

	git_diff_free(diff_i2t);
	git_diff_free(diff_w2i);

	git_tree_free(tree);
}

void test_diff_workdir__eof_newline_changes(void)
{
	git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
	git_diff *diff = NULL;
	diff_expects exp;
	char *pathspec = "current_file";
	int use_iterator;

	g_repo = cl_git_sandbox_init("status");

	opts.pathspec.strings = &pathspec;
	opts.pathspec.count   = 1;

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	for (use_iterator = 0; use_iterator <= 1; use_iterator++) {
		memset(&exp, 0, sizeof(exp));

		if (use_iterator)
			cl_git_pass(diff_foreach_via_iterator(
				diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));
		else
			cl_git_pass(git_diff_foreach(
				diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

		cl_assert_equal_i(0, exp.files);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_DELETED]);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_MODIFIED]);
		cl_assert_equal_i(0, exp.hunks);
		cl_assert_equal_i(0, exp.lines);
		cl_assert_equal_i(0, exp.line_ctxt);
		cl_assert_equal_i(0, exp.line_adds);
		cl_assert_equal_i(0, exp.line_dels);
	}

	git_diff_free(diff);

	cl_git_append2file("status/current_file", "\n");

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	for (use_iterator = 0; use_iterator <= 1; use_iterator++) {
		memset(&exp, 0, sizeof(exp));

		if (use_iterator)
			cl_git_pass(diff_foreach_via_iterator(
				diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));
		else
			cl_git_pass(git_diff_foreach(
				diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

		cl_assert_equal_i(1, exp.files);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_DELETED]);
		cl_assert_equal_i(1, exp.file_status[GIT_DELTA_MODIFIED]);
		cl_assert_equal_i(1, exp.hunks);
		cl_assert_equal_i(2, exp.lines);
		cl_assert_equal_i(1, exp.line_ctxt);
		cl_assert_equal_i(1, exp.line_adds);
		cl_assert_equal_i(0, exp.line_dels);
	}

	git_diff_free(diff);

	cl_git_rewritefile("status/current_file", "current_file");

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	for (use_iterator = 0; use_iterator <= 1; use_iterator++) {
		memset(&exp, 0, sizeof(exp));

		if (use_iterator)
			cl_git_pass(diff_foreach_via_iterator(
				diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));
		else
			cl_git_pass(git_diff_foreach(
				diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

		cl_assert_equal_i(1, exp.files);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
		cl_assert_equal_i(0, exp.file_status[GIT_DELTA_DELETED]);
		cl_assert_equal_i(1, exp.file_status[GIT_DELTA_MODIFIED]);
		cl_assert_equal_i(1, exp.hunks);
		cl_assert_equal_i(3, exp.lines);
		cl_assert_equal_i(0, exp.line_ctxt);
		cl_assert_equal_i(1, exp.line_adds);
		cl_assert_equal_i(2, exp.line_dels);
	}

	git_diff_free(diff);
}

/* PREPARATION OF TEST DATA
 *
 * Since there is no command line equivalent of git_diff_tree_to_workdir,
 * it was a bit of a pain to confirm that I was getting the expected
 * results in the first part of this tests.  Here is what I ended up
 * doing to set my expectation for the file counts and results:
 *
 * Running "git ls-tree 26a125" and "git ls-tree aa27a6" shows:
 *
 *  A a0de7e0ac200c489c41c59dfa910154a70264e6e	current_file
 *  B 5452d32f1dd538eb0405e8a83cc185f79e25e80f	file_deleted
 *  C 452e4244b5d083ddf0460acf1ecc74db9dcfa11a	modified_file
 *  D 32504b727382542f9f089e24fddac5e78533e96c	staged_changes
 *  E 061d42a44cacde5726057b67558821d95db96f19	staged_changes_file_deleted
 *  F 70bd9443ada07063e7fbf0b3ff5c13f7494d89c2	staged_changes_modified_file
 *  G e9b9107f290627c04d097733a10055af941f6bca	staged_delete_file_deleted
 *  H dabc8af9bd6e9f5bbe96a176f1a24baf3d1f8916	staged_delete_modified_file
 *  I 53ace0d1cc1145a5f4fe4f78a186a60263190733	subdir/current_file
 *  J 1888c805345ba265b0ee9449b8877b6064592058	subdir/deleted_file
 *  K a6191982709b746d5650e93c2acf34ef74e11504	subdir/modified_file
 *  L e8ee89e15bbe9b20137715232387b3de5b28972e	subdir.txt
 *
 * --------
 *
 * find . ! -path ./.git/\* -a -type f | git hash-object --stdin-paths
 *
 *  A a0de7e0ac200c489c41c59dfa910154a70264e6e current_file
 *  M 6a79f808a9c6bc9531ac726c184bbcd9351ccf11 ignored_file
 *  C 0a539630525aca2e7bc84975958f92f10a64c9b6 modified_file
 *  N d4fa8600b4f37d7516bef4816ae2c64dbf029e3a new_file
 *  D 55d316c9ba708999f1918e9677d01dfcae69c6b9 staged_changes
 *  F 011c3440d5c596e21d836aa6d7b10eb581f68c49 staged_changes_modified_file
 *  H dabc8af9bd6e9f5bbe96a176f1a24baf3d1f8916 staged_delete_modified_file
 *  O 529a16e8e762d4acb7b9636ff540a00831f9155a staged_new_file
 *  P 8b090c06d14ffa09c4e880088ebad33893f921d1 staged_new_file_modified_file
 *  I 53ace0d1cc1145a5f4fe4f78a186a60263190733 subdir/current_file
 *  K 57274b75eeb5f36fd55527806d567b2240a20c57 subdir/modified_file
 *  Q 80a86a6931b91bc01c2dbf5ca55bdd24ad1ef466 subdir/new_file
 *  L e8ee89e15bbe9b20137715232387b3de5b28972e subdir.txt
 *
 * --------
 *
 *  A - current_file (UNMODIFIED) -> not in results
 *  B D file_deleted
 *  M I ignored_file (IGNORED)
 *  C M modified_file
 *  N U new_file (UNTRACKED)
 *  D M staged_changes
 *  E D staged_changes_file_deleted
 *  F M staged_changes_modified_file
 *  G D staged_delete_file_deleted
 *  H - staged_delete_modified_file (UNMODIFIED) -> not in results
 *  O U staged_new_file
 *  P U staged_new_file_modified_file
 *  I - subdir/current_file (UNMODIFIED) -> not in results
 *  J D subdir/deleted_file
 *  K M subdir/modified_file
 *  Q U subdir/new_file
 *  L - subdir.txt (UNMODIFIED) -> not in results
 *
 * Expect 13 files, 0 ADD, 4 DEL, 4 MOD, 1 IGN, 4 UNTR
 */


void test_diff_workdir__larger_hunks(void)
{
	const char *a_commit = "d70d245ed97ed2aa596dd1af6536e4bfdb047b69";
	const char *b_commit = "7a9e0b02e63179929fed24f0a3e0f19168114d10";
	git_tree *a, *b;
	git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
	size_t i, d, num_d, h, num_h, l, num_l;

	g_repo = cl_git_sandbox_init("diff");

	cl_assert((a = resolve_commit_oid_to_tree(g_repo, a_commit)) != NULL);
	cl_assert((b = resolve_commit_oid_to_tree(g_repo, b_commit)) != NULL);

	opts.context_lines = 1;
	opts.interhunk_lines = 0;

	for (i = 0; i <= 2; ++i) {
		git_diff *diff = NULL;
		git_patch *patch;
		const git_diff_hunk *hunk;
		const git_diff_line *line;

		/* okay, this is a bit silly, but oh well */
		switch (i) {
		case 0:
			cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));
			break;
		case 1:
			cl_git_pass(git_diff_tree_to_workdir(&diff, g_repo, a, &opts));
			break;
		case 2:
			cl_git_pass(git_diff_tree_to_workdir(&diff, g_repo, b, &opts));
			break;
		}

		num_d = git_diff_num_deltas(diff);
		cl_assert_equal_i(2, (int)num_d);

		for (d = 0; d < num_d; ++d) {
			cl_git_pass(git_patch_from_diff(&patch, diff, d));
			cl_assert(patch);

			num_h = git_patch_num_hunks(patch);
			for (h = 0; h < num_h; h++) {
				cl_git_pass(git_patch_get_hunk(&hunk, &num_l, patch, h));

				for (l = 0; l < num_l; ++l) {
					cl_git_pass(
						git_patch_get_line_in_hunk(&line, patch, h, l));
					cl_assert(line);
				}

				/* confirm fail after the last item */
				cl_git_fail(
					git_patch_get_line_in_hunk(&line, patch, h, num_l));
			}

			/* confirm fail after the last item */
			cl_git_fail(git_patch_get_hunk(&hunk, &num_l, patch, num_h));

			git_patch_free(patch);
		}

		git_diff_free(diff);
	}

	git_tree_free(a);
	git_tree_free(b);
}

/* Set up a test that exercises this code. The easiest test using existing
 * test data is probably to create a sandbox of submod2 and then run a
 * git_diff_tree_to_workdir against tree
 * 873585b94bdeabccea991ea5e3ec1a277895b698. As for what you should actually
 * test, you can start by just checking that the number of lines of diff
 * content matches the actual output of git diff. That will at least
 * demonstrate that the submodule content is being used to generate somewhat
 * comparable outputs. It is a test that would fail without this code and
 * will succeed with it.
 */

#include "../submodule/submodule_helpers.h"

void test_diff_workdir__submodules(void)
{
	const char *a_commit = "873585b94bdeabccea991ea5e3ec1a277895b698";
	git_tree *a;
	git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
	git_diff *diff = NULL;
	diff_expects exp;

	g_repo = setup_fixture_submod2();

	a = resolve_commit_oid_to_tree(g_repo, a_commit);

	opts.flags =
		GIT_DIFF_INCLUDE_UNTRACKED |
		GIT_DIFF_INCLUDE_IGNORED |
		GIT_DIFF_RECURSE_UNTRACKED_DIRS |
		GIT_DIFF_SHOW_UNTRACKED_CONTENT;

	cl_git_pass(git_diff_tree_to_workdir(&diff, g_repo, a, &opts));

	/* diff_print(stderr, diff); */

	/* essentially doing: git diff 873585b94bdeabccea991ea5e3ec1a277895b698 */

	memset(&exp, 0, sizeof(exp));

	cl_git_pass(git_diff_foreach(
		diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

	/* so "git diff 873585" returns:
	 *  M   .gitmodules
	 *  A   just_a_dir/contents
	 *  A   just_a_file
	 *  A   sm_added_and_uncommited
	 *  A   sm_changed_file
	 *  A   sm_changed_head
	 *  A   sm_changed_index
	 *  A   sm_changed_untracked_file
	 *  M   sm_missing_commits
	 *  A   sm_unchanged
	 * which is a little deceptive because of the difference between the
	 * "git diff <treeish>" results from "git_diff_tree_to_workdir".  The
	 * only significant difference is that those Added items will show up
	 * as Untracked items in the pure libgit2 diff.
	 *
	 * Then add in the two extra untracked items "not" and "not-submodule"
	 * to get the 12 files reported here.
	 */

	cl_assert_equal_i(12, exp.files);

	cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
	cl_assert_equal_i(0, exp.file_status[GIT_DELTA_DELETED]);
	cl_assert_equal_i(2, exp.file_status[GIT_DELTA_MODIFIED]);
	cl_assert_equal_i(0, exp.file_status[GIT_DELTA_IGNORED]);
	cl_assert_equal_i(10, exp.file_status[GIT_DELTA_UNTRACKED]);

	/* the following numbers match "git diff 873585" exactly */

	cl_assert_equal_i(9, exp.hunks);

	cl_assert_equal_i(33, exp.lines);
	cl_assert_equal_i(2, exp.line_ctxt);
	cl_assert_equal_i(30, exp.line_adds);
	cl_assert_equal_i(1, exp.line_dels);

	git_diff_free(diff);
	git_tree_free(a);
}

void test_diff_workdir__cannot_diff_against_a_bare_repository(void)
{
	git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
	git_diff *diff = NULL;
	git_tree *tree;

	g_repo = cl_git_sandbox_init("testrepo.git");

	cl_assert_equal_i(
		GIT_EBAREREPO, git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	cl_git_pass(git_repository_head_tree(&tree, g_repo));

	cl_assert_equal_i(
		GIT_EBAREREPO, git_diff_tree_to_workdir(&diff, g_repo, tree, &opts));

	git_tree_free(tree);
}

void test_diff_workdir__to_null_tree(void)
{
	git_diff *diff;
	diff_expects exp;
	git_diff_options opts = GIT_DIFF_OPTIONS_INIT;

	opts.flags = GIT_DIFF_INCLUDE_UNTRACKED |
		GIT_DIFF_RECURSE_UNTRACKED_DIRS;

	g_repo = cl_git_sandbox_init("status");

	cl_git_pass(git_diff_tree_to_workdir(&diff, g_repo, NULL, &opts));

	memset(&exp, 0, sizeof(exp));

	cl_git_pass(git_diff_foreach(
		diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

	cl_assert_equal_i(exp.files, exp.file_status[GIT_DELTA_UNTRACKED]);

	git_diff_free(diff);
}

void test_diff_workdir__checks_options_version(void)
{
	git_diff *diff;
	git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
	const git_error *err;

	g_repo = cl_git_sandbox_init("status");

	opts.version = 0;
	cl_git_fail(git_diff_tree_to_workdir(&diff, g_repo, NULL, &opts));
	err = giterr_last();
	cl_assert_equal_i(GITERR_INVALID, err->klass);

	giterr_clear();
	opts.version = 1024;
	cl_git_fail(git_diff_tree_to_workdir(&diff, g_repo, NULL, &opts));
	err = giterr_last();
	cl_assert_equal_i(GITERR_INVALID, err->klass);
}

void test_diff_workdir__can_diff_empty_file(void)
{
	git_diff *diff;
	git_tree *tree;
	git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
	struct stat st;
	git_patch *patch;

	g_repo = cl_git_sandbox_init("attr_index");

	tree = resolve_commit_oid_to_tree(g_repo, "3812cfef3661"); /* HEAD */

	/* baseline - make sure there are no outstanding diffs */

	cl_git_pass(git_diff_tree_to_workdir(&diff, g_repo, tree, &opts));
	cl_assert_equal_i(2, (int)git_diff_num_deltas(diff));
	git_diff_free(diff);

	/* empty contents of file */

	cl_git_rewritefile("attr_index/README.txt", "");
	cl_git_pass(git_path_lstat("attr_index/README.txt", &st));
	cl_assert_equal_i(0, (int)st.st_size);

	cl_git_pass(git_diff_tree_to_workdir(&diff, g_repo, tree, &opts));
	cl_assert_equal_i(3, (int)git_diff_num_deltas(diff));
	/* diffs are: .gitattributes, README.txt, sub/sub/.gitattributes */
	cl_git_pass(git_patch_from_diff(&patch, diff, 1));
	git_patch_free(patch);
	git_diff_free(diff);

	/* remove a file altogether */

	cl_git_pass(p_unlink("attr_index/README.txt"));
	cl_assert(!git_path_exists("attr_index/README.txt"));

	cl_git_pass(git_diff_tree_to_workdir(&diff, g_repo, tree, &opts));
	cl_assert_equal_i(3, (int)git_diff_num_deltas(diff));
	cl_git_pass(git_patch_from_diff(&patch, diff, 1));
	git_patch_free(patch);
	git_diff_free(diff);

	git_tree_free(tree);
}

void test_diff_workdir__to_index_issue_1397(void)
{
	git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
	git_diff *diff = NULL;
	diff_expects exp;

	g_repo = cl_git_sandbox_init("issue_1397");

	cl_repo_set_bool(g_repo, "core.autocrlf", true);

	opts.context_lines = 3;
	opts.interhunk_lines = 1;

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	memset(&exp, 0, sizeof(exp));
	cl_git_pass(git_diff_foreach(
		diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

	cl_assert_equal_i(0, exp.files);
	cl_assert_equal_i(0, exp.hunks);
	cl_assert_equal_i(0, exp.lines);

	git_diff_free(diff);
	diff = NULL;

	cl_git_rewritefile("issue_1397/crlf_file.txt",
		"first line\r\nsecond line modified\r\nboth with crlf");

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	memset(&exp, 0, sizeof(exp));
	cl_git_pass(git_diff_foreach(
		diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

	cl_assert_equal_i(1, exp.files);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_MODIFIED]);

	cl_assert_equal_i(1, exp.hunks);

	cl_assert_equal_i(5, exp.lines);
	cl_assert_equal_i(3, exp.line_ctxt);
	cl_assert_equal_i(1, exp.line_adds);
	cl_assert_equal_i(1, exp.line_dels);

	git_diff_free(diff);
}

void test_diff_workdir__to_tree_issue_1397(void)
{
	const char *a_commit = "7f483a738"; /* the current HEAD */
	git_tree *a;
	git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
	git_diff *diff = NULL;
	git_diff *diff2 = NULL;
	diff_expects exp;

	g_repo = cl_git_sandbox_init("issue_1397");

	cl_repo_set_bool(g_repo, "core.autocrlf", true);

	a = resolve_commit_oid_to_tree(g_repo, a_commit);

	opts.context_lines = 3;
	opts.interhunk_lines = 1;

	cl_git_pass(git_diff_tree_to_workdir(&diff, g_repo, a, &opts));

	memset(&exp, 0, sizeof(exp));
	cl_git_pass(git_diff_foreach(
		diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

	cl_assert_equal_i(0, exp.files);
	cl_assert_equal_i(0, exp.hunks);
	cl_assert_equal_i(0, exp.lines);

	git_diff_free(diff);
	diff = NULL;

	cl_git_pass(git_diff_tree_to_index(&diff, g_repo, a, NULL, &opts));
	cl_git_pass(git_diff_index_to_workdir(&diff2, g_repo, NULL, &opts));
	cl_git_pass(git_diff_merge(diff, diff2));
	git_diff_free(diff2);

	memset(&exp, 0, sizeof(exp));
	cl_git_pass(git_diff_foreach(
		diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

	cl_assert_equal_i(0, exp.files);
	cl_assert_equal_i(0, exp.hunks);
	cl_assert_equal_i(0, exp.lines);

	git_diff_free(diff);
	git_tree_free(a);
}

void test_diff_workdir__untracked_directory_scenarios(void)
{
	git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
	git_diff *diff = NULL;
	diff_expects exp;
	char *pathspec = NULL;
	static const char *files0[] = {
		"subdir/deleted_file",
		"subdir/modified_file",
		"subdir/new_file",
		NULL
	};
	static const char *files1[] = {
		"subdir/deleted_file",
		"subdir/directory/",
		"subdir/modified_file",
		"subdir/new_file",
		NULL
	};
	static const char *files2[] = {
		"subdir/deleted_file",
		"subdir/directory/more/notignored",
		"subdir/modified_file",
		"subdir/new_file",
		NULL
	};

	g_repo = cl_git_sandbox_init("status");
	cl_git_mkfile("status/.gitignore", "ignored\n");

	opts.context_lines = 3;
	opts.interhunk_lines = 1;
	opts.flags |= GIT_DIFF_INCLUDE_IGNORED | GIT_DIFF_INCLUDE_UNTRACKED;
	opts.pathspec.strings = &pathspec;
	opts.pathspec.count   = 1;
	pathspec = "subdir";

	/* baseline for "subdir" pathspec */

	memset(&exp, 0, sizeof(exp));
	exp.names = files0;

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	cl_git_pass(git_diff_foreach(diff, diff_file_cb, NULL, NULL, &exp));

	cl_assert_equal_i(3, exp.files);
	cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_DELETED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_MODIFIED]);
	cl_assert_equal_i(0, exp.file_status[GIT_DELTA_IGNORED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_UNTRACKED]);

	git_diff_free(diff);

	/* empty directory */

	cl_git_pass(p_mkdir("status/subdir/directory", 0777));

	memset(&exp, 0, sizeof(exp));
	exp.names = files1;

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	cl_git_pass(git_diff_foreach(diff, diff_file_cb, NULL, NULL, &exp));

	cl_assert_equal_i(4, exp.files);
	cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_DELETED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_MODIFIED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_IGNORED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_UNTRACKED]);

	git_diff_free(diff);

	/* empty directory in empty directory */

	cl_git_pass(p_mkdir("status/subdir/directory/empty", 0777));

	memset(&exp, 0, sizeof(exp));
	exp.names = files1;

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	cl_git_pass(git_diff_foreach(diff, diff_file_cb, NULL, NULL, &exp));

	cl_assert_equal_i(4, exp.files);
	cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_DELETED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_MODIFIED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_IGNORED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_UNTRACKED]);

	git_diff_free(diff);

	/* directory with only ignored files */

	cl_git_pass(p_mkdir("status/subdir/directory/deeper", 0777));
	cl_git_mkfile("status/subdir/directory/deeper/ignored", "ignore me\n");

	cl_git_pass(p_mkdir("status/subdir/directory/another", 0777));
	cl_git_mkfile("status/subdir/directory/another/ignored", "ignore me\n");

	memset(&exp, 0, sizeof(exp));
	exp.names = files1;

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	cl_git_pass(git_diff_foreach(diff, diff_file_cb, NULL, NULL, &exp));

	cl_assert_equal_i(4, exp.files);
	cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_DELETED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_MODIFIED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_IGNORED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_UNTRACKED]);

	git_diff_free(diff);

	/* directory with ignored directory (contents irrelevant) */

	cl_git_pass(p_mkdir("status/subdir/directory/more", 0777));
	cl_git_pass(p_mkdir("status/subdir/directory/more/ignored", 0777));
	cl_git_mkfile("status/subdir/directory/more/ignored/notignored",
		"inside ignored dir\n");

	memset(&exp, 0, sizeof(exp));
	exp.names = files1;

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	cl_git_pass(git_diff_foreach(diff, diff_file_cb, NULL, NULL, &exp));

	cl_assert_equal_i(4, exp.files);
	cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_DELETED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_MODIFIED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_IGNORED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_UNTRACKED]);

	git_diff_free(diff);

	/* quick version avoids directory scan */

	opts.flags = opts.flags | GIT_DIFF_ENABLE_FAST_UNTRACKED_DIRS;

	memset(&exp, 0, sizeof(exp));
	exp.names = files1;

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	cl_git_pass(git_diff_foreach(diff, diff_file_cb, NULL, NULL, &exp));

	cl_assert_equal_i(4, exp.files);
	cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_DELETED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_MODIFIED]);
	cl_assert_equal_i(0, exp.file_status[GIT_DELTA_IGNORED]);
	cl_assert_equal_i(2, exp.file_status[GIT_DELTA_UNTRACKED]);

	git_diff_free(diff);

	/* directory with nested non-ignored content */

	opts.flags = opts.flags & ~GIT_DIFF_ENABLE_FAST_UNTRACKED_DIRS;

	cl_git_mkfile("status/subdir/directory/more/notignored",
		"not ignored deep under untracked\n");

	memset(&exp, 0, sizeof(exp));
	exp.names = files1;

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	cl_git_pass(git_diff_foreach(diff, diff_file_cb, NULL, NULL, &exp));

	cl_assert_equal_i(4, exp.files);
	cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_DELETED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_MODIFIED]);
	cl_assert_equal_i(0, exp.file_status[GIT_DELTA_IGNORED]);
	cl_assert_equal_i(2, exp.file_status[GIT_DELTA_UNTRACKED]);

	git_diff_free(diff);

	/* use RECURSE_UNTRACKED_DIRS to get actual untracked files (no ignores) */

	opts.flags = opts.flags & ~GIT_DIFF_INCLUDE_IGNORED;
	opts.flags = opts.flags | GIT_DIFF_RECURSE_UNTRACKED_DIRS;

	memset(&exp, 0, sizeof(exp));
	exp.names = files2;

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	cl_git_pass(git_diff_foreach(diff, diff_file_cb, NULL, NULL, &exp));

	cl_assert_equal_i(4, exp.files);
	cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_DELETED]);
	cl_assert_equal_i(1, exp.file_status[GIT_DELTA_MODIFIED]);
	cl_assert_equal_i(0, exp.file_status[GIT_DELTA_IGNORED]);
	cl_assert_equal_i(2, exp.file_status[GIT_DELTA_UNTRACKED]);

	git_diff_free(diff);
}


void test_diff_workdir__untracked_directory_comes_last(void)
{
	git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
	git_diff *diff = NULL;

	g_repo = cl_git_sandbox_init("renames");

	cl_git_mkfile("renames/.gitignore", "*.ign\n");
	cl_git_pass(p_mkdir("renames/zzz_untracked", 0777));
	cl_git_mkfile("renames/zzz_untracked/an.ign", "ignore me please");
	cl_git_mkfile("renames/zzz_untracked/skip.ign", "ignore me really");
	cl_git_mkfile("renames/zzz_untracked/test.ign", "ignore me now");

	opts.context_lines = 3;
	opts.interhunk_lines = 1;
	opts.flags |= GIT_DIFF_INCLUDE_IGNORED | GIT_DIFF_INCLUDE_UNTRACKED;

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	cl_assert(diff != NULL);

	git_diff_free(diff);
}

void test_diff_workdir__untracked_with_bom(void)
{
	git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
	git_diff *diff = NULL;
	const git_diff_delta *delta;

	g_repo = cl_git_sandbox_init("empty_standard_repo");
	cl_repo_set_bool(g_repo, "core.autocrlf", true);

	cl_git_write2file("empty_standard_repo/bom.txt",
		"\xFF\xFE\x31\x00\x32\x00\x33\x00\x34\x00", 10, O_WRONLY|O_CREAT, 0664);

	opts.flags =
		GIT_DIFF_INCLUDE_UNTRACKED | GIT_DIFF_SHOW_UNTRACKED_CONTENT;

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	cl_assert_equal_i(1, git_diff_num_deltas(diff));
	cl_assert((delta = git_diff_get_delta(diff, 0)) != NULL);
	cl_assert_equal_i(GIT_DELTA_UNTRACKED, delta->status);

	/* not known at this point
	 * cl_assert((delta->flags & GIT_DIFF_FLAG_BINARY) != 0);
	 */

	git_diff_free(diff);
}

void test_diff_workdir__patience_diff(void)
{
	git_index *index;
	git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
	git_diff *diff = NULL;
	git_patch *patch = NULL;
	git_buf buf = GIT_BUF_INIT;
	const char *expected_normal = "diff --git a/test.txt b/test.txt\nindex 34a5acc..d52725f 100644\n--- a/test.txt\n+++ b/test.txt\n@@ -1,10 +1,7 @@\n When I wrote this\n I did not know\n-how to create\n-a patience diff\n I did not know\n how to create\n+a patience diff\n another problem\n-I did not know\n-how to create\n a minimal diff\n";
	const char *expected_patience = "diff --git a/test.txt b/test.txt\nindex 34a5acc..d52725f 100644\n--- a/test.txt\n+++ b/test.txt\n@@ -1,10 +1,7 @@\n When I wrote this\n I did not know\n+I did not know\n how to create\n a patience diff\n-I did not know\n-how to create\n another problem\n-I did not know\n-how to create\n a minimal diff\n";

	g_repo = cl_git_sandbox_init("empty_standard_repo");
	cl_repo_set_bool(g_repo, "core.autocrlf", true);
	cl_git_pass(git_repository_index(&index, g_repo));

	cl_git_mkfile(
		"empty_standard_repo/test.txt",
		"When I wrote this\nI did not know\nhow to create\na patience diff\nI did not know\nhow to create\nanother problem\nI did not know\nhow to create\na minimal diff\n");
	cl_git_pass(git_index_add_bypath(index, "test.txt"));
	cl_repo_commit_from_index(NULL, g_repo, NULL, 1372350000, "Base");
	git_index_free(index);

	cl_git_rewritefile(
		"empty_standard_repo/test.txt",
		"When I wrote this\nI did not know\nI did not know\nhow to create\na patience diff\nanother problem\na minimal diff\n");

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));
	cl_assert_equal_i(1, git_diff_num_deltas(diff));
	cl_git_pass(git_patch_from_diff(&patch, diff, 0));
	cl_git_pass(git_patch_to_buf(&buf, patch));

	cl_assert_equal_s(expected_normal, buf.ptr);
	git_buf_clear(&buf);
	git_patch_free(patch);
	git_diff_free(diff);

	opts.flags |= GIT_DIFF_PATIENCE;

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));
	cl_assert_equal_i(1, git_diff_num_deltas(diff));
	cl_git_pass(git_patch_from_diff(&patch, diff, 0));
	cl_git_pass(git_patch_to_buf(&buf, patch));

	cl_assert_equal_s(expected_patience, buf.ptr);
	git_buf_clear(&buf);

	git_buf_free(&buf);
	git_patch_free(patch);
	git_diff_free(diff);
}

void test_diff_workdir__with_stale_index(void)
{
	git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
	git_diff *diff = NULL;
	git_index *idx = NULL;
	diff_expects exp;

	g_repo = cl_git_sandbox_init("status");
	cl_git_pass(git_repository_index(&idx, g_repo));

	/* make the in-memory index invalid */
	{
		git_repository *r2;
		git_index *idx2;
		cl_git_pass(git_repository_open(&r2, "status"));
		cl_git_pass(git_repository_index(&idx2, r2));
		cl_git_pass(git_index_add_bypath(idx2, "new_file"));
		cl_git_pass(git_index_add_bypath(idx2, "subdir/new_file"));
		cl_git_pass(git_index_remove_bypath(idx2, "staged_new_file"));
		cl_git_pass(git_index_remove_bypath(idx2, "staged_changes_file_deleted"));
		cl_git_pass(git_index_write(idx2));
		git_index_free(idx2);
		git_repository_free(r2);
	}

	opts.context_lines = 3;
	opts.interhunk_lines = 1;
	opts.flags |= GIT_DIFF_INCLUDE_UNTRACKED | GIT_DIFF_INCLUDE_UNMODIFIED;

	/* first try with index pointer which should prevent reload */

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, idx, &opts));

	memset(&exp, 0, sizeof(exp));

	cl_git_pass(git_diff_foreach(
		diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

	cl_assert_equal_i(17, exp.files);
	cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
	cl_assert_equal_i(4, exp.file_status[GIT_DELTA_DELETED]);
	cl_assert_equal_i(4, exp.file_status[GIT_DELTA_MODIFIED]);
	cl_assert_equal_i(4, exp.file_status[GIT_DELTA_UNTRACKED]);
	cl_assert_equal_i(5, exp.file_status[GIT_DELTA_UNMODIFIED]);

	git_diff_free(diff);

	/* now let's try without the index pointer which should trigger reload */

	/* two files that were UNTRACKED should have become UNMODIFIED */
	/* one file that was UNMODIFIED should now have become UNTRACKED */
	/* one file that was DELETED should now be gone completely */

	cl_git_pass(git_diff_index_to_workdir(&diff, g_repo, NULL, &opts));

	memset(&exp, 0, sizeof(exp));

	cl_git_pass(git_diff_foreach(
		diff, diff_file_cb, diff_hunk_cb, diff_line_cb, &exp));

	git_diff_free(diff);

	cl_assert_equal_i(16, exp.files);
	cl_assert_equal_i(0, exp.file_status[GIT_DELTA_ADDED]);
	cl_assert_equal_i(3, exp.file_status[GIT_DELTA_DELETED]);
	cl_assert_equal_i(4, exp.file_status[GIT_DELTA_MODIFIED]);
	cl_assert_equal_i(3, exp.file_status[GIT_DELTA_UNTRACKED]);
	cl_assert_equal_i(6, exp.file_status[GIT_DELTA_UNMODIFIED]);

	git_index_free(idx);
}
