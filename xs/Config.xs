MODULE = Git::Raw			PACKAGE = Git::Raw::Config

SV *
get_str(self, name)
	Config self
	SV *name

	CODE:
		STRLEN len;
		const char *value;
		const char *var = SvPVbyte(name, len);

		int rc = git_config_get_string(&value, self, var);
		git_check_error(rc);

		RETVAL = newSVpv(value, 0);

	OUTPUT: RETVAL

SV *
set_str(self, name, value)
	Config self
	SV *name
	SV *value

	CODE:
		STRLEN len1, len2;
		const char *var = SvPVbyte(name, len1);
		const char *val = SvPVbyte(value, len2);

		int rc = git_config_set_string(self, var, val);
		git_check_error(rc);

		RETVAL = newSVpv(val, 0);

	OUTPUT: RETVAL

void
DESTROY(self)
	Config self

	CODE:
		git_config_free(self);
