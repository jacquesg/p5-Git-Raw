MODULE = Git::Raw			PACKAGE = Git::Raw::Blame::Hunk

SV *
lines_in_hunk(self)
	Blame_Hunk self

	CODE:
		RETVAL = newSVuv(self -> lines_in_hunk);

	OUTPUT: RETVAL

SV *
final_commit_id(self)
	Blame_Hunk self

	CODE:
		RETVAL = git_oid_to_sv(&self -> final_commit_id);

	OUTPUT: RETVAL

SV *
final_start_line_number(self)
	Blame_Hunk self

	CODE:
		RETVAL = newSVuv(self -> final_start_line_number);

	OUTPUT: RETVAL

SV *
orig_commit_id(self)
	Blame_Hunk self

	CODE:
		RETVAL = git_oid_to_sv(&self -> orig_commit_id);

	OUTPUT: RETVAL

SV *
orig_start_line_number(self)
	Blame_Hunk self

	CODE:
		RETVAL = newSVuv(self -> orig_start_line_number);

	OUTPUT: RETVAL

SV *
orig_path(self)
	Blame_Hunk self

	CODE:
		RETVAL = newSVpv(self -> orig_path, 0);

	OUTPUT: RETVAL

SV *
boundary(self)
	Blame_Hunk self

	CODE:
		RETVAL = newSViv(self -> boundary);

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		GIT_FREE_OBJ(Blame::Hunk, self, dummy_free);
