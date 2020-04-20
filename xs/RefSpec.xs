MODULE = Git::Raw			PACKAGE = Git::Raw::RefSpec

RefSpec
parse(class, input, is_fetch)
	SV *class
	SV *input
	SV *is_fetch

	PREINIT:
		int rc;
		git_refspec *s = NULL;
		RefSpec spec = NULL;

	CODE:
		rc = git_refspec_parse(&s, git_ensure_pv(input, "input"),
			git_ensure_iv(is_fetch, "is_fetch"));
		git_check_error(rc);

		Newxz(spec, 1, git_raw_refspec);
		spec -> refspec = s;
		spec -> owned = 1;

		RETVAL = spec;

	OUTPUT: RETVAL

SV *
dst(self)
	RefSpec self

	CODE:
		RETVAL = newSVpv(git_refspec_dst(self -> refspec), 0);

	OUTPUT: RETVAL

SV *
dst_matches(self, ref)
	RefSpec self
	SV *ref

	PREINIT:
		const char *ref_name;

	CODE:
		ref_name = git_ensure_pv(ref, "name");

		RETVAL = newSViv(git_refspec_dst_matches(self -> refspec, ref_name));

	OUTPUT: RETVAL

SV *
src(self)
	RefSpec self

	CODE:
		RETVAL = newSVpv(git_refspec_src(self -> refspec), 0);

	OUTPUT: RETVAL

SV *
src_matches(self, ref)
	RefSpec self
	SV *ref

	PREINIT:
		const char *ref_name;

	CODE:
		ref_name = git_ensure_pv(ref, "name");

		RETVAL = newSViv(git_refspec_src_matches(self -> refspec, ref_name));

	OUTPUT: RETVAL

SV *
string(self)
	RefSpec self

	CODE:
		RETVAL = newSVpv(git_refspec_string(self -> refspec), 0);

	OUTPUT: RETVAL

SV *
direction(self)
	RefSpec self

	PREINIT:
		git_direction dir;

	CODE:
		dir = git_refspec_direction(self -> refspec);
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
		RETVAL = &PL_sv_undef;

		ref_name = git_ensure_pv(ref, "name");

		rc = git_refspec_transform(&buf, self -> refspec, ref_name);
		if (rc == GIT_OK)
			RETVAL = newSVpv(buf.ptr, buf.size);

		git_buf_dispose(&buf);
		git_check_error(rc);

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
		RETVAL = &PL_sv_undef;

		ref_name = git_ensure_pv(ref, "name");

		rc = git_refspec_rtransform(&buf, self -> refspec, ref_name);
		if (rc == GIT_OK)
			RETVAL = newSVpv(buf.ptr, buf.size);

		git_buf_dispose(&buf);
		git_check_error(rc);

	OUTPUT: RETVAL

SV *
is_force(self)
	RefSpec self

	CODE:
		RETVAL = newSViv(git_refspec_force(self -> refspec));

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	PREINIT:
		RefSpec spec;

	CODE:
		spec = GIT_SV_TO_PTR(RefSpec, self);

		if (spec -> owned)
			git_refspec_free(spec -> refspec);
		else
			SvREFCNT_dec(GIT_SV_TO_MAGIC(self));

		Safefree(spec);

