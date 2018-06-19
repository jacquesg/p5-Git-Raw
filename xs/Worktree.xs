MODULE = Git::Raw			PACKAGE = Git::Raw::Worktree

SV *
add(class, repo, name, path)
	SV *class
	SV *repo
	SV *name
	SV *path

	PREINIT:
		int rc;
		Repository repo_ptr;

		Worktree worktree;

	CODE:
		repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		rc = git_worktree_add(&worktree, repo_ptr -> repository,
			git_ensure_pv(name, "name"), git_ensure_pv(path, "path"),
			NULL);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, SvPVbyte_nolen(class), worktree, SvRV(repo)
		);

	OUTPUT: RETVAL

SV *
lookup(class, repo, name)
	SV *class
	SV *repo
	SV *name

	PREINIT:
		int rc;
		Repository repo_ptr;

		Worktree worktree;

	CODE:
		repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		rc = git_worktree_lookup(&worktree, repo_ptr -> repository,
			git_ensure_pv(name, "name"));
		if (rc != 0)
			XSRETURN_UNDEF;

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, SvPVbyte_nolen(class), worktree, SvRV(repo)
		);

	OUTPUT: RETVAL

Repository
repository(self)
	Worktree self

	PREINIT:
		int rc;
		git_repository *r = NULL;
		Repository repo = NULL;

	CODE:
		rc = git_repository_open_from_worktree(&r, self);
		git_check_error(rc);

		Newxz(repo, 1, git_raw_repository);
		repo -> repository = r;
		repo -> owned = 1;

		RETVAL = repo;

	OUTPUT: RETVAL

void
list(class, repo)
	SV *class
	Repository repo

	PREINIT:
		int rc, ctx;

		int i, num_worktrees = 0;
		git_strarray worktrees = {0, 0};

	PPCODE:
		ctx = GIMME_V;

		if (ctx != G_VOID) {
			rc = git_worktree_list(&worktrees, repo -> repository);
			git_check_error(rc);

			for (i = 0; i < worktrees.count; ++i) {
				if (ctx == G_ARRAY)
					mXPUSHs(newSVpv(worktrees.strings[i], 0));
				++num_worktrees;
			}

			git_strarray_free(&worktrees);
			if (ctx == G_ARRAY)
				XSRETURN(num_worktrees);
			mXPUSHi((int) num_worktrees);
			XSRETURN(1);
		} else
			XSRETURN_EMPTY;

void
is_locked(self)
	Worktree self

	PREINIT:
		int rc;
		git_buf buf = GIT_BUF_INIT_CONST(NULL, 0);

	PPCODE:
		rc = git_worktree_is_locked(&buf, self);
		if (rc < 0) {
			git_buf_dispose(&buf);
			git_check_error(rc);
		}

		if (rc > 0)
			mXPUSHp (buf.ptr, buf.size);
		else
			mXPUSHi (0);

		git_buf_dispose(&buf);
		XSRETURN(1);

void
is_prunable(self, opts)
	Worktree self
	HV *opts

	PREINIT:
		int rc;
		git_worktree_prune_options prune_options = GIT_WORKTREE_PRUNE_OPTIONS_INIT;

	PPCODE:
		git_hv_to_worktree_prune_opts(opts, &prune_options);
		rc = git_worktree_is_prunable(self, &prune_options);
		XSRETURN_IV(rc);

void
lock(self, reason)
	Worktree self
	SV *reason

	PREINIT:
		int rc;

	PPCODE:
		rc = git_worktree_lock(self, git_ensure_pv(reason, "reason"));
		git_check_error(rc);

		XSRETURN_YES;

void
unlock(self)
	Worktree self

	PREINIT:
		int rc;

	CODE:
		rc = git_worktree_unlock(self);
		git_check_error(rc);

void
validate(self)
	Worktree self

	PREINIT:
		int rc;

	PPCODE:
		rc = git_worktree_validate(self);
		if (rc == 0)
			XSRETURN_YES;

		XSRETURN_NO;

void
prune(self, opts)
	Worktree self
	HV *opts

	PREINIT:
		int rc;
		git_worktree_prune_options prune_options = GIT_WORKTREE_PRUNE_OPTIONS_INIT;

	CODE:
		git_hv_to_worktree_prune_opts(opts, &prune_options);
		rc = git_worktree_prune(self, &prune_options);
		git_check_error(rc);

void
DESTROY(self)
	SV *self

	CODE:
		git_worktree_free(GIT_SV_TO_PTR(Worktree, self));
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));

