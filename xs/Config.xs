MODULE = Git::Raw			PACKAGE = Git::Raw::Config

SV *
new(class)
	SV *class

	CODE:
		Config cfg;

		int rc = git_config_new(&cfg);
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), cfg);

	OUTPUT: RETVAL

void
add_file(self, path, level)
	Config self
	SV *path
	int level

	CODE:
		int rc = git_config_add_file_ondisk(
			self, SvPVbyte_nolen(path), level, 0
		);
		git_check_error(rc);

SV *
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

				if (rc != GIT_ENOTFOUND)
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

		RETVAL = (rc != GIT_ENOTFOUND) ? boolSV(value) : &PL_sv_undef;

	OUTPUT: RETVAL

SV *
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

				if (rc != GIT_ENOTFOUND)
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

		RETVAL = (rc != GIT_ENOTFOUND) ? newSViv(value) : &PL_sv_undef;

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

				if (rc != GIT_ENOTFOUND)
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

		RETVAL = (rc != GIT_ENOTFOUND) ? newSVpv(value, 0) : &PL_sv_undef;

	OUTPUT: RETVAL

void
foreach(self, cb)
	Config self
	SV *cb

	CODE:
		git_foreach_payload payload = {
			.repo = NULL,
			.cb = cb
		};

		int rc = git_config_foreach(
			self, git_config_foreach_cbb, &payload
		);

		if (rc != GIT_EUSER)
			git_check_error(rc);

void
refresh(self)
	Config self

	CODE:
		int rc = git_config_refresh(self);
		git_check_error(rc);

void
delete(self, name)
	Config self
	SV *name

	CODE:
		int rc = git_config_delete_entry(self, SvPVbyte_nolen(name));
		git_check_error(rc);

void
DESTROY(self)
	Config self

	CODE:
		git_config_free(self);
