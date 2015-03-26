MODULE = Git::Raw			PACKAGE = Git::Raw::Note

SV *
create(class, repo, commitish, content, ...)
	const char *class
	SV *repo
	SV *commitish
	SV *content

	PROTOTYPE: $$$$;$$
	PREINIT:
		int rc, force = 0;

		Note note;
		Repository repo_ptr;
		Signature sig;

		git_oid oid;

		const char *ref_name = NULL;

	CODE:
		if (items >= 5 && SvOK(ST(4)))
			ref_name = git_ensure_pv(ST(4), "refname");

		if (items >= 6)
			force = (int) git_ensure_iv(ST(5), "force");

		repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		rc = git_signature_default(&sig, repo_ptr -> repository);
		git_check_error(rc);

		rc = git_note_create(NULL, repo_ptr -> repository, ref_name, sig, sig,
			git_sv_to_commitish(repo_ptr -> repository, commitish, &oid),
			git_ensure_pv(content, "content"), force
		);
		git_signature_free(sig);
		git_check_error(rc);

		rc = git_note_read(
			&note, repo_ptr -> repository, ref_name, &oid
		);
		git_check_error(rc);
		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, class, note, SvRV(repo)
		);

	OUTPUT: RETVAL

SV *
read(class, repo, commitish, ...)
	const char *class
	SV *repo
	SV *commitish

	PROTOTYPE: $$$;$
	PREINIT:
		int rc;

		Note note;
		Repository repo_ptr;

		git_oid oid;

		const char *ref_name = NULL;

	CODE:
		if (items == 4)
			ref_name = git_ensure_pv(ST(3), "refname");

		repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		rc = git_note_read(
			&note, repo_ptr -> repository, ref_name,
			git_sv_to_commitish(repo_ptr -> repository, commitish, &oid)
		);

		RETVAL = &PL_sv_undef;
		if (rc != GIT_ENOTFOUND) {
			git_check_error(rc);

			GIT_NEW_OBJ_WITH_MAGIC(
				RETVAL, "Git::Raw::Note", note, SvRV(repo)
			);
		}

	OUTPUT: RETVAL

void
remove(class, repo, commitish, ...)
	const char *class
	SV *repo
	SV *commitish

	PROTOTYPE: $$$;$
	PREINIT:
		int rc;

		Repository repo_ptr;
		Signature sig;

		git_oid oid;

		const char *ref_name = NULL;

	CODE:
		if (items == 4)
			ref_name = git_ensure_pv(ST(3), "refname");

		repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		rc = git_signature_default(&sig, repo_ptr -> repository);
		git_check_error(rc);

		rc = git_note_remove(
			repo_ptr -> repository, ref_name,
			sig, sig, git_sv_to_commitish(repo_ptr -> repository, commitish, &oid)
		);
		git_signature_free(sig);

		if (rc != GIT_ENOTFOUND)
			git_check_error(rc);

SV *
id(self)
	Note self

	CODE:
		RETVAL = git_oid_to_sv(git_note_id(self));

	OUTPUT: RETVAL

SV *
message(self)
	Note self

	CODE:
		RETVAL = newSVpv(git_note_message(self), 0);

	OUTPUT: RETVAL

Signature
author(self)
	Note self

	PREINIT:
		int rc;
		Signature a, r;

	CODE:
		a = (Signature) git_note_author(self);
		rc = git_signature_dup(&r, a);
		git_check_error(rc);

		RETVAL = r;

	OUTPUT: RETVAL

Signature
committer(self)
	Note self

	PREINIT:
		int rc;
		Signature c, r;

	CODE:
		c = (Signature) git_note_committer(self);
		rc = git_signature_dup(&r, c);
		git_check_error(rc);

		RETVAL = r;

	OUTPUT: RETVAL

SV *
default_ref(class, repo)
	SV *class
	SV *repo

	PREINIT:
		int rc;

		Repository repo_ptr;
		Reference ref;

		git_buf ref_name = GIT_BUF_INIT_CONST(NULL, 0);

	CODE:
		repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		rc = git_note_default_ref(&ref_name, repo_ptr -> repository);
		git_check_error(rc);

		rc = git_reference_lookup(
			&ref, repo_ptr -> repository, ref_name.ptr
		);
		git_buf_free(&ref_name);

		RETVAL = &PL_sv_undef;
		if (rc != GIT_ENOTFOUND) {
			git_check_error(rc);

			GIT_NEW_OBJ_WITH_MAGIC(
				RETVAL, "Git::Raw::Reference", ref, SvRV(repo)
			);
		}

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		git_note_free(GIT_SV_TO_PTR(Note, self));
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
