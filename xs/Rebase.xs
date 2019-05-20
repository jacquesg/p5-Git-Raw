MODULE = Git::Raw			PACKAGE = Git::Raw::Rebase

SV *
new(class, repo, branch, upstream, onto, ...)
	SV *class
	SV *repo
	AnnotatedCommit branch
	AnnotatedCommit upstream
	AnnotatedCommit onto

	PREINIT:
		int rc;

		Repository repo_ptr;
		Rebase rebase;

		git_rebase_options rebase_options = GIT_REBASE_OPTIONS_INIT;

	CODE:
		if (items >= 6) {
			HV *opts = git_ensure_hv(ST(5), "rebase_opts");
			git_hv_to_rebase_opts(opts, &rebase_options);
		}

		repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		rc = git_rebase_init(&rebase, repo_ptr -> repository,
			branch, upstream, onto,
			&rebase_options
		);
		git_check_error (rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, SvPVbyte_nolen(class), rebase, SvRV(repo)
		);

	OUTPUT: RETVAL

void
abort(self)
	Rebase self

	PREINIT:
		int rc;

	CODE:
		rc = git_rebase_abort(self);
		git_check_error(rc);

SV *
commit(self, author, committer)
	SV *self
	Signature author
	Signature committer

	PREINIT:
		int rc;

		SV *repo;
		Repository repo_ptr;

		Commit commit;
		git_oid oid;

	CODE:
		repo = GIT_SV_TO_MAGIC(self);
		repo_ptr = INT2PTR(Repository, SvIV((SV *) repo));

		rc = git_rebase_commit(&oid, GIT_SV_TO_PTR(Rebase, self),
			author, committer,
			NULL, NULL
		);
		git_check_error(rc);

		rc = git_commit_lookup(&commit,
			repo_ptr -> repository, &oid);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Commit",
			commit, repo
		);

	OUTPUT: RETVAL

void
finish(self, signature)
	Rebase self
	Signature signature

	PREINIT:
		int rc;

	CODE:
		rc = git_rebase_finish(self, signature);
		git_check_error(rc);

SV *
inmemory_index(self)
	SV *self

	PREINIT:
		int rc;

		Index index;

	CODE:
		rc = git_rebase_inmemory_index(&index,
			GIT_SV_TO_PTR(Rebase, self));
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Index",
			index, SvRV(self)
		);

	OUTPUT: RETVAL

SV *
next(self)
	SV *self

	PREINIT:
		int rc;

		Rebase_Operation op = NULL;

	CODE:
		rc = git_rebase_next(&op,
			GIT_SV_TO_PTR(Rebase, self)
		);
		git_check_error(rc);

		if (op == NULL)
			XSRETURN_UNDEF;

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Rebase::Operation",
			op, SvRV(self)
		);

	OUTPUT: RETVAL

SV *
open(class, repo, ...)
	SV *class
	SV *repo

	PREINIT:
		int rc;

		Repository repo_ptr;
		Rebase rebase;

		git_rebase_options rebase_options = GIT_REBASE_OPTIONS_INIT;

	CODE:
		/* Rebase options */
		if (items >= 3) {
			HV *opts = git_ensure_hv(ST(2), "rebase_opts");
			git_hv_to_rebase_opts(opts, &rebase_options);
		}

		repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		rc = git_rebase_open(&rebase, repo_ptr -> repository,
			&rebase_options
		);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, SvPVbyte_nolen(class), rebase, SvRV(repo)
		);

	OUTPUT: RETVAL

SV *
current_operation(self)
	SV *self

	PREINIT:
		Rebase rebase;
		Rebase_Operation op;

	CODE:
		rebase = GIT_SV_TO_PTR(Rebase, self);

		if (!git_rebase_operation_entrycount(rebase))
			croak_usage("Rebase has no operations");

		op = git_rebase_operation_byindex(rebase,
			git_rebase_operation_current(rebase)
		);

		if (op == NULL)
			XSRETURN_UNDEF;

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Rebase::Operation",
			op, GIT_SV_TO_MAGIC(self)
		);

	OUTPUT: RETVAL

unsigned int
operation_count(self)
	Rebase self

	CODE:
		RETVAL = git_rebase_operation_entrycount(self);

	OUTPUT: RETVAL

void
operations(self)
	SV *self

	PREINIT:
		int ctx;
		size_t i, count;

		Rebase rebase;

	PPCODE:
		ctx = GIMME_V;
		if (ctx == G_VOID)
			XSRETURN_EMPTY;

		rebase = GIT_SV_TO_PTR(Rebase, self);
		count = git_rebase_operation_entrycount(rebase);

		if (ctx == G_SCALAR)
			XSRETURN_IV((int) count);

		for (i = 0; i < count; ++i) {
			SV *tmp;

			Rebase_Operation op =
				git_rebase_operation_byindex(rebase, i);

			GIT_NEW_OBJ_WITH_MAGIC(
				tmp, "Git::Raw::Rebase::Operation",
				op, SvRV(self)
			);
			mXPUSHs(tmp);
		}

		XSRETURN((int) count);

SV *
orig_head_name(self)
	Rebase self

	CODE:
		const char *head_name = git_rebase_orig_head_name(self);
		if (head_name == NULL)
			XSRETURN_UNDEF;

		RETVAL = newSVpv (head_name, 0);

	OUTPUT: RETVAL

SV *
orig_head_id(self)
	Rebase self

	CODE:
		const git_oid *oid = git_rebase_orig_head_id(self);
		if (oid == NULL)
			XSRETURN_UNDEF;

		RETVAL = git_oid_to_sv(oid);

	OUTPUT: RETVAL

SV *
onto_name(self)
	Rebase self

	CODE:
		const char *onto_name = git_rebase_onto_name(self);
		if (onto_name == NULL)
			XSRETURN_UNDEF;

		RETVAL = newSVpv (onto_name, 0);

	OUTPUT: RETVAL

SV *
onto_id(self)
	Rebase self

	CODE:
		const git_oid *oid = git_rebase_onto_id(self);
		if (oid == NULL)
			XSRETURN_UNDEF;

		RETVAL = git_oid_to_sv(oid);

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		git_rebase_free(GIT_SV_TO_PTR(Rebase, self));
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
