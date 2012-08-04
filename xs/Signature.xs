MODULE = Git::Raw			PACKAGE = Git::Raw::Signature

Signature
new(class, name, email, time, off)
	SV *class
	SV *name
	SV *email
	SV *time
	unsigned off

	CODE:
		Signature sig;
		STRLEN len1, len2, len3, len4;
		const char *name_str = SvPVbyte(name, len1);
		const char *email_str = SvPVbyte(email, len2);
		const char *time_str = SvPVbyte(time, len3);

		git_time_t t;
		sscanf(time_str, "%" PRId64, &t);

		int rc = git_signature_new(&sig, name_str, email_str, t, off);
		git_check_error(rc);

		RETVAL = sig;

	OUTPUT: RETVAL

Signature
now(class, name, email)
	SV *class
	SV *name
	SV *email

	CODE:
		Signature sig;
		STRLEN len1, len2;
		const char *name_str = SvPVbyte(name, len1);
		const char *email_str = SvPVbyte(email, len2);

		int rc = git_signature_now(&sig, name_str, email_str);
		git_check_error(rc);

		RETVAL = sig;

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
		git_time_t time = self -> when.time;

		const int n = snprintf(NULL, 0, "%" PRId64, time);
		char buf[n+1];

		snprintf(buf, n+1, "%" PRId64, time);

		RETVAL = newSVpv(buf, 0);

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
