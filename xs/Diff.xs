MODULE = Git::Raw			PACKAGE = Git::Raw::Diff

void
merge(self, from)
	Diff self
	Diff from

	PREINIT:
		int rc;

	CODE:
		rc = git_diff_merge(self, from);
		git_check_error(rc);

void
print(self, format, callback)
	Diff self
	SV *format
	SV *callback

	PREINIT:
		int rc;

		const char *fmt_str;
		git_diff_format_t fmt = GIT_DIFF_FORMAT_PATCH;

	CODE:
		fmt_str = SvPVbyte_nolen(format);

		if (!strcmp(fmt_str, "patch"))
			fmt = GIT_DIFF_FORMAT_PATCH;
		else if (!strcmp(fmt_str, "patch_header"))
			fmt = GIT_DIFF_FORMAT_PATCH_HEADER;
		else if (!strcmp(fmt_str, "raw"))
			fmt = GIT_DIFF_FORMAT_RAW;
		else if (!strcmp(fmt_str, "name_only"))
			fmt = GIT_DIFF_FORMAT_NAME_ONLY;
		else if (!strcmp(fmt_str, "name_status"))
			fmt = GIT_DIFF_FORMAT_NAME_STATUS;
		else
			croak_usage("Invalid format");

		rc = git_diff_print(self, fmt, git_diff_cb, callback);
		git_check_error(rc);

SV *
delta_count(self)
	Diff self

	CODE:
		RETVAL = newSVuv(git_diff_num_deltas(self));

	OUTPUT: RETVAL

void
deltas(self, ...)
	SV *self

	PROTOTYPE: $;$

	PREINIT:
		int ctx;
		size_t start = 0, end, num_deltas;

	PPCODE:
		ctx = GIMME_V;

		if (ctx == G_VOID)
			XSRETURN_EMPTY;

		num_deltas = git_diff_num_deltas(GIT_SV_TO_PTR(Diff, self));

		if (items == 2) {
			SV *index = ST(1);

			if (!SvIOK(index) || SvIV(index) < 0)
				croak_usage("Invalid type for 'index'");

			start = SvUV(index);
			if (start >= num_deltas)
				croak_usage("index %" PRIuZ " out of range", start);

			num_deltas = 1;
		}

		end = start + num_deltas;

		for (; start < end; ++start) {
			SV *delta;
			const git_diff_delta *d = git_diff_get_delta(
				GIT_SV_TO_PTR(Diff, self), start
			);

			GIT_NEW_OBJ_WITH_MAGIC(
				delta, "Git::Raw::Diff::Delta",
				(Diff_Delta) d, SvRV(self)
			);

			mXPUSHs(delta);
		}

		XSRETURN(num_deltas);

void
find_similar(self, ...)
	Diff self

	PROTOTYPE: $;$
	PREINIT:
		int rc;

		git_diff_find_options find_opts = GIT_DIFF_FIND_OPTIONS_INIT;

	CODE:
		if (items == 2) {
			SV *opt;
			HV *hopt;
			HV *opts;

			opts = git_ensure_hv(ST(1), "options");

			if ((hopt = git_hv_hash_entry(opts, "flags")))
				find_opts.flags |= git_hv_to_diff_find_flag(hopt);

			if ((opt = git_hv_int_entry(opts, "rename_threshold")))
				find_opts.rename_threshold = SvIV(opt);

			if ((opt = git_hv_int_entry(opts, "rename_from_rewrite_threshold")))
				find_opts.rename_from_rewrite_threshold = SvIV(opt);

			if ((opt = git_hv_int_entry(opts, "copy_threshold")))
				find_opts.copy_threshold = SvIV(opt);

			if ((opt = git_hv_int_entry(opts, "break_rewrite_threshold")))
				find_opts.break_rewrite_threshold = SvIV(opt);

			if ((opt = git_hv_int_entry(opts, "rename_limit")))
				find_opts.rename_limit = SvIV(opt);
		}

		rc = git_diff_find_similar(self, &find_opts);
		git_check_error(rc);

SV *
stats(self)
	SV *self

	PREINIT:
		int rc;

		Diff_Stats stats;

	CODE:
		rc = git_diff_get_stats(&stats, GIT_SV_TO_PTR(Diff, self));
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Diff::Stats", stats, SvRV(self)
		);

	OUTPUT: RETVAL

void
patches(self)
	SV *self

	PREINIT:
		int ctx;

	PPCODE:
		ctx = GIMME_V;

		if (ctx != G_VOID) {
			int rc;
			size_t count;
			Diff diff_ptr;
			diff_ptr = GIT_SV_TO_PTR(Diff, self);

			count = git_diff_num_deltas(diff_ptr);
			if (ctx == G_ARRAY) {
				size_t i;

				for (i = 0; i < count; ++i) {
					SV *tmp;
					Patch patch;

					rc = git_patch_from_diff(&patch, diff_ptr, i);
					git_check_error(rc);

					GIT_NEW_OBJ_WITH_MAGIC(
						tmp, "Git::Raw::Patch", patch, SvRV(self)
					);

					mXPUSHs(tmp);
				}

				XSRETURN((int) count);
			} else {
				mXPUSHs(newSViv((int) count));
				XSRETURN(1);
			}
		} else
			XSRETURN_EMPTY;

void
DESTROY(self)
	SV *self

	CODE:
		git_diff_free(GIT_SV_TO_PTR(Diff, self));
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
