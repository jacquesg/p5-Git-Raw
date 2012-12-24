MODULE = Git::Raw			PACKAGE = Git::Raw::Blob

SV *
create(class, repo, buffer)
	SV *class
	SV *repo
	SV *buffer

	CODE:
		Blob blob;
		git_oid oid;

		STRLEN len;
		const char *buffer_str = SvPVbyte(buffer, len);
		Repository repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		int rc = git_blob_create_frombuffer(&oid, repo_ptr, buffer_str, len);
		git_check_error(rc);

		rc = git_blob_lookup(&blob, repo_ptr, &oid);
		git_check_error(rc);

		GIT_NEW_OBJ_DOUBLE(RETVAL, class, blob, repo);

	OUTPUT: RETVAL

SV *
lookup(class, repo, id)
	SV *class
	SV *repo
	SV *id

	CODE:
		git_oid oid;
		git_object *obj;
		Repository repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		STRLEN len;
		const char *id_str = SvPVbyte(id, len);

		int rc = git_oid_fromstrn(&oid, id_str, len);
		git_check_error(rc);

		rc = git_object_lookup_prefix(&obj, repo_ptr, &oid, len, GIT_OBJ_BLOB);
		git_check_error(rc);

		GIT_NEW_OBJ_DOUBLE(RETVAL, class, obj, repo);

	OUTPUT: RETVAL

SV *
content(self)
	Blob self

	CODE:
		size_t len = git_blob_rawsize(self);
		RETVAL = newSVpv(git_blob_rawcontent(self), len);

	OUTPUT: RETVAL

size_t
size(self)
	Blob self

	CODE:
		size_t len = git_blob_rawsize(self);
		RETVAL = len;

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		git_blob_free(GIT_SV_TO_PTR(Blob, self));
		SvREFCNT_dec(xs_object_magic_get_struct(aTHX_ SvRV(self)));
