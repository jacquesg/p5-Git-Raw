MODULE = Git::Raw			PACKAGE = Git::Raw::Remote

SV *
create(class, repo, name, url)
	SV *class
	SV *repo
	SV *name
	SV *url

	PREINIT:
		int rc;

		git_remote *r = NULL;
		Remote remote = NULL;
		Repository repo_ptr = NULL;

	CODE:
		repo_ptr = GIT_SV_TO_PTR(Repository, repo);
		rc = git_remote_create(
			&r, repo_ptr -> repository,
			git_ensure_pv(name, "name"), git_ensure_pv(url, "url")
		);
		git_check_error(rc);

		Newxz(remote, 1, git_raw_remote);
		git_init_remote_callbacks(&remote -> callbacks);
		remote -> remote = r;
		remote -> owned = 1;

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, SvPVbyte_nolen(class), remote, SvRV(repo)
		);

	OUTPUT: RETVAL

SV *
create_anonymous(class, repo, url, fetch)
	SV *class
	SV *repo
	SV *url
	SV *fetch

	PREINIT:
		int rc;

		git_remote *r = NULL;
		Remote remote = NULL;
		Repository repo_ptr = NULL;

		const char *f = NULL;

	CODE:
		if (SvOK(fetch))
			f = git_ensure_pv(fetch, "fetch");

		repo_ptr = GIT_SV_TO_PTR(Repository, repo);
		rc = git_remote_create_anonymous(
			&r, repo_ptr -> repository,
			git_ensure_pv(url, "url"), f
		);
		git_check_error(rc);

		Newx(remote, 1, git_raw_remote);
		git_init_remote_callbacks(&remote -> callbacks);
		remote -> remote = r;

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, SvPVbyte_nolen(class), remote, SvRV(repo)
		);

	OUTPUT: RETVAL

SV *
load(class, repo, name)
	SV *class
	SV *repo
	SV *name

	PREINIT:
		int rc;

		git_remote *r = NULL;
		Repository repo_ptr = NULL;

	CODE:
		repo_ptr = GIT_SV_TO_PTR(Repository, repo);
		rc = git_remote_lookup(
			&r, repo_ptr -> repository,
			git_ensure_pv(name, "name"));
		if (rc == GIT_ENOTFOUND) {
			RETVAL = &PL_sv_undef;
		} else {
			Remote remote = NULL;
			git_check_error(rc);

			Newx(remote, 1, git_raw_remote);
			git_init_remote_callbacks(&remote -> callbacks);
			remote -> remote = r;

			GIT_NEW_OBJ_WITH_MAGIC(
				RETVAL, SvPVbyte_nolen(class), remote, SvRV(repo)
			);
		}

	OUTPUT: RETVAL

SV *
owner(self)
	SV *self

	PREINIT:
		SV *repo;

	CODE:
		repo = GIT_SV_TO_MAGIC(self);
		RETVAL = newRV_inc(repo);

	OUTPUT: RETVAL

SV *
default_branch(self)
	Remote self

	PREINIT:
		int rc;

		git_buf buf = GIT_BUF_INIT_CONST(NULL, 0);

	CODE:
		rc = git_remote_default_branch(&buf, self -> remote);
		if (rc == GIT_ENOTFOUND) {
			RETVAL = &PL_sv_undef;
		} else {
			if (rc != GIT_OK)
				git_buf_free(&buf);

			git_check_error(rc);
			RETVAL = newSVpv(buf.ptr, buf.size);
		}

		git_buf_free(&buf);

	OUTPUT: RETVAL

SV *
name(self)
	Remote self

	CODE:
		RETVAL = newSVpv(git_remote_name(self -> remote), 0);

	OUTPUT: RETVAL

void
rename(class, repo, old_name, new_name, ...)
	const char *class
	Repository repo
	const char *old_name
	const char *new_name

	PROTOTYPE: $$$$;$

	PREINIT:
		int rc;

		AV *p = NULL;
		Remote remote;
		git_strarray problems = {NULL, 0};

	CODE:
		if (items >= 5)
			p = git_ensure_av(ST(4), "problems");

		rc = git_remote_rename(&problems, repo -> repository,
			old_name, new_name);
		git_check_error(rc);

		if (p != NULL && problems.count > 0) {
			size_t i;
			for (i = 0; i < problems.count; ++i)
				av_push(p, newSVpv(problems.strings[i], 0));
		}
		git_strarray_free(&problems);

SV *
url(self, ...)
	Remote self

	PROTOTYPE: $;$

	PREINIT:
		int rc;
		const char *url;

	CODE:
		if (items == 2) {
			url = git_ensure_pv(ST(1), "url");

			rc = git_remote_set_url(self -> remote, url);
			git_check_error(rc);
		}

		RETVAL = &PL_sv_undef;
		if ((url = git_remote_url(self -> remote)))
			RETVAL = newSVpv(url, 0);

	OUTPUT: RETVAL

SV *
pushurl(self, ...)
	Remote self

	PROTOTYPE: $;$

	PREINIT:
		int rc;
		const char *pushurl;

	CODE:
		if (items == 2) {
			pushurl = git_ensure_pv(ST(1), "pushurl");

			rc = git_remote_set_pushurl(self -> remote, pushurl);
			git_check_error(rc);
		}

		if ((pushurl = git_remote_pushurl(self -> remote)))
			RETVAL = newSVpv(pushurl, 0);
		else
			RETVAL = &PL_sv_undef;

	OUTPUT: RETVAL

void
add_fetch(self, spec)
	Remote self
	SV *spec

	PREINIT:
		int rc;

	CODE:
		rc = git_remote_add_fetch(self -> remote, git_ensure_pv(spec, "spec"));
		git_check_error(rc);

void
add_push(self, spec)
	Remote self
	SV *spec

	PREINIT:
		int rc;

	CODE:
		rc = git_remote_add_push(self -> remote, git_ensure_pv(spec, "spec"));
		git_check_error(rc);

void
clear_refspecs(self)
	Remote self

	CODE:
		git_remote_clear_refspecs(self -> remote);

void
refspecs(self)
	SV *self

	PREINIT:
		size_t i, count;

		Remote remote_ptr;

	PPCODE:
		remote_ptr = GIT_SV_TO_PTR(Remote, self);

		count = git_remote_refspec_count(remote_ptr -> remote);

		for (i = 0; i < count; ++i) {
			const git_refspec *refspec;
			SV *tmp;

			refspec = git_remote_get_refspec(
				remote_ptr -> remote,
				i
			);

			GIT_NEW_OBJ_WITH_MAGIC(
				tmp, "Git::Raw::RefSpec", (git_refspec *) refspec, SvRV(self)
			);

			mXPUSHs(tmp);
		}

		XSRETURN(count);

SV *
refspec_count(self)
	Remote self

	CODE:
		RETVAL = newSVuv(git_remote_refspec_count(self -> remote));

	OUTPUT: RETVAL

void
fetch(self)
	Remote self

	PREINIT:
		int rc;

	CODE:
		rc = git_remote_fetch(self -> remote, NULL, NULL);
		git_check_error(rc);

SV *
push(self, refspecs)
	Remote self
	SV *refspecs

	PREINIT:
		int rc;

		git_push_options opts = GIT_PUSH_OPTIONS_INIT;
		git_strarray specs = {NULL, 0};

	CODE:
		git_list_to_paths(
			git_ensure_av(refspecs, "refspecs"),
			&specs
		);

		/* Reset the push success marker */
		self -> callbacks.push_success = 1;

		rc = git_remote_push(self -> remote, &specs, &opts);
		Safefree(specs.strings);
		if (rc != GIT_OK && rc != GIT_EUSER)
			git_check_error(rc);

		RETVAL = newSViv(self -> callbacks.push_success);

	OUTPUT: RETVAL

void
connect(self, direction)
	Remote self
	SV *direction

	PREINIT:
		int rc;

		const char *dir;
		git_direction direct = GIT_DIRECTION_FETCH;

	CODE:
		dir = git_ensure_pv(direction, "direction");

		if (strcmp(dir, "fetch") == 0)
			direct = GIT_DIRECTION_FETCH;
		else if (strcmp(dir, "push") == 0)
			direct = GIT_DIRECTION_PUSH;
		else
			croak_usage("Invalid direction '%s'. "
				"Valid values: 'fetch' or 'push'", dir);

		rc = git_remote_connect(self -> remote, direct);
		git_check_error(rc);

void
disconnect(self)
	Remote self

	CODE:
		git_remote_disconnect(self -> remote);

void
download(self)
	Remote self

	PREINIT:
		int rc;

	CODE:
		rc = git_remote_download(self -> remote, NULL);
		git_check_error(rc);

SV *
upload(self, refspecs)
	Remote self
	SV *refspecs

	PREINIT:
		int rc;
		git_push_options opts = GIT_PUSH_OPTIONS_INIT;
		git_strarray specs = {NULL, 0};

	CODE:
		git_list_to_paths(
			git_ensure_av(refspecs, "refspecs"),
			&specs
		);

		/* Reset the push success marker */
		self -> callbacks.push_success = 1;

		rc = git_remote_upload(self -> remote, &specs, &opts);
		Safefree(specs.strings);

		if (rc != GIT_OK && rc != GIT_EUSER)
			git_check_error(rc);
		RETVAL = newSViv(self -> callbacks.push_success);

	OUTPUT: RETVAL

void
prune(self)
	Remote self

	PREINIT:
		int rc;

	CODE:
		rc = git_remote_prune(self -> remote);
		git_check_error(rc);

void
update_tips(self)
	Remote self

	PREINIT:
		int rc;

	CODE:
		rc = git_remote_update_tips(self -> remote, NULL);
		git_check_error(rc);

void
callbacks(self, callbacks)
	SV *self
	HV *callbacks

	PREINIT:
		int rc;

		Remote remote;

		git_remote_callbacks rcallbacks = GIT_REMOTE_CALLBACKS_INIT;

	CODE:
		remote = GIT_SV_TO_PTR(Remote, self);

		git_clean_remote_callbacks(&remote -> callbacks);

		if ((remote -> callbacks.credentials =
			get_callback_option(callbacks, "credentials")))
			rcallbacks.credentials = git_credentials_cbb;

		if ((remote -> callbacks.certificate_check =
			get_callback_option(callbacks, "certificate_check")))
			rcallbacks.certificate_check = git_certificate_check_cbb;

		if ((remote -> callbacks.progress =
			get_callback_option(callbacks, "sideband_progress")))
			rcallbacks.sideband_progress = git_progress_cbb;

		if ((remote -> callbacks.transfer_progress =
			get_callback_option(callbacks, "transfer_progress")))
			rcallbacks.transfer_progress = git_transfer_progress_cbb;

		if ((remote -> callbacks.update_tips =
			get_callback_option(callbacks, "update_tips")))
			rcallbacks.update_tips = git_update_tips_cbb;

		if ((remote -> callbacks.pack_progress =
			get_callback_option(callbacks, "pack_progress")))
			rcallbacks.pack_progress = git_packbuilder_progress_cbb;

		if ((remote -> callbacks.push_transfer_progress =
			get_callback_option(callbacks, "push_transfer_progress")))
			rcallbacks.push_transfer_progress = git_push_transfer_progress_cbb;

		/* This callback should always fire */
		remote -> callbacks.push_update_reference =
			get_callback_option(callbacks, "push_update_reference");
		rcallbacks.push_update_reference = git_push_update_reference_cbb;

		rcallbacks.payload = &remote -> callbacks;

		rc = git_remote_set_callbacks(remote -> remote, &rcallbacks);
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
		rc = git_remote_ls(&refs, &count, self -> remote);
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
		RETVAL = newSViv(git_remote_connected(self -> remote));

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	PREINIT:
		Remote remote;

	CODE:
		remote = GIT_SV_TO_PTR(Remote, self);

		git_clean_remote_callbacks(&remote -> callbacks);
		if (remote -> owned)
			git_remote_free(remote -> remote);
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
		Safefree(remote);
