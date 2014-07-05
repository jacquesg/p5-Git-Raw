MODULE = Git::Raw			PACKAGE = Git::Raw::Signature

Signature
new(class, name, email, time, off)
	SV *class
	SV *name
	SV *email
	SV *time
	unsigned off

	PREINIT:
		int rc;
		Signature sig;

		git_time_t git_time;

	CODE:
		sscanf(SvPVbyte_nolen(time), "%" PRId64, &git_time);

		rc = git_signature_new(
			&sig, git_ensure_pv(name, "name"),
			git_ensure_pv(email, "email"), git_time, off
		);
		git_check_error(rc);

		RETVAL = sig;

	OUTPUT: RETVAL

Signature
now(class, name, email)
	SV *class
	SV *name
	SV *email

	PREINIT:
		int rc;
		Signature sig;

	CODE:
		rc = git_signature_now(
			&sig, git_ensure_pv(name, "name"), git_ensure_pv(email, "email")
		);
		git_check_error(rc);

		RETVAL = sig;

	OUTPUT: RETVAL

Signature
default(class, repo)
	SV *class
	Repository repo

	PREINIT:
		int rc;
		Signature sig;

	CODE:
		rc = git_signature_default(&sig, repo -> repository);
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

	PREINIT:
		char *buf;
		git_time_t time;

	CODE:
		time = self -> when.time;

		Newx(buf, snprintf(NULL, 0, "%" PRId64, time)+1, char);
		sprintf(buf, "%" PRId64, time);

		RETVAL = newSVpv(buf, 0);
		Safefree(buf);

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
