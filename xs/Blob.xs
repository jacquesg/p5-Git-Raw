MODULE = Git::Raw			PACKAGE = Git::Raw::Blob

SV *
create(class, repo, buffer)
	SV *class
	Repository repo
	SV *buffer

	CODE:
		Blob blob;
		STRLEN len;
		git_oid oid;
		const char *buf = SvPVbyte(buffer, len);

		int rc = git_blob_create_frombuffer(&oid, repo, buf, len);
		git_check_error(rc);

		rc = git_blob_lookup(&blob, repo, &oid);
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), blob);

	OUTPUT: RETVAL

SV *
lookup(class, repo, id)
	SV *class
	Repository repo
	SV *id

	CODE:
		git_oid oid;
		git_object *o;

		STRLEN len;
		const char *id_str = SvPVbyte(id, len);

		int rc = git_oid_fromstrn(&oid, id_str, len);
		git_check_error(rc);

		rc = git_object_lookup_prefix(&o, repo, &oid, len, GIT_OBJ_BLOB);
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), o);

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
	Blob self

	CODE:
		git_blob_free(self);
