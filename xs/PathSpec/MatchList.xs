MODULE = Git::Raw			PACKAGE = Git::Raw::PathSpec::MatchList

SV *
count(self)
	PathSpec_MatchList self;

	CODE:
		RETVAL = newSVuv(git_pathspec_match_list_entrycount(self));

	OUTPUT: RETVAL

void
entries(self)
	PathSpec_MatchList self;

	PREINIT:
		size_t i, count;

	PPCODE:
		count = git_pathspec_match_list_entrycount(self);
		EXTEND(SP, count);

		for (i = 0; i < count; ++i) {
			SV *path = newSVpv(git_pathspec_match_list_entry(self, i), 0);
			PUSHs(sv_2mortal(path));
		}

		XSRETURN(count);

SV *
failed_count(self)
	PathSpec_MatchList self;

	CODE:
		RETVAL = newSVuv(git_pathspec_match_list_failed_entrycount(self));

	OUTPUT: RETVAL

void
failed_entries(self)
	PathSpec_MatchList self;

	PREINIT:
		size_t i, count;

	PPCODE:
		count = git_pathspec_match_list_failed_entrycount(self);
		EXTEND(SP, count);

		for (i = 0; i < count; ++i) {
			SV *path = newSVpv(git_pathspec_match_list_failed_entry(self, i), 0);
			PUSHs(sv_2mortal(path));
		}

		XSRETURN(count);

void
DESTROY(self)
	SV *self

	PREINIT:
		PathSpec_MatchList list;

	CODE:
		list = GIT_SV_TO_PTR(PathSpec::MatchList, self);
		git_pathspec_match_list_free(list);
