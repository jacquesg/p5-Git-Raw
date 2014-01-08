MODULE = Git::Raw			PACKAGE = Git::Raw::Signature

Signature
new(class, name, email, time, off)
	SV *class
	SV *name
	SV *email
	SV *time
	unsigned off

	CODE:
	{
		Signature sig;

		git_time_t git_time;
		sscanf(SvPVbyte_nolen(time), "%" PRId64, &git_time);

		int rc = git_signature_new(
			&sig, SvPVbyte_nolen(name),
			SvPVbyte_nolen(email), git_time, off
		);
		git_check_error(rc);

		RETVAL = sig;
	}

	OUTPUT: RETVAL

Signature
now(class, name, email)
	SV *class
	SV *name
	SV *email

	CODE:
	{
		Signature sig;

		int rc = git_signature_now(
			&sig, SvPVbyte_nolen(name), SvPVbyte_nolen(email)
		);
		git_check_error(rc);

		RETVAL = sig;
	}

	OUTPUT: RETVAL

SV *
name(self)
	Signature self

	CODE:
		RETVAL = newSVpv(self -> name, 0);

	OUTPUT: RETVAL

SV *
email(self)
	Signature self

	CODE:
		RETVAL = newSVpv(self -> email, 0);

	OUTPUT: RETVAL

SV *
time(self)
	Signature self

	CODE:
	{
		char *buf;
		git_time_t time = self -> when.time;

		Newx(buf, snprintf(NULL, 0, "%" PRId64, time)+1, char);
		sprintf(buf, "%" PRId64, time);

		RETVAL = newSVpv(buf, 0);
		Safefree(buf);
	}

	OUTPUT: RETVAL

int
offset(self)
	Signature self

	CODE:
		RETVAL = self -> when.offset;

	OUTPUT: RETVAL

void DESTROY(self)
	Signature self

	CODE:
		git_signature_free(self);
