MODULE = Git::Raw			PACKAGE = Git::Raw::Index

void
add(self, path)
	Index self
	SV *path

	CODE:
		const char *path_str = SvPVbyte_nolen(path);

		int rc = git_index_add_from_workdir(self, path_str);
		git_check_error(rc);

void
clear(self)
	Index self

	CODE:
		git_index_clear(self);

void
read(self)
	Index self

	CODE:
		int rc = git_index_read(self);
		git_check_error(rc);

void
write(self)
	Index self

	CODE:
		int rc = git_index_write(self);
		git_check_error(rc);

void
read_tree(self, tree)
	Index self
	Tree tree

	CODE:
		int rc = git_index_read_tree(self, tree);
		git_check_error(rc);

SV *
write_tree(self)
	Index self

	CODE:
		Tree tree;
		git_oid oid;

		int rc = git_index_write_tree(&oid, self);
		git_check_error(rc);

		RETVAL = git_oid_to_sv(&oid);

	OUTPUT: RETVAL

void
remove(self, path)
	Index self
	SV *path

	CODE:
		const char *path_str = SvPVbyte_nolen(path);

		int rc = git_index_remove(self, path_str, 0);
		git_check_error(rc);

void
DESTROY(self)
	Index self

	CODE:
		git_index_free(self);
