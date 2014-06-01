MODULE = Git::Raw::Diff			PACKAGE = Git::Raw::Diff::File

SV *
id(self)
	Diff_File self

	CODE:
		RETVAL = git_oid_to_sv(&self -> id);

	OUTPUT: RETVAL

SV *
path(self)
	Diff_File self

	CODE:
		RETVAL = newSVpv(self -> path, 0);

	OUTPUT: RETVAL

SV *
size(self)
	Diff_File self

	CODE:
		RETVAL = newSVuv((size_t) self -> size);

	OUTPUT: RETVAL

SV *
flags(self)
	Diff_File self

	PREINIT:
		AV *flags = newAV();

	CODE:
		if (self -> flags & GIT_DIFF_FLAG_BINARY)
			av_push(flags, newSVpv("binary", 0));
		if (self -> flags & GIT_DIFF_FLAG_VALID_ID)
			av_push(flags, newSVpv("valid_id", 0));

		RETVAL = newRV_noinc((SV *) flags);

	OUTPUT: RETVAL

SV *
mode(self)
	Diff_File self

	PREINIT:
		const char *mode = NULL;

	CODE:
		if (self -> mode == GIT_FILEMODE_NEW)
			mode = "new";
		else if (self -> mode == GIT_FILEMODE_TREE)
			mode = "tree";
		else if (self -> mode == GIT_FILEMODE_BLOB)
			mode = "blob";
		else if (self -> mode == GIT_FILEMODE_BLOB_EXECUTABLE)
			mode = "blob_executable";
		else if (self -> mode == GIT_FILEMODE_LINK)
			mode = "link";
		else if (self -> mode == GIT_FILEMODE_COMMIT)
			mode = "commit";

		RETVAL = newSVpv (mode, 0);

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		GIT_FREE_OBJ(Diff::File, self, dummy_free);
