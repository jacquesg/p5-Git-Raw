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
		git_diff_format_t fmt;

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
			Perl_croak(aTHX_ "Invalid format");

		rc = git_diff_print(self, fmt, git_diff_cb, callback);
		git_check_error(rc);

SV *
delta_count(self)
	Diff self

	CODE:
		RETVAL = newSVuv(git_diff_num_deltas(self));

	OUTPUT: RETVAL

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

void
patches(self)
	SV *self

	PREINIT:
		int rc;

		Diff diff_ptr;

		size_t i, count, num_patches = 0;

	PPCODE:
		diff_ptr = GIT_SV_TO_PTR(Diff, self);

		count = git_diff_num_deltas(diff_ptr);
		for (i = 0; i < count; ++i) {
			Patch patch;

			rc = git_patch_from_diff(&patch, diff_ptr, i);
			git_check_error(rc);

			if (patch) {
				SV *p;

				GIT_NEW_OBJ_WITH_MAGIC(
					p, "Git::Raw::Patch", patch, SvRV(self)
				);

				EXTEND(SP, 1);
				PUSHs(sv_2mortal(p));

				++num_patches;
			}
		}

		XSRETURN(num_patches);

void
DESTROY(self)
	Diff self

	CODE:
		git_diff_free(self);
