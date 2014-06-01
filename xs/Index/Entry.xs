MODULE = Git::Raw			PACKAGE = Git::Raw::Index::Entry

SV *
id(self)
	Index_Entry self

	CODE:
		RETVAL = git_oid_to_sv(&self -> id);

	OUTPUT: RETVAL

SV *
path(self)
	Index_Entry self

	CODE:
		RETVAL = newSVpv(self -> path, 0);

	OUTPUT: RETVAL

SV *
size(self)
	Index_Entry self

	CODE:
		RETVAL = newSVuv((size_t) self -> file_size);

	OUTPUT: RETVAL

SV *
stage(self)
	Index_Entry self

	CODE:
		RETVAL = newSViv(git_index_entry_stage(self));

	OUTPUT: RETVAL

void
DESTROY(self)
	SV* self

	CODE:
		GIT_FREE_OBJ(Index::Entry, self, dummy_free);
