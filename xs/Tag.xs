MODULE = Git::Raw			PACKAGE = Git::Raw::Tag

void
DESTROY(self)
	Tag self

	CODE:
		git_tag_free(self);
