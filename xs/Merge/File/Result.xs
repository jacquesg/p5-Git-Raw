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
	SV *self

	PREINIT:
		Merge_File_Result result;

	CODE:
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));

		result = GIT_SV_TO_PTR(Merge::File::Result, self);
		git_merge_file_result_free(result);
		Safefree(result);

