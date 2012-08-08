MODULE = Git::Raw			PACKAGE = Git::Raw::Blob

SV *
content(self)
	Blob self

	CODE:
		size_t len = git_blob_rawsize(self);
		RETVAL = newSVpv(git_blob_rawcontent(self), len);

	OUTPUT: RETVAL

void
DESTROY(self)
	Blob self

	CODE:
		git_blob_free(self);
