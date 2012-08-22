MODULE = Git::Raw			PACKAGE = Git::Raw::Branch

Reference
create(class, repo, name, target)
	SV *class
	Repository repo
	SV *name
	SV *target

	CODE:
		Reference out;
		const char *name_str = SvPVbyte_nolen(name);

		git_object *obj = git_sv_to_obj(target);

		int rc = git_branch_create(&out, repo, name_str, obj, 0);
		git_check_error(rc);

		RETVAL = out;

	OUTPUT: RETVAL

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

void
delete(class, repo, name, is_local)
	SV *class
	Repository repo
	SV *name
	bool is_local;

	CODE:
		git_branch_t t = is_local ?
			GIT_BRANCH_LOCAL     :
			GIT_BRANCH_REMOTE    ;

		int rc = git_branch_delete(repo, SvPVbyte_nolen(name), t);
		git_check_error(rc);
