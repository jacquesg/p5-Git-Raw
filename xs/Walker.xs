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

		GIT_NEW_OBJ(RETVAL, SvPVbyte_nolen(class), walk, SvRV(repo));

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
	char* glob

	PREINIT:
		int rc;

	CODE:
		rc = git_revwalk_push_glob(self, glob);
		git_check_error(rc);

void
push_ref(self, ref)
	Walker self
	char* ref

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

		Repository repo_ptr;

	CODE:
		repo = GIT_SV_TO_REPO(self);
		walk = GIT_SV_TO_PTR(Walker, self);

		repo_ptr = git_revwalk_repository(walk);

		rc = git_revwalk_next(&oid, walk);

		switch (rc) {
			case 0: {
				rc = git_commit_lookup(&commit, repo_ptr, &oid);
				git_check_error(rc);

				break;
			}

			case GIT_ITEROVER:
				XSRETURN_UNDEF;

			default:
				git_check_error(rc);
		}

		GIT_NEW_OBJ(RETVAL, "Git::Raw::Commit", commit, repo);

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
		SvREFCNT_dec(GIT_SV_TO_REPO(self));
