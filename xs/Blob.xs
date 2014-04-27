MODULE = Git::Raw			PACKAGE = Git::Raw::Blob

SV *
create(class, repo, buffer)
	SV *class
	SV *repo
	SV *buffer

	PREINIT:
		int rc;

		Blob blob;
		git_oid oid;

		STRLEN len;
		const char *buffer_str;

		Repository repo_ptr;

	PREINIT:
		buffer_str = git_ensure_pv_with_len(buffer, "buffer", &len);

	CODE:
		repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		rc = git_blob_create_frombuffer(&oid, repo_ptr, buffer_str, len);
		git_check_error(rc);

		rc = git_blob_lookup(&blob, repo_ptr, &oid);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, SvPVbyte_nolen(class), blob, repo
		);

	OUTPUT: RETVAL

SV *
lookup(class, repo, id)
	SV *class
	SV *repo
	SV *id

	PREINIT:
		int rc;

		Blob blob;
		git_oid oid;

		STRLEN len;
		const char *id_str;

	PREINIT:
		id_str = git_ensure_pv_with_len(id, "id", &len);

	CODE:
		rc = git_oid_fromstrn(&oid, id_str, len);
		git_check_error(rc);

		rc = git_blob_lookup_prefix(&blob, GIT_SV_TO_PTR(Repository, repo), &oid, len);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, SvPVbyte_nolen(class), blob, repo
		);

	OUTPUT: RETVAL

SV *
content(self)
	Blob self

	PREINIT:
		git_off_t len;

	CODE:
		len = git_blob_rawsize(self);
		RETVAL = newSVpv(git_blob_rawcontent(self), (STRLEN) len);

	OUTPUT: RETVAL

SV *
size(self)
	Blob self

	CODE:
		RETVAL = newSVuv(git_blob_rawsize(self));

	OUTPUT: RETVAL

SV *
id(self)
	Blob self

	CODE:
		RETVAL = git_oid_to_sv(git_blob_id(self));

	OUTPUT: RETVAL

SV *
is_tree(self)
	SV *self

	CODE:
		RETVAL = newSVuv(0);

	OUTPUT: RETVAL

SV *
is_blob(self)
	SV *self

	CODE:
		RETVAL = newSVuv(1);

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		git_blob_free(GIT_SV_TO_PTR(Blob, self));
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
