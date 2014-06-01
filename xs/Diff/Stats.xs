MODULE = Git::Raw			PACKAGE = Git::Raw::Diff::Stats

SV *
deletions(self)
	Diff_Stats self

	CODE:
		RETVAL = newSVuv(git_diff_stats_deletions(self));

	OUTPUT: RETVAL

SV *
insertions(self)
	Diff_Stats self

	CODE:
		RETVAL = newSVuv(git_diff_stats_insertions(self));

	OUTPUT: RETVAL

SV *
files_changed(self)
	Diff_Stats self

	CODE:
		RETVAL = newSVuv(git_diff_stats_files_changed(self));

	OUTPUT: RETVAL

SV *
buffer(self, ...)
	Diff_Stats self

	PROTOTYPE: $;$
	PREINIT:
		int rc;
		size_t width = 0;

		git_buf buf = GIT_BUF_INIT_CONST(NULL, 0);

		git_diff_stats_format_t format = GIT_DIFF_STATS_NONE;

	CODE:
		if (items == 2) {
			HV *opts = git_ensure_hv(ST(1), "options");
			HV *flags;

			if ((flags = git_hv_hash_entry(opts, "flags"))) {
				unsigned out = 0;

				git_flag_opt(flags, "full", GIT_DIFF_STATS_FULL, &out);
				git_flag_opt(flags, "short", GIT_DIFF_STATS_SHORT, &out);
				git_flag_opt(flags, "number", GIT_DIFF_STATS_NUMBER, &out);
				git_flag_opt(flags, "summary", GIT_DIFF_STATS_INCLUDE_SUMMARY, &out);

				format = out;
			}
		}

		rc = git_diff_stats_to_buf(&buf, self, format, width);
		git_check_error(rc);

		RETVAL = newSVpv(buf.ptr, buf.size);

		git_buf_free(&buf);

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		GIT_FREE_OBJ(Diff::Status, self, git_diff_stats_free);
