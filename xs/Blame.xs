MODULE = Git::Raw			PACKAGE = Git::Raw::Blame

SV *
hunk_count(self)
	Blame self

	CODE:
		RETVAL = newSVuv(git_blame_get_hunk_count(self));

	OUTPUT: RETVAL

void
hunks(self, ...)
	SV *self

	PROTOTYPE: $;$

	PREINIT:
		size_t start = 0, end, num_hunks;

	PPCODE:
		num_hunks = git_blame_get_hunk_count(GIT_SV_TO_PTR(Blame, self));

		if (items == 2) {
			SV *index = ST(1);

			if (!SvIOK(index) || SvIV(index) < 0)
				Perl_croak(aTHX_ "Invalid type for 'index'");

			start = SvUV(index);
			if (start >= num_hunks)
				Perl_croak(aTHX_ "index %" PRIuZ " out of range", start);

			num_hunks = 1;
		}

		end = start + num_hunks;

		EXTEND(SP, num_hunks);
		for (; start < end; ++start) {
			SV *hunk;

			const git_blame_hunk *h =
				git_blame_get_hunk_byindex(GIT_SV_TO_PTR(Blame, self),
					start);

			GIT_NEW_OBJ_WITH_MAGIC(
				hunk, "Git::Raw::Blame::Hunk",
				(Blame_Hunk) h, SvRV(self)
			);

			PUSHs(sv_2mortal(hunk));
		}

		XSRETURN(num_hunks);

SV *
buffer(self, buffer)
	SV *self
	SV *buffer

	PREINIT:
		int rc;

		Blame blame;

		const char *text;
		STRLEN len;

	CODE:
		text = git_ensure_pv_with_len(buffer, "buffer", &len);

		rc = git_blame_buffer(
			&blame, GIT_SV_TO_PTR(Blame, self),
			text, len);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Blame",
			blame, SvRV(self));
	OUTPUT: RETVAL

SV *
line(self, line_no)
	SV *self
	size_t line_no

	PREINIT:
		const git_blame_hunk *h;

	CODE:
		if ((h = git_blame_get_hunk_byline(
			GIT_SV_TO_PTR(Blame, self), line_no))) {

			GIT_NEW_OBJ_WITH_MAGIC(
				RETVAL, "Git::Raw::Blame::Hunk",
				(Blame_Hunk) h, SvRV(self)
			);
		} else {
			RETVAL = &PL_sv_undef;
		}

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		git_blame_free(GIT_SV_TO_PTR(Blame, self));
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
