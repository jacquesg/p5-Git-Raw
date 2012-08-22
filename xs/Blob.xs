MODULE = Git::Raw			PACKAGE = Git::Raw::Blob

SV *
lookup(class, repo, id)
	SV *class
	Repository repo
	SV *id

	CODE:
		STRLEN len;
		git_oid oid;
		git_object *o;

		int rc = git_oid_fromstrn(&oid, SvPVbyte(id, len), len);
		git_check_error(rc);

		rc = git_object_lookup_prefix(&o, repo, &oid, len, GIT_OBJ_BLOB);
		git_check_error(rc);

		RETVAL = git_obj_to_sv(o);

	OUTPUT: RETVAL

SV *
content(self)
	Blob self

	CODE:
		size_t len = git_blob_rawsize(self);
		RETVAL = newSVpv(git_blob_rawcontent(self), len);

	OUTPUT: RETVAL

void
DESTROY(self)
	Blob self

	CODE:
		git_blob_free(self);
