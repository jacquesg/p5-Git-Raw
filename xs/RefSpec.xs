MODULE = Git::Raw			PACKAGE = Git::Raw::RefSpec

SV *
dst(self)
	RefSpec self

	CODE:
		RETVAL = newSVpv(git_refspec_dst(self), 0);

	OUTPUT: RETVAL

SV *
src(self)
	RefSpec self

	CODE:
		RETVAL = newSVpv(git_refspec_src(self), 0);

	OUTPUT: RETVAL
