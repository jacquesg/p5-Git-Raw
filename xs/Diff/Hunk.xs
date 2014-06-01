MODULE = Git::Raw			PACKAGE = Git::Raw::Diff::Hunk

SV *
old_start(self)
	Diff_Hunk self

	CODE:
		RETVAL = newSVuv(self -> old_start);

	OUTPUT: RETVAL

SV *
old_lines(self)
	Diff_Hunk self

	CODE:
		RETVAL = newSVuv(self -> old_lines);

	OUTPUT: RETVAL

SV *
new_start(self)
	Diff_Hunk self

	CODE:
		RETVAL = newSVuv(self -> new_start);

	OUTPUT: RETVAL

SV *
new_lines(self)
	Diff_Hunk self

	CODE:
		RETVAL = newSVuv(self -> new_lines);

	OUTPUT: RETVAL

SV *
header(self)
	Diff_Hunk self

	PREINIT:
		size_t header_len = 0;
		const char *header = NULL;

	CODE:
		header_len = self -> header_len;
		header = self -> header;

		for (header_len = self -> header_len; header_len != 0; --header_len) {
			if (header[header_len-1] != '\r' &&
				header[header_len-1] != '\n')
				break;
		}

		RETVAL = newSVpv(header, header_len);

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		GIT_FREE_OBJ(Diff::Hunk, self, dummy_free);
