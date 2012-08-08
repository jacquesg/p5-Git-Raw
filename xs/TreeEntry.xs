MODULE = Git::Raw			PACKAGE = Git::Raw::TreeEntry

SV *
id(self)
	TreeEntry self

	CODE:
		char out[41];
		const git_oid *oid = git_tree_entry_id(self);

		git_oid_fmt(out, oid);
		out[40] = '\0';

		RETVAL = newSVpv(out, 0);

	OUTPUT: RETVAL

SV *
name(self)
	TreeEntry self

	CODE:
		const char *name = git_tree_entry_name(self);
		RETVAL = newSVpv(name, 0);

	OUTPUT: RETVAL

SV *
object(self, repo)
	TreeEntry self
	Repository repo

	CODE:
		git_object *o;

		int rc = git_tree_entry_to_object(&o, repo, self);
		git_check_error(rc);

		RETVAL = git_obj_to_sv(o);

	OUTPUT: RETVAL
