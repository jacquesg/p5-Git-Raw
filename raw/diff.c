#include <raw/diff.h>
#include <raw/util/general.h>

unsigned git_hv_to_diff_flag(HV *flags) {
	unsigned out = 0;

	git_flag_opt(flags, "reverse", GIT_DIFF_REVERSE, &out);

	git_flag_opt(flags, "include_ignored", GIT_DIFF_INCLUDE_IGNORED, &out);

	git_flag_opt(flags, "include_typechange", GIT_DIFF_INCLUDE_TYPECHANGE, &out);

	git_flag_opt(
		flags, "include_typechange_trees",
		GIT_DIFF_INCLUDE_TYPECHANGE_TREES, &out);

	git_flag_opt(
		flags, "recurse_ignored_dirs",
		GIT_DIFF_RECURSE_IGNORED_DIRS, &out
	);

	git_flag_opt(
		flags, "include_untracked",
		GIT_DIFF_INCLUDE_UNTRACKED, &out
	);

	git_flag_opt(
		flags, "recurse_untracked_dirs",
		GIT_DIFF_RECURSE_UNTRACKED_DIRS, &out
	);

	git_flag_opt(flags, "ignore_filemode", GIT_DIFF_IGNORE_FILEMODE, &out);

	git_flag_opt(flags, "ignore_case", GIT_DIFF_IGNORE_CASE, &out);

	git_flag_opt(
		flags, "ignore_submodules",
		GIT_DIFF_IGNORE_SUBMODULES, &out
	);

	git_flag_opt(
		flags, "ignore_whitespace",
		GIT_DIFF_IGNORE_WHITESPACE, &out
	);

	git_flag_opt(
		flags, "ignore_whitespace_change",
		GIT_DIFF_IGNORE_WHITESPACE_CHANGE, &out
	);

	git_flag_opt(
		flags, "ignore_whitespace_eol",
		GIT_DIFF_IGNORE_WHITESPACE_EOL, &out
	);

	git_flag_opt(
		flags, "skip_binary_check",
		GIT_DIFF_SKIP_BINARY_CHECK, &out
	);

	git_flag_opt(
		flags, "enable_fast_untracked_dirs",
		GIT_DIFF_ENABLE_FAST_UNTRACKED_DIRS, &out
	);

	git_flag_opt(
		flags, "show_untracked_content",
		GIT_DIFF_SHOW_UNTRACKED_CONTENT, &out
	);

	git_flag_opt(
		flags, "show_unmodified",
		GIT_DIFF_SHOW_UNMODIFIED, &out
	);

	git_flag_opt(flags, "patience", GIT_DIFF_PATIENCE, &out);

	git_flag_opt(flags, "minimal", GIT_DIFF_MINIMAL, &out);

	return out;
}

unsigned git_hv_to_diff_find_flag(HV *flags) {
	unsigned out = 0;

	git_flag_opt(flags, "renames", GIT_DIFF_FIND_RENAMES, &out);

	git_flag_opt(
		flags,
		"renames_from_rewrites",
		GIT_DIFF_FIND_RENAMES_FROM_REWRITES, &out
	);

	git_flag_opt(flags, "copies", GIT_DIFF_FIND_COPIES, &out);

	git_flag_opt(
		flags,
		"copies_from_unmodified",
		GIT_DIFF_FIND_COPIES_FROM_UNMODIFIED, &out
	);

	git_flag_opt(flags, "rewrites", GIT_DIFF_FIND_REWRITES, &out);

	git_flag_opt(flags, "break_rewrites", GIT_DIFF_BREAK_REWRITES, &out);

	git_flag_opt(flags, "untracked", GIT_DIFF_FIND_FOR_UNTRACKED, &out);

	git_flag_opt(flags, "all", GIT_DIFF_FIND_ALL, &out);

	git_flag_opt(
		flags,
		"ignore_leading_whitespace",
		GIT_DIFF_FIND_IGNORE_LEADING_WHITESPACE, &out
	);

	git_flag_opt(
		flags,
		"ignore_whitespace",
		GIT_DIFF_FIND_IGNORE_WHITESPACE, &out
	);

	git_flag_opt(
		flags,
		"dont_ignore_whitespace", GIT_DIFF_FIND_DONT_IGNORE_WHITESPACE, &out
	);

	git_flag_opt(
		flags,
		"exact_match_only", GIT_DIFF_FIND_EXACT_MATCH_ONLY, &out
	);

	git_flag_opt(
		flags,
		"break_rewrites_for_renames_only", GIT_DIFF_BREAK_REWRITES_FOR_RENAMES_ONLY,
		&out
	);

	git_flag_opt(flags,
		"remove_unmodified", GIT_DIFF_FIND_REMOVE_UNMODIFIED,
		&out
	);

	return out;
}

int git_diff_cb(const git_diff_delta *delta, const git_diff_hunk *hunk,
		const git_diff_line *line, void *data) {
	dSP;

	SV *coderef = data;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	switch (line -> origin) {
		case GIT_DIFF_LINE_CONTEXT:
			XPUSHs(sv_2mortal(newSVpv("ctx", 0)));
			break;

		case GIT_DIFF_LINE_ADDITION:
		case GIT_DIFF_LINE_ADD_EOFNL:
			XPUSHs(sv_2mortal(newSVpv("add", 0)));
			break;

		case GIT_DIFF_LINE_DELETION:
		case GIT_DIFF_LINE_DEL_EOFNL:
			XPUSHs(sv_2mortal(newSVpv("del", 0)));
			break;

		case GIT_DIFF_LINE_FILE_HDR:
			XPUSHs(sv_2mortal(newSVpv("file", 0)));
			break;

		case GIT_DIFF_LINE_HUNK_HDR:
			XPUSHs(sv_2mortal(newSVpv("hunk", 0)));
			break;

		case GIT_DIFF_LINE_BINARY:
			XPUSHs(sv_2mortal(newSVpv("bin", 0)));
			break;

		default:
			Perl_croak(aTHX_ "Unexpected diff usage");
			break;
	}

	XPUSHs(sv_2mortal(newSVpv(line -> content, line -> content_len)));
	PUTBACK;

	call_sv(coderef, G_DISCARD);

	FREETMPS;
	LEAVE;

	return 0;
}

/* vim: set syntax=xs ts=4 sw=4: */
