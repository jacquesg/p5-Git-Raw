MODULE = Git::Raw			PACKAGE = Git::Raw::Remote

Remote
create(class, repo, name, url)
	SV *class
	Repository repo
	SV *name
	SV *url

	PREINIT:
		int rc;
		Remote remote;

	CODE:
		rc = git_remote_create(
			&remote, repo, SvPVbyte_nolen(name), SvPVbyte_nolen(url)
		);
		git_check_error(rc);

		RETVAL = remote;

	OUTPUT: RETVAL

Remote
load(class, repo, name)
	SV *class
	Repository repo
	SV *name

	PREINIT:
		int rc;
		Remote remote;

	CODE:
		rc = git_remote_load(&remote, repo, SvPVbyte_nolen(name));
		git_check_error(rc);

		RETVAL = remote;

	OUTPUT: RETVAL

SV *
name(self, ...)
	Remote self

	PROTOTYPE: $;$
	PREINIT:
		int rc;
		char *name;

	CODE:
		if (items == 2) {
			name = SvPVbyte_nolen(ST(1));

			rc = git_remote_rename(self, name, NULL, NULL);
			git_check_error(rc);
		}

		name = (char *) git_remote_name(self);

		RETVAL = newSVpv(name, 0);

	OUTPUT: RETVAL

SV *
url(self, ...)
	Remote self

	PROTOTYPE: $;$
	PREINIT:
		int rc;
		const char *url;

	CODE:
		if (items == 2) {
			url = SvPVbyte_nolen(ST(1));

			rc = git_remote_set_url(self, url);
			git_check_error(rc);

			rc = git_remote_save(self);
			git_check_error(rc);
		}

		url = git_remote_url(self);

		RETVAL = newSVpv(url, 0);

	OUTPUT: RETVAL

void
add_fetch(self, spec)
	Remote self
	SV *spec

	PREINIT:
		int rc;

	CODE:
		rc = git_remote_add_fetch(self, SvPVbyte_nolen(spec));
		git_check_error(rc);

void
add_push(self, spec)
	Remote self
	SV *spec

	PREINIT:
		int rc;

	CODE:
		rc = git_remote_add_push(self, SvPVbyte_nolen(spec));
		git_check_error(rc);

void
connect(self, direction)
	Remote self
	SV *direction

	PREINIT:
		int rc;
		git_direction direct;
		const char *dir;

	CODE:
		dir = SvPVbyte_nolen(direction);

		if (strcmp(dir, "fetch") == 0)
			direct = GIT_DIRECTION_FETCH;
		else if (strcmp(dir, "push") == 0)
			direct = GIT_DIRECTION_PUSH;
		else
			Perl_croak(aTHX_ "Invalid direction");

		rc = git_remote_connect(self, direct);
		git_check_error(rc);

void
disconnect(self)
	Remote self

	CODE:
		git_remote_disconnect(self);

void
download(self)
	Remote self

	PREINIT:
		int rc;

	CODE:
		rc = git_remote_download(self);
		git_check_error(rc);

void
save(self)
	Remote self

	PREINIT:
		int rc;

	CODE:
		rc = git_remote_save(self);
		git_check_error(rc);

void
update_tips(self)
	Remote self

	PREINIT:
		int rc;

	CODE:
		rc = git_remote_update_tips(self);
		git_check_error(rc);

void
callbacks(self, callbacks)
	Remote self
	HV *callbacks

	PREINIT:
		SV **opt;
		git_remote_callbacks rcallbacks = GIT_REMOTE_CALLBACKS_INIT;

	CODE:
		/* TODO: support all callbacks */
		if ((opt = hv_fetchs(callbacks, "credentials", 0))) {
			SV *cb = *opt;

			SvREFCNT_inc(cb);

			rcallbacks.credentials = git_cred_acquire_cbb;
			rcallbacks.payload     = cb;
		}

		git_remote_set_callbacks(self, &rcallbacks);

SV *
is_connected(self)
	Remote self

	CODE:
		RETVAL = newSViv(git_remote_connected(self));

	OUTPUT: RETVAL

void
DESTROY(self)
	Remote self

	CODE:
		git_remote_free(self);
