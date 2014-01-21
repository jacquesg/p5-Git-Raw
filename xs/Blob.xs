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

	CODE:
		repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		buffer_str = SvPVbyte(buffer, len);
		rc = git_blob_create_frombuffer(&oid, repo_ptr, buffer_str, len);
		git_check_error(rc);

		rc = git_blob_lookup(&blob, repo_ptr, &oid);
		git_check_error(rc);

		GIT_NEW_OBJ(RETVAL, SvPVbyte_nolen(class), blob, SvRV(repo));

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

	CODE:
		id_str = SvPVbyte(id, len);
		rc = git_oid_fromstrn(&oid, id_str, len);
		git_check_error(rc);

		rc = git_blob_lookup_prefix(&blob, GIT_SV_TO_PTR(Repository, repo), &oid, len);
		git_check_error(rc);

		GIT_NEW_OBJ(RETVAL, SvPVbyte_nolen(class), blob, SvRV(repo));

	OUTPUT: RETVAL

SV *
content(self)
	Blob self

	PREINIT:
		git_off_t len;

	CODE:
		len = git_blob_rawsize(self);
		RETVAL = newSVpv(git_blob_rawcontent(self), len);

	OUTPUT: RETVAL

SV *
size(self)
	Blob self

	PREINIT:
		git_off_t len;

	CODE:
		len = git_blob_rawsize(self);
		RETVAL = newSViv(len);

	OUTPUT: RETVAL

SV *
id(self)
	Blob self

	PREINIT:
		const git_oid *oid;

	CODE:
		oid = git_blob_id(self);
		RETVAL = git_oid_to_sv((git_oid *) oid);

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
		SvREFCNT_dec(xs_object_magic_get_struct(aTHX_ SvRV(self)));
