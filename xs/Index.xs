MODULE = Git::Raw			PACKAGE = Git::Raw::Index

void
add(self, path)
	Index self
	SV *path

	CODE:
		STRLEN len;
		const char *path_str = SvPVbyte(path, len);

		int rc = git_index_add(self, path_str, 0);
		git_check_error(rc);

void
append(self, path)
	Index self
	SV *path

	CODE:
		STRLEN len;
		const char *path_str = SvPVbyte(path, len);

		int rc = git_index_append(self, path_str, 0);
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
uniq(self)
	Index self

	CODE:
		git_index_uniq(self);

void
write(self)
	Index self

	CODE:
		int rc = git_index_write(self);
		git_check_error(rc);

SV *
write_tree(self)
	Index self

	CODE:
		Tree tree;
		git_oid oid;
		char out[41];

		int rc = git_tree_create_fromindex(&oid, self);
		git_check_error(rc);

		git_oid_fmt(out, &oid);
		out[40] = '\0';

		RETVAL = newSVpv(out, 0);

	OUTPUT: RETVAL

void
DESTROY(self)
	Index self

	CODE:
		git_index_free(self);
