MODULE = Git::Raw			PACKAGE = Git::Raw::Tree

SV *
id(self)
	Tree self

	CODE:
		char out[41];
		const git_oid *oid = git_tree_id(self);

		git_oid_fmt(out, oid);
		out[40] = '\0';

		RETVAL = newSVpv(out, 0);

	OUTPUT: RETVAL

void
DESTROY(self)
	Tree self

	CODE:
		git_tree_free(self);
