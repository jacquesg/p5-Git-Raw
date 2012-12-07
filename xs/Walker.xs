MODULE = Git::Raw			PACKAGE = Git::Raw::Walker

SV *
create(class, repo)
	SV *class
	Repository repo

	CODE:
		Walker w;

		int rc = git_revwalk_new(&w, repo);
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), w);

	OUTPUT: RETVAL

void
push(self, commit)
	Walker self
	Commit commit

	CODE:
		int rc = git_revwalk_push(self, git_commit_id(commit));
		git_check_error(rc);

Commit
next(self)
	Walker self

	CODE:
		Commit c;
		git_oid oid;
		int rc = git_revwalk_next(&oid, self);

		switch (rc) {
			case 0: {
				Repository r = git_revwalk_repository(self);
				rc = git_commit_lookup(&c, r, &oid);
				git_check_error(rc);

				break;
			}

			case GIT_ITEROVER: XSRETURN_UNDEF;

			default: git_check_error(rc);
		}

		RETVAL = c;

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
