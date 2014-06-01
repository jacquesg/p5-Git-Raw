MODULE = Git::Raw			PACKAGE = Git::Raw::Tree::Entry

SV *
id(self)
	Tree_Entry self

	PREINIT:
		const git_oid *oid;

	CODE:
		oid = git_tree_entry_id(self);
		RETVAL = git_oid_to_sv((git_oid *) oid);

	OUTPUT: RETVAL

SV *
name(self)
	Tree_Entry self

	PREINIT:
		const char *name;

	CODE:
		name = git_tree_entry_name(self);
		RETVAL = newSVpv(name, 0);

	OUTPUT: RETVAL

SV *
file_mode(self)
	Tree_Entry self

	CODE:
		RETVAL = newSViv(git_tree_entry_filemode(self));

	OUTPUT: RETVAL

SV *
object(self)
	SV *self

	PREINIT:
		int rc;

		git_object *obj;
		Repository repo;

		Tree_Entry entry;

	CODE:
		repo = INT2PTR(Repository, SvIV((SV *) GIT_SV_TO_MAGIC(self)));

		entry = GIT_SV_TO_PTR(Tree::Entry, self);

		rc = git_tree_entry_to_object(&obj, repo, entry);
		git_check_error(rc);

		RETVAL = git_obj_to_sv(obj, GIT_SV_TO_MAGIC(self));

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		GIT_FREE_OBJ(Tree::Entry, self, git_tree_entry_free);
