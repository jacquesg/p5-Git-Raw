MODULE = Git::Raw			PACKAGE = Git::Raw::Push

Push
new(class, remote)
	SV *class
	Remote remote

	PREINIT:
		int rc;
		Push push;

	CODE:
		rc = git_push_new(&push, remote);
		git_check_error(rc);

		RETVAL = push;

	OUTPUT: RETVAL

void
add_refspec(self, refspec)
	Push self
	SV *refspec

	PREINIT:
		int rc;

	CODE:
		rc = git_push_add_refspec(self, SvPVbyte_nolen(refspec));
		git_check_error(rc);

void
finish(self)
	Push self

	PREINIT:
		int rc;

	CODE:
		rc = git_push_finish(self);
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
