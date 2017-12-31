MODULE = Git::Raw			PACKAGE = Git::Raw::AnnotatedCommit

SV *
id(self)
	AnnotatedCommit self

	CODE:
		RETVAL = git_oid_to_sv(git_annotated_commit_id(self));

	OUTPUT: RETVAL

SV *
lookup(class, repo, id)
	SV *class
	SV *repo
	SV *id

	PREINIT:
		int rc;

		git_oid oid;
		AnnotatedCommit commit;
		Repository repo_ptr;

	CODE:
		rc = git_oid_fromstr(&oid, git_ensure_pv(id, "id"));
		git_check_error(rc);

		repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		rc = git_annotated_commit_lookup(&commit,
			repo_ptr -> repository, &oid
		);
		if (rc == GIT_ENOTFOUND)
			XSRETURN_UNDEF;

		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, SvPVbyte_nolen(class), commit, SvRV(repo)
		);

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		git_annotated_commit_free(GIT_SV_TO_PTR(Rebase, self));
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
