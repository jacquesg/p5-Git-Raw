MODULE = Git::Raw			PACKAGE = Git::Raw::TreeEntry

SV *
id(self)
	TreeEntry self

	PREINIT:
		const git_oid *oid;

	CODE:
		oid = git_tree_entry_id(self);
		RETVAL = git_oid_to_sv((git_oid *) oid);

	OUTPUT: RETVAL

SV *
name(self)
	TreeEntry self

	PREINIT:
		const char *name;

	CODE:
		name = git_tree_entry_name(self);
		RETVAL = newSVpv(name, 0);

	OUTPUT: RETVAL

SV *
object(self)
	SV *self

	PREINIT:
		int rc;
		Repository repo;
		git_object *obj;

	CODE:
		repo = INT2PTR(
			Repository,
			SvIV((SV *)xs_object_magic_get_struct(aTHX_ SvRV(self)))
		);

		rc = git_tree_entry_to_object(&obj, repo, GIT_SV_TO_PTR(TreeEntry, self));
		git_check_error(rc);

		RETVAL = git_obj_to_sv(obj, self);

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		git_tree_entry_free(GIT_SV_TO_PTR(TreeEntry, self));
		SvREFCNT_dec(xs_object_magic_get_struct(aTHX_ SvRV(self)));
