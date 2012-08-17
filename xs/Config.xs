MODULE = Git::Raw			PACKAGE = Git::Raw::Config

bool
bool(self, name, ...)
	Config self
	SV *name

	PROTOTYPE: $$;$
	CODE:
		int rc, value;
		const char *var = SvPVbyte_nolen(name);

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
		}

		RETVAL = value;

	OUTPUT: RETVAL

int
int(self, name, ...)
	Config self
	SV *name

	PROTOTYPE: $$;$
	CODE:
		int rc, value;
		const char *var = SvPVbyte_nolen(name);

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
		}

		RETVAL = value;

	OUTPUT: RETVAL

SV *
str(self, name, ...)
	Config self
	SV *name

	PROTOTYPE: $$;$
	CODE:
		int rc;
		const char *value, *var = SvPVbyte_nolen(name);

		switch (items) {
			case 2: {
				rc = git_config_get_string(&value, self, var);
				git_check_error(rc);

				break;
			}

			case 3: {
				value = SvPVbyte_nolen(ST(2));

				rc = git_config_set_string(self, var, value);
				git_check_error(rc);

				break;
			}
		}

		RETVAL = newSVpv(value, 0);

	OUTPUT: RETVAL

void
DESTROY(self)
	Config self

	CODE:
		git_config_free(self);
