MODULE = Git::Raw			PACKAGE = Git::Raw::Merge::File::Result

SV *
automergeable(self)
	Merge_File_Result self

	CODE:
		RETVAL = newSViv((int) self -> automergeable);

	OUTPUT: RETVAL

SV *
content(self)
	Merge_File_Result self

	CODE:
		RETVAL = newSVpv(self -> ptr, self -> len);

	OUTPUT: RETVAL

SV *
path(self)
	Merge_File_Result self

	CODE:
		RETVAL = &PL_sv_undef;

		if (self -> path)
			RETVAL = newSVpv(self -> path, 0);

	OUTPUT: RETVAL

void
DESTROY(self)
	Merge_File_Result self

	CODE:
		git_merge_file_result_free(self);
		Safefree(self);
