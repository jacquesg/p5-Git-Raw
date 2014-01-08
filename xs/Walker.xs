MODULE = Git::Raw			PACKAGE = Git::Raw::Walker

SV *
create(class, repo)
	SV *class
	Repository repo

	CODE:
	{
		Walker walk;

		int rc = git_revwalk_new(&walk, repo);
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), walk);
	}

	OUTPUT: RETVAL

void
push(self, commit)
	Walker self
	Commit commit

	CODE:
	{
		int rc = git_revwalk_push(self, git_commit_id(commit));
		git_check_error(rc);
	}

void
push_glob(self, glob)
	Walker self
	char* glob

	CODE:
	{
		int rc = git_revwalk_push_glob(self, glob);
		git_check_error(rc);
	}

void
push_ref(self, ref)
	Walker self
	char* ref

	CODE:
	{
		int rc = git_revwalk_push_ref(self, ref);
		git_check_error(rc);
	}

void
push_head(self)
	Walker self

	CODE:
	{
		int rc = git_revwalk_push_head(self);
		git_check_error(rc);
	}

void
hide(self, commit)
	Walker self
	Commit commit

	CODE:
	{
		int rc = git_revwalk_hide(self, git_commit_id(commit));
		git_check_error(rc);
	}

void
hide_glob(self, glob)
	Walker self
	char* glob

	CODE:
	{
		int rc = git_revwalk_hide_glob(self, glob);
		git_check_error(rc);
	}

void
hide_ref(self, ref)
	Walker self
	char* ref

	CODE:
	{
		int rc = git_revwalk_hide_ref(self, ref);
		git_check_error(rc);
	}

void
hide_head(self)
	Walker self

	CODE:
	{
		int rc = git_revwalk_hide_head(self);
		git_check_error(rc);
	}

Commit
next(self)
	Walker self

	CODE:
	{
		git_oid oid;
		Commit commit;
		int rc = git_revwalk_next(&oid, self);

		switch (rc) {
			case 0: {
				Repository repo = git_revwalk_repository(self);

				rc = git_commit_lookup(&commit, repo, &oid);
				git_check_error(rc);

				break;
			}

			case GIT_ITEROVER: XSRETURN_UNDEF;

			default: git_check_error(rc);
		}

		RETVAL = commit;
	}

	OUTPUT: RETVAL

void
reset(self)
	Walker self

	CODE:
		git_revwalk_reset(self);

void
DESTROY(self)
	Walker self

	CODE:
		git_revwalk_free(self);
