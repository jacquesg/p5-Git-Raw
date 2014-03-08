MODULE = Git::Raw			PACKAGE = Git::Raw::Branch

BOOT:
{
	AV *isa = get_av("Git::Raw::Branch::ISA", 1);
	av_push(isa, newSVpv("Git::Raw::Reference", 0));
}

SV *
create(class, repo, name, target)
	SV *class
	SV *repo
	SV *name
	SV *target

	PREINIT:
		int rc;

		Commit obj;
		Reference ref;
		Signature sig;

	INIT:
		obj = (Commit) git_sv_to_obj(target);

	CODE:
		rc = git_signature_default(&sig, GIT_SV_TO_PTR(Repository, repo));
		git_check_error(rc);

		rc = git_branch_create(
			&ref, GIT_SV_TO_PTR(Repository, repo),
			SvPVbyte_nolen(name), obj, 0, sig, NULL
		);

		git_signature_free(sig);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, SvPVbyte_nolen(class), ref, SvRV(repo)
		);

	OUTPUT: RETVAL

SV *
lookup(class, repo, name, is_local)
	SV *class
	SV *repo
	SV *name
	bool is_local

	PREINIT:
		int rc;
		Reference branch;

		git_branch_t type = is_local ?
			GIT_BRANCH_LOCAL     :
			GIT_BRANCH_REMOTE    ;

	CODE:
		rc = git_branch_lookup(
			&branch, GIT_SV_TO_PTR(Repository, repo),
			SvPVbyte_nolen(name), type
		);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, SvPVbyte_nolen(class), branch, SvRV(repo)
		);

	OUTPUT: RETVAL

void
move(self, name, force)
	SV *self
	SV *name
	bool force

	PREINIT:
		int rc;

		Signature sig;

		Branch new_branch;
		Branch old_branch;

	INIT:
		old_branch = GIT_SV_TO_PTR(Branch, self);

	CODE:
		rc = git_signature_default(&sig, git_reference_owner(
			GIT_SV_TO_PTR(Reference, self)));
		git_check_error(rc);

		rc = git_branch_move(
			&new_branch, old_branch, SvPVbyte_nolen(name), force,
			sig, NULL
		);

		git_signature_free(sig);
		git_check_error(rc);

Reference
upstream(self)
	Branch self

	PREINIT:
		int rc;

		Reference ref;

	CODE:
		rc = git_branch_upstream(&ref, self);
		git_check_error(rc);

		RETVAL = ref;

	OUTPUT: RETVAL

SV *
is_head(self)
	Branch self

	CODE:
		RETVAL = newSViv(git_branch_is_head(self));

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		git_reference_free(GIT_SV_TO_PTR(Reference, self));
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
