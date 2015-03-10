MODULE = Git::Raw			PACKAGE = Git::Raw::Config

Config
new(class)
	SV *class

	PREINIT:
		int rc;
		Config cfg;

	CODE:
		rc = git_config_new(&cfg);
		git_check_error(rc);

		RETVAL = cfg;

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
			self, git_ensure_pv(path, "path"), level, 0
		);
		git_check_error(rc);

SV *
bool(self, name, ...)
	Config self
	SV *name

	PROTOTYPE: $$;$

	PREINIT:
		int rc, value;

		const char *id = NULL;

	CODE:
		id = git_ensure_pv(name, "name");

		if (items == 3) {
			value = git_ensure_iv(ST(2), "value");

			rc = git_config_set_bool(self, id, value);
		} else {
			if ((rc = git_config_get_bool(&value, self, id)) == GIT_ENOTFOUND)
				XSRETURN_UNDEF;
		}

		git_check_error(rc);
		RETVAL = newSViv(value);

	OUTPUT: RETVAL

SV *
int(self, name, ...)
	Config self
	SV *name

	PROTOTYPE: $$;$

	PREINIT:
		int rc, value;

		const char *id = NULL;

	CODE:
		id = git_ensure_pv(name, "name");

		if (items == 3) {
			value = git_ensure_iv(ST(2), "value");

			rc = git_config_set_int32(self, id, value);
		} else {
			if ((rc = git_config_get_int32(&value, self, id)) == GIT_ENOTFOUND)
				XSRETURN_UNDEF;
		}

		git_check_error(rc);
		RETVAL = newSViv(value);

	OUTPUT: RETVAL

SV *
str(self, name, ...)
	Config self
	SV *name

	PROTOTYPE: $$;$

	PREINIT:
		int rc;
		const char *value;

		const char *id = NULL;
	CODE:
		id = git_ensure_pv(name, "name");

		if (items == 3) {
			value = git_ensure_pv(ST(2), "value");

			rc = git_config_set_string(self, id, value);
			git_check_error(rc);

			RETVAL = newSVpv(value, 0);
		} else {
			git_buf buf = GIT_BUF_INIT_CONST(NULL, 0);
			if ((rc = git_config_get_string_buf(&buf, self, id)) == GIT_ENOTFOUND)
				XSRETURN_UNDEF;
			git_check_error(rc);

			RETVAL = newSVpv(buf.ptr, 0);
			git_buf_free(&buf);
		}

	OUTPUT: RETVAL

void
foreach(self, cb)
	Config self
	SV *cb

	PREINIT:
		int rc;

		git_foreach_payload payload = { NULL, NULL, NULL };

	CODE:
		payload.cb = cb;

		rc = git_config_foreach(
			self, git_config_foreach_cbb, &payload
		);

		if (rc != GIT_EUSER)
			git_check_error(rc);

Config
default(class)
	SV *class

	PREINIT:
		int rc;
		Config cfg;

	CODE:
		rc = git_config_open_default(&cfg);
		git_check_error(rc);

		RETVAL = cfg;

	OUTPUT: RETVAL

void
delete(self, name)
	Config self
	SV *name

	PREINIT:
		int rc;

	CODE:
		rc = git_config_delete_entry(self, git_ensure_pv(name, "name"));
		git_check_error(rc);

void
DESTROY(self)
	Config self

	CODE:
		git_config_free(self);
