MODULE = Git::Raw			PACKAGE = Git::Raw::Config

SV *
new(class)
	SV *class

	PREINIT:
		int rc;
		Config cfg;

	CODE:
		rc = git_config_new(&cfg);
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), cfg);

	OUTPUT: RETVAL

void
add_file(self, path, level)
	Config self
	SV *path
	int level

	PREINIT:
		int rc;

	CODE:
		rc = git_config_add_file_ondisk(
			self, SvPVbyte_nolen(path), level, 0
		);
		git_check_error(rc);

SV *
bool(self, name, ...)
	Config self
	SV *name

	PROTOTYPE: $$;$
	PREINIT:
		int rc, value;

	CODE:
		switch (items) {
			case 2: {
				rc = git_config_get_bool(&value, self, SvPVbyte_nolen(name));

				if (rc != GIT_ENOTFOUND)
					git_check_error(rc);

				break;
			}

			case 3: {
				value = SvIV(ST(2));

				rc = git_config_set_bool(self, SvPVbyte_nolen(name), value);
				git_check_error(rc);

				break;
			}

			default:
				rc = GIT_ENOTFOUND;
				break;
		}

		RETVAL = (rc != GIT_ENOTFOUND) ? newSViv(value) : &PL_sv_undef;

	OUTPUT: RETVAL

SV *
int(self, name, ...)
	Config self
	SV *name

	PROTOTYPE: $$;$
	PREINIT:
		int rc, value;

	CODE:
		switch (items) {
			case 2: {
				rc = git_config_get_int32(&value, self, SvPVbyte_nolen(name));

				if (rc != GIT_ENOTFOUND)
					git_check_error(rc);

				break;
			}

			case 3: {
				value = SvIV(ST(2));

				rc = git_config_set_int32(self, SvPVbyte_nolen(name), value);
				git_check_error(rc);

				break;
			}

			default:
				rc = GIT_ENOTFOUND;
				break;
		}

		RETVAL = (rc != GIT_ENOTFOUND) ? newSViv(value) : &PL_sv_undef;

	OUTPUT: RETVAL

SV *
str(self, name, ...)
	Config self
	SV *name

	PROTOTYPE: $$;$
	PREINIT:
		int rc;	
		const char *value;

	CODE:
		switch (items) {
			case 2: {
				rc = git_config_get_string(&value, self, SvPVbyte_nolen(name));

				if (rc != GIT_ENOTFOUND)
					git_check_error(rc);

				break;
			}

			case 3: {
				value = SvPVbyte_nolen(ST(2));

				rc = git_config_set_string(self, SvPVbyte_nolen(name), value);
				git_check_error(rc);

				break;
			}

			default:
				rc = GIT_ENOTFOUND;
				break;
		}

		RETVAL = (rc != GIT_ENOTFOUND) ? newSVpv(value, 0) : &PL_sv_undef;

	OUTPUT: RETVAL

void
foreach(self, cb)
	Config self
	SV *cb

	PREINIT:
		int rc;

	CODE:
		git_foreach_payload payload = {
			.repo = NULL,
			.cb = cb
		};

		rc = git_config_foreach(
			self, git_config_foreach_cbb, &payload
		);

		if (rc != GIT_EUSER)
			git_check_error(rc);

void
refresh(self)
	Config self

	PREINIT:
		int rc;

	CODE:
		rc = git_config_refresh(self);
		git_check_error(rc);

void
delete(self, name)
	Config self
	SV *name

	PREINIT:
		int rc;

	CODE:
		rc = git_config_delete_entry(self, SvPVbyte_nolen(name));
		git_check_error(rc);

void
DESTROY(self)
	Config self

	CODE:
		git_config_free(self);
