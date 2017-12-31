MODULE = Git::Raw			PACKAGE = Git::Raw::Rebase::Operation

INCLUDE: const-xs-rebase-operation.inc

SV *
type(self)
	Rebase_Operation self

	CODE:
		RETVAL = newSViv(self -> type);

	OUTPUT: RETVAL

SV *
id(self)
	Rebase_Operation self

	CODE:
		RETVAL = git_oid_to_sv(&self -> id);

	OUTPUT: RETVAL

SV *
exec(self)
	Rebase_Operation self

	CODE:
		RETVAL = newSVpv(self -> exec, 0);

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
