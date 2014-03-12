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
create_inmemory(class, repo, fetch, url)
	SV *class
	Repository repo
	SV *fetch
	SV *url

	PREINIT:
		int rc;
		Remote remote;

		const char *f = NULL;

	CODE:
		if (SvOK(fetch))
			f = SvPVbyte_nolen(fetch);

		rc = git_remote_create_inmemory(
			&remote, repo, f, SvPVbyte_nolen(url)
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

		const char *dir;
		git_direction direct;

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
		Signature sig;

	CODE:
		rc = git_signature_default(&sig, git_remote_owner(self));
		git_check_error(rc);

		rc = git_remote_update_tips(self, sig, NULL);
		git_signature_free(sig);
		git_check_error(rc);

void
callbacks(self, callbacks)
	SV *self
	HV *callbacks

	PREINIT:
		int rc;

		Remote remote_ptr;

		git_raw_remote_callbacks *cbs = NULL;
		git_remote_callbacks rcallbacks = GIT_REMOTE_CALLBACKS_INIT;

	CODE:
		remote_ptr = GIT_SV_TO_PTR(Remote, self);

		if ((cbs = xs_object_magic_get_struct(aTHX_ self))) {
			git_clean_remote_callbacks(cbs);
		}

		Renew(cbs, 1, git_raw_remote_callbacks);

		if ((cbs -> credentials =
			get_callback_option(callbacks, "credentials")))
			rcallbacks.credentials = git_credentials_cbb;

		if ((cbs -> progress =
			get_callback_option(callbacks, "progress")))
			rcallbacks.progress = git_progress_cbb;

		if ((cbs -> completion =
			get_callback_option(callbacks, "completion")))
			rcallbacks.completion = git_completion_cbb;

		if ((cbs -> transfer_progress =
			get_callback_option(callbacks, "transfer_progress")))
			rcallbacks.transfer_progress = git_transfer_progress_cbb;

		if ((cbs -> update_tips =
			get_callback_option(callbacks, "update_tips")))
			rcallbacks.update_tips = git_update_tips_cbb;

		rcallbacks.payload = cbs;

		xs_object_magic_attach_struct(aTHX_ SvRV(self), cbs);

		rc = git_remote_set_callbacks(remote_ptr, &rcallbacks);
		git_check_error(rc);

SV *
ls(self)
	Remote self

	PREINIT:
		int rc;

		size_t i, count;
		const char *peel = "^{}";
		const git_remote_head **refs;

		HV *r;

	CODE:
		rc = git_remote_ls(&refs, &count, self);
		git_check_error(rc);

		r = newHV();

		for (i = 0; i < count; ++i) {
			size_t len;
			const char *ref_name;

			HV *entry = newHV();
			int local = refs[i] -> local;

			hv_stores(entry, "local", newSViv(local));

			hv_stores(entry, "id", git_oid_to_sv(&refs[i] -> oid));

			if (local)
				hv_stores(entry, "lid",
					git_oid_to_sv(&refs[i] -> loid));

			ref_name = refs[i] -> name;
			len = strlen(ref_name) - (strstr(ref_name, peel) == NULL ?
				0 : strlen(peel));

			hv_store(r, refs[i] -> name, len,
				newRV_noinc((SV *) entry), 0);
		}

		RETVAL = newRV_noinc((SV *) r);

	OUTPUT: RETVAL

SV *
is_connected(self)
	Remote self

	CODE:
		RETVAL = newSViv(git_remote_connected(self));

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	PREINIT:
		git_raw_remote_callbacks *cbs;

	CODE:
		if ((cbs = xs_object_magic_get_struct(aTHX_ self))) {
			git_clean_remote_callbacks(cbs);
			Safefree(cbs);
		}

		git_remote_free(GIT_SV_TO_PTR(Remote, self));
