MODULE = Git::Raw			PACKAGE = Git::Raw::Branch

BOOT:
{
	AV *isa = perl_get_av("Git::Raw::Branch::ISA",1);
	av_push(isa, newSVpv("Git::Raw::Reference", 0));
}

SV *
create(class, repo, name, target)
	SV *class
	SV *repo
	SV *name
	SV *target

	CODE:
		Reference ref;
		Commit obj = (Commit) git_sv_to_obj(target);

		int rc = git_branch_create(
			&ref, GIT_SV_TO_PTR(Repository, repo),
			SvPVbyte_nolen(name), obj, 0
		);
		git_check_error(rc);

		GIT_NEW_OBJ(RETVAL, SvPVbyte_nolen(class), ref, SvRV(repo));

	OUTPUT: RETVAL

SV *
lookup(class, repo, name, is_local)
	SV *class
	SV *repo
	SV *name
	bool is_local

	CODE:
		Reference branch;

		git_branch_t type = is_local ?
			GIT_BRANCH_LOCAL     :
			GIT_BRANCH_REMOTE    ;

		int rc = git_branch_lookup(
			&branch, GIT_SV_TO_PTR(Repository, repo),
			SvPVbyte_nolen(name), type
		);
		git_check_error(rc);

		GIT_NEW_OBJ(RETVAL, SvPVbyte_nolen(class), branch, SvRV(repo));

	OUTPUT: RETVAL

void
move(self, name, force)
	SV *self
	SV *name
	bool force

	CODE:
		Branch old_branch = GIT_SV_TO_PTR(Branch, self),
		       new_branch;

		int rc = git_branch_move(
			&new_branch, old_branch, SvPVbyte_nolen(name), force
		);
		git_check_error(rc);

Reference
upstream(self)
	Branch self

	CODE:
		Reference ref;

		int rc = git_branch_upstream(&ref, self);
		git_check_error(rc);

		RETVAL = ref;

	OUTPUT: RETVAL

SV *
is_head(self)
	Branch self

	CODE:
		RETVAL = newSViv(git_branch_is_head(self));

	OUTPUT: RETVAL
