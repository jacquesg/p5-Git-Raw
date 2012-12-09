MODULE = Git::Raw			PACKAGE = Git::Raw::Push

Push
new(class, remote)
	SV *class
	Remote remote

	CODE:
		Push out;

		int rc = git_push_new(&out, remote);
		git_check_error(rc);

		RETVAL = out;

	OUTPUT: RETVAL

void
add_refspec(self, refspec)
	Push self
	SV *refspec

	CODE:
		const char *spec = SvPVbyte_nolen(refspec);

		int rc = git_push_add_refspec(self, spec);
		git_check_error(rc);

void
finish(self)
	Push self

	CODE:
		int rc = git_push_finish(self);
		git_check_error(rc);

bool
unpack_ok(self)
	Push self

	CODE:
		RETVAL = git_push_unpack_ok(self);

	OUTPUT: RETVAL

void
DESTROY(self)
	Push self

	CODE:
		git_push_free(self);
