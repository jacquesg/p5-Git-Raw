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

SV *
upstream(self)
	SV *self

	PREINIT:
		int rc;

		Reference ref;

	CODE:
		rc = git_branch_upstream(&ref, GIT_SV_TO_PTR(Branch, self));
		if (rc == GIT_ENOTFOUND)
			XSRETURN_UNDEF;

		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Reference", ref, GIT_SV_TO_MAGIC(self)
		);

	OUTPUT: RETVAL

SV *
upstream_name(self)
	SV *self

	PREINIT:
		int rc;

		Reference ref;
		git_buf buf = GIT_BUF_INIT_CONST(NULL, 0);

	CODE:
		RETVAL = &PL_sv_undef;

		ref = GIT_SV_TO_PTR(Reference, self);

		rc = git_branch_upstream_name(
				&buf,
				git_reference_owner(ref),
				git_reference_name(ref)
		);

		if (rc == GIT_OK)
			RETVAL = newSVpv(buf.ptr, buf.size);

		git_buf_free(&buf);
		git_check_error(rc);

	OUTPUT: RETVAL

SV *
remote_name(self)
	SV *self

	PREINIT:
		int rc;

		Reference ref;
		git_buf upstream = GIT_BUF_INIT_CONST(NULL, 0);
		git_buf remote = GIT_BUF_INIT_CONST(NULL, 0);

	CODE:
		RETVAL = &PL_sv_undef;

		ref = GIT_SV_TO_PTR(Reference, self);

		rc = git_branch_upstream_name(
				&upstream,
				git_reference_owner(ref),
				git_reference_name(ref)
		);

		if (rc == GIT_OK) {
			rc = git_branch_remote_name(
					&remote,
					git_reference_owner(ref),
					upstream.ptr);

			if (rc == GIT_OK)
				RETVAL = newSVpv(remote.ptr, remote.size);
		}

		git_buf_free(&upstream);
		git_buf_free(&remote);
		git_check_error(rc);

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
