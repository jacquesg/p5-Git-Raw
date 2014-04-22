MODULE = Git::Raw			PACKAGE = Git::Raw::RefSpec

SV *
dst(self)
	RefSpec self

	CODE:
		RETVAL = newSVpv(git_refspec_dst(self), 0);

	OUTPUT: RETVAL

SV *
dst_matches(self, ref)
	RefSpec self
	SV *ref

	PREINIT:
		const char *ref_name;

	CODE:
		if (!SvPOK(ref))
			Perl_croak(aTHX_ "Expected a string for 'name'");

		ref_name = SvPVbyte_nolen(ref);

		RETVAL = newSViv(git_refspec_dst_matches(self, ref_name));

	OUTPUT: RETVAL

SV *
src(self)
	RefSpec self

	CODE:
		RETVAL = newSVpv(git_refspec_src(self), 0);

	OUTPUT: RETVAL

SV *
src_matches(self, ref)
	RefSpec self
	SV *ref

	PREINIT:
		const char *ref_name;

	CODE:
		if (!SvPOK(ref))
			Perl_croak(aTHX_ "Expected a string for 'name'");

		ref_name = SvPVbyte_nolen(ref);

		RETVAL = newSViv(git_refspec_src_matches(self, ref_name));

	OUTPUT: RETVAL

SV *
string(self)
	RefSpec self

	CODE:
		RETVAL = newSVpv(git_refspec_string(self), 0);

	OUTPUT: RETVAL

SV *
direction(self)
	RefSpec self

	PREINIT:
		git_direction dir;

	CODE:
		dir = git_refspec_direction(self);
		if (dir == GIT_DIRECTION_FETCH)
			RETVAL = newSVpv("fetch", 0);
		else if (dir == GIT_DIRECTION_PUSH)
			RETVAL = newSVpv("push", 0);
		else
			RETVAL = &PL_sv_undef;

	OUTPUT: RETVAL

SV *
transform(self, ref)
	RefSpec self
	SV *ref

	PREINIT:
		int rc;

		const char *ref_name;
		git_buf buf = GIT_BUF_INIT_CONST(NULL, 0);

	CODE:
		if (!SvPOK(ref))
			Perl_croak(aTHX_ "Expected a string for 'name'");

		ref_name = SvPVbyte_nolen(ref);

		rc = git_refspec_transform(&buf, self, ref_name);
		if (rc != GIT_OK)
			git_buf_free(&buf);
		git_check_error(rc);

		RETVAL = newSVpv(buf.ptr, buf.size);
		git_buf_free(&buf);

	OUTPUT: RETVAL

SV *
rtransform(self, ref)
	RefSpec self
	SV *ref

	PREINIT:
		int rc;

		const char *ref_name;
		git_buf buf = GIT_BUF_INIT_CONST(NULL, 0);

	CODE:
		if (!SvPOK(ref))
			Perl_croak(aTHX_ "Expected a string for 'name'");

		ref_name = SvPVbyte_nolen(ref);

		rc = git_refspec_rtransform(&buf, self, ref_name);
		if (rc != GIT_OK)
			git_buf_free(&buf);
		git_check_error(rc);

		RETVAL = newSVpv(buf.ptr, buf.size);
		git_buf_free(&buf);

	OUTPUT: RETVAL

SV *
is_force(self)
	RefSpec self

	CODE:
		RETVAL = newSViv(git_refspec_force(self));

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
