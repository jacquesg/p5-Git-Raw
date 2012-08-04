MODULE = Git::Raw			PACKAGE = Git::Raw::Tree

void
DESTROY(self)
	Tree self

	CODE:
		git_tree_free(self);
