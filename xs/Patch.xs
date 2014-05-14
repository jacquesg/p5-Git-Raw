MODULE = Git::Raw			PACKAGE = Git::Raw::Patch

SV *
buffer(self)
	Patch self

	PREINIT:
		int rc;

		git_buf buf = GIT_BUF_INIT_CONST(NULL, 0);

	CODE:
		rc = git_patch_to_buf(&buf, self);
		git_check_error(rc);

		RETVAL = newSVpv(buf.ptr, buf.size);

		git_buf_free(&buf);

	OUTPUT: RETVAL

SV *
hunk_count(self)
	Patch self

	CODE:
		RETVAL = newSVuv(git_patch_num_hunks(self));

	OUTPUT: RETVAL

void
hunks(self, ...)
	SV *self

	PROTOTYPE: $;$

	PREINIT:
		size_t start = 0, end, num_hunks;

	PPCODE:
		num_hunks = git_patch_num_hunks(GIT_SV_TO_PTR(Patch, self));

		if (items == 2) {
			SV *index = ST(1);

			if (!SvIOK(index) || SvIV(index) < 0)
				croak_usage("Invalid type for 'index'");

			start = SvUV(index);
			if (start >= num_hunks)
				croak_usage("index %" PRIuZ " out of range", start);

			num_hunks = 1;
		}

		end = start + num_hunks;

		for (; start < end; ++start) {
			SV *hunk;
			const git_diff_hunk *h;

			int rc = git_patch_get_hunk(
				&h, NULL, GIT_SV_TO_PTR(Patch, self), start
			);
			git_check_error(rc);

			GIT_NEW_OBJ_WITH_MAGIC(
				hunk, "Git::Raw::Diff::Hunk",
				(Diff_Hunk) h, SvRV(self)
			);

			mXPUSHs(hunk);
		}

		XSRETURN(num_hunks);

SV *
line_stats(self)
	Patch self

	PREINIT:
		int rc;

		size_t total_context, total_additions, total_deletions;

		HV *stats;

	CODE:
		rc = git_patch_line_stats(
			&total_context, &total_additions, &total_deletions, self
		);
		git_check_error(rc);

		stats = newHV();

		hv_stores(stats, "context", newSVuv(total_context));
		hv_stores(stats, "additions", newSVuv(total_additions));
		hv_stores(stats, "deletions", newSVuv(total_deletions));

		RETVAL = newRV_noinc((SV *) stats);

	OUTPUT: RETVAL

SV *
delta(self)
	SV *self

	CODE:
		const git_diff_delta *delta =
			git_patch_get_delta(GIT_SV_TO_PTR(Patch, self)
		);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Diff::Delta",
			(Diff_Delta) delta, SvRV(self));

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		git_patch_free(GIT_SV_TO_PTR(Patch, self));
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
