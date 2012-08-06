MODULE = Git::Raw			PACKAGE = Git::Raw::Config

bool
bool(self, name, ...)
	Config self
	SV *name

	CODE:
		int rc;
		STRLEN len;
		bool value;
		const char *var = SvPVbyte(name, len);

		switch (items) {
			case 2: {
				rc = git_config_get_bool(&value, self, var);
				git_check_error(rc);

				break;
			}

			case 3: {
				value = SvIV(ST(2));

				rc = git_config_set_bool(self, var, value);
				git_check_error(rc);

				break;
			}

			default: Perl_croak(aTHX_ "Too much arguments");
		}

		RETVAL = value;

	OUTPUT: RETVAL

int
int(self, name, ...)
	Config self
	SV *name

	CODE:
		STRLEN len;
		int rc, value;
		const char *var = SvPVbyte(name, len);

		switch (items) {
			case 2: {
				rc = git_config_get_int32(&value, self, var);
				git_check_error(rc);

				break;
			}

			case 3: {
				value = SvIV(ST(2));

				rc = git_config_set_int32(self, var, value);
				git_check_error(rc);

				break;
			}

			default: Perl_croak(aTHX_ "Too much arguments");
		}

		RETVAL = value;

	OUTPUT: RETVAL

SV *
string(self, name, ...)
	Config self
	SV *name

	CODE:
		int rc;
		STRLEN len;
		char *value;
		const char *var = SvPVbyte(name, len);

		switch (items) {
			case 2: {
				rc = git_config_get_string(&value, self, var);
				git_check_error(rc);

				break;
			}

			case 3: {
				STRLEN len2;
				value = SvPVbyte(ST(2), len2);

				rc = git_config_set_string(self, var, value);
				git_check_error(rc);

				break;
			}

			default: Perl_croak(aTHX_ "Too much arguments");
		}

		RETVAL = newSVpv(value, 0);

	OUTPUT: RETVAL

void
DESTROY(self)
	Config self

	CODE:
		git_config_free(self);
