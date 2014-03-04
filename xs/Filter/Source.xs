MODULE = Git::Raw			PACKAGE = Git::Raw::Filter::Source


SV *
id(self)
	Filter_Source self

	CODE:
		RETVAL = git_oid_to_sv(git_filter_source_id(self));

	OUTPUT: RETVAL

SV *
path(self)
	Filter_Source self

	CODE:
		RETVAL = newSVpv(git_filter_source_path(self), 0);

	OUTPUT: RETVAL

SV *
file_mode(self)
	Filter_Source self

	CODE:
		RETVAL = newSViv(git_filter_source_filemode(self));

	OUTPUT: RETVAL

SV *
mode(self)
	Filter_Source self

	PREINIT:
		git_filter_mode_t mode;
		const char *result = NULL;

	CODE:
		mode = git_filter_source_mode(self);

		if (mode == GIT_FILTER_TO_WORKTREE)
			result = "to_worktree";
		else if (mode == GIT_FILTER_TO_ODB)
			result = "to_odb";

		RETVAL = newSVpv(result, 0);

	OUTPUT: RETVAL
