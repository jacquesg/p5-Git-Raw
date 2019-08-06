MODULE = Git::Raw			PACKAGE = Git::Raw::Submodule

void
foreach(class, repo, cb)
	SV *class
	SV *repo
	SV *cb

	PREINIT:
		int rc;

	CODE:
		git_foreach_payload payload = {
			GIT_SV_TO_PTR(Repository, repo),
			repo,
			git_ensure_cv(cb, "callback")
		};

		rc = git_submodule_foreach(payload.repo_ptr -> repository,
			git_submodule_foreach_cb, &payload
		);
		if (rc != GIT_EUSER)
			git_check_error(rc);

SV *
lookup(class, repo, name)
	SV *class
	SV *repo
	SV *name

	PREINIT:
		int rc;
		Submodule module;
		Repository repo_ptr;

	CODE:
		repo_ptr = GIT_SV_TO_PTR(Repository, repo);
		rc = git_submodule_lookup(&module,
			repo_ptr -> repository,
			SvPVbyte_nolen(name));
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, SvPVbyte_nolen(class), module, SvRV(repo)
		);

	OUTPUT: RETVAL

Repository
open(self)
	Submodule self

	PREINIT:
		int rc;
		git_repository *r = NULL;
		Repository repo = NULL;

	CODE:
		rc = git_submodule_open(&r, self);
		git_check_error(rc);

		Newxz(repo, 1, git_raw_repository);
		repo -> repository = r;
		repo -> owned = 1;

		RETVAL = repo;

	OUTPUT: RETVAL

void
init(self, overwrite)
	Submodule self
	SV *overwrite

	PREINIT:
		int rc;

	CODE:
		rc = git_submodule_init(self, SvTRUE (overwrite) ? 1 : 0);
		git_check_error(rc);

void
update(self, init, ...)
	Submodule self
	SV *init

	PREINIT:
		int rc;

		git_submodule_update_options update_opts = GIT_SUBMODULE_UPDATE_OPTIONS_INIT;

	CODE:
		if (items >= 3) {
			git_hv_to_submodule_update_opts(
				git_ensure_hv(ST(2), "update_opts"),
				&update_opts
			);
		}
		rc = git_submodule_update(self, SvTRUE (init) ? 1 : 0,
			&update_opts);
		git_check_error(rc);

SV *
path(self)
	Submodule self

	CODE:
		RETVAL = newSVpv (git_submodule_path(self), 0);

	OUTPUT: RETVAL

SV *
url(self)
	Submodule self

	CODE:
		RETVAL = newSVpv (git_submodule_url(self), 0);

	OUTPUT: RETVAL

SV *
name(self)
	Submodule self

	CODE:
		RETVAL = newSVpv (git_submodule_name(self), 0);

	OUTPUT: RETVAL

void
add_to_index(self)
	Submodule self

	PREINIT:
		int rc;

	CODE:
		rc = git_submodule_add_to_index(self, 1);
		git_check_error(rc);

void
sync(self)
	Submodule self

	PREINIT:
		int rc;

	CODE:
		rc = git_submodule_sync(self);
		git_check_error(rc);

void
reload(self)
	Submodule self

	PREINIT:
		int rc;

	CODE:
		rc = git_submodule_reload(self, 1);
		git_check_error(rc);

void
DESTROY(self)
	Submodule self

	CODE:
		git_submodule_free(self);
