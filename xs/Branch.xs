MODULE = Git::Raw			PACKAGE = Git::Raw::Branch

Reference
lookup(class, repo, name, is_local)
	SV *class
	Repository repo
	SV *name
	bool is_local

	CODE:
		Reference b;
		git_branch_t t = is_local ?
			GIT_BRANCH_LOCAL     :
			GIT_BRANCH_REMOTE    ;

		int rc = git_branch_lookup(&b, repo, SvPVbyte_nolen(name), t);
		git_check_error(rc);

		RETVAL = b;

	OUTPUT: RETVAL
