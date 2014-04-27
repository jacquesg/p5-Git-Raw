MODULE = Git::Raw			PACKAGE = Git::Raw::Walker

SV *
create(class, repo)
	SV *class
	SV *repo

	PREINIT:
		int rc;
		Walker walk;

	CODE:
		rc = git_revwalk_new(&walk, GIT_SV_TO_PTR(Repository, repo));
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, SvPVbyte_nolen(class), walk, SvRV(repo)
		);

	OUTPUT: RETVAL

void
push(self, commit)
	Walker self
	Commit commit

	PREINIT:
		int rc;

	CODE:
		rc = git_revwalk_push(self, git_commit_id(commit));
		git_check_error(rc);

void
push_glob(self, glob)
	Walker self
	const char* glob

	PREINIT:
		int rc;

	CODE:
		rc = git_revwalk_push_glob(self, glob);
		git_check_error(rc);

void
push_ref(self, ref)
	Walker self
	const char* ref

	PREINIT:
		int rc;

	CODE:
		rc = git_revwalk_push_ref(self, ref);
		git_check_error(rc);

void
push_head(self)
	Walker self

	PREINIT:
		int rc;

	CODE:
		rc = git_revwalk_push_head(self);
		git_check_error(rc);

void
push_range(self, ...)
	SV *self

	PROTOTYPE: $;@
	PREINIT:
		int rc, free_buffer = 0;

		Repository repo;
		Walker walk;

		char *range = NULL;

	CODE:
		walk = GIT_SV_TO_PTR(Walker, self);
		repo = git_revwalk_repository(walk);

		if (items == 3) {
			git_oid start, end;

			if (git_sv_to_commitish(repo, ST(1), &start) == NULL)
				Perl_croak(aTHX_ "Could not resolve 'start' to a commit id");
			if (git_sv_to_commitish(repo, ST(2), &end) == NULL)
				Perl_croak(aTHX_ "Could not resolve 'end' to a commit id");

			Newx(range, 2 * GIT_OID_HEXSZ + 2 + 1, char);
			free_buffer = 1;

			git_oid_tostr(range, GIT_OID_HEXSZ + 1, &start);
			strncpy(range + GIT_OID_HEXSZ, "..", 2);
			git_oid_tostr(range + GIT_OID_HEXSZ + 2, GIT_OID_HEXSZ + 1, &end);
		} else if (items == 2) {
			range = (char *) git_ensure_pv(ST(1), "range");
		} else
			Perl_croak(aTHX_ "'range' not provided");

		rc = git_revwalk_push_range(walk, range);
		if (free_buffer)
			Safefree(range);
		git_check_error(rc);

void
hide(self, commit)
	Walker self
	Commit commit

	PREINIT:
		int rc;

	CODE:
		rc = git_revwalk_hide(self, git_commit_id(commit));
		git_check_error(rc);

void
hide_glob(self, glob)
	Walker self
	char* glob

	PREINIT:
		int rc;

	CODE:
		rc = git_revwalk_hide_glob(self, glob);
		git_check_error(rc);

void
hide_ref(self, ref)
	Walker self
	char* ref

	PREINIT:
		int rc;

	CODE:
		rc = git_revwalk_hide_ref(self, ref);
		git_check_error(rc);

void
hide_head(self)
	Walker self

	PREINIT:
		int rc;

	CODE:
		rc = git_revwalk_hide_head(self);
		git_check_error(rc);

SV *
next(self)
	SV *self

	PREINIT:
		int rc;

		SV *repo;

		Walker walk;

		git_oid oid;
		Commit commit = NULL;

	CODE:
		repo = GIT_SV_TO_MAGIC(self);
		walk = GIT_SV_TO_PTR(Walker, self);

		rc = git_revwalk_next(&oid, walk);
		if (rc == GIT_ITEROVER)
			XSRETURN_UNDEF;
		git_check_error(rc);

		rc = git_commit_lookup(&commit, git_revwalk_repository(walk), &oid);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Commit", commit, repo
		);

	OUTPUT: RETVAL

void
reset(self)
	Walker self

	CODE:
		git_revwalk_reset(self);

void
DESTROY(self)
	SV *self

	CODE:
		git_revwalk_free(GIT_SV_TO_PTR(Walker, self));
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
