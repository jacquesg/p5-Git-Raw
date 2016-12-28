MODULE = Git::Raw			PACKAGE = Git::Raw::Error

INCLUDE: const-xs-error.inc

SV *
message(self)
	Error self

	CODE:
		SvREFCNT_inc (self -> message);
		RETVAL = self -> message;

	OUTPUT: RETVAL

SV *
code(self)
	Error self

	CODE:
		RETVAL = newSViv(self -> code);

	OUTPUT: RETVAL

SV *
category(self)
	Error self

	CODE:
		RETVAL = newSViv(self -> category);

	OUTPUT: RETVAL

SV *
file(self)
	Error self

	CODE:
		RETVAL = newSVpv(self -> file, 0);

	OUTPUT: RETVAL

SV *
line(self)
	Error self

	CODE:
		RETVAL = newSVuv(self -> line);

	OUTPUT: RETVAL

SV *
_is_error(self)
	Error self

	CODE:
		RETVAL = newSViv(self -> code != 0);

	OUTPUT: RETVAL

void
DESTROY(self)
	Error self

	CODE:
		SvREFCNT_dec(self -> message);
		Safefree(self);
