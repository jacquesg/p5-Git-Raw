MODULE = Git::Raw			PACKAGE = Git::Raw::Object

INCLUDE: const-xs-object.inc

SV *
lookup(class, repo, id)
	SV *class
	SV *repo
	SV *id

	PREINIT:
		int rc;

		git_oid oid;
		git_object *obj;

		STRLEN len;
		const char *id_str;

		Repository repo_ptr = NULL;

	CODE:
		id_str = git_ensure_pv_with_len(id, "id", &len);

		rc = git_oid_fromstrn(&oid, id_str, len);
		git_check_error(rc);

		repo_ptr = GIT_SV_TO_PTR(Repository, repo);
		rc = git_object_lookup_prefix(
			&obj, repo_ptr -> repository, &oid, len, GIT_OBJ_ANY
		);

		if (rc == GIT_ENOTFOUND)
			XSRETURN_UNDEF;

		git_check_error(rc);
		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Object",
			obj, repo
		);

	OUTPUT: RETVAL

SV *
type(self)
	Object self

	CODE:
		RETVAL = newSViv(git_object_type(self));

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		git_object_free(GIT_SV_TO_PTR(Object, self));
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));

