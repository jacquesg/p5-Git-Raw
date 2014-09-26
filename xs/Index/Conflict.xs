MODULE = Git::Raw			PACKAGE = Git::Raw::Index::Conflict

SV *
ours(self)
	SV *self

	PREINIT:
		Index_Conflict conflict;

	CODE:
		conflict = GIT_SV_TO_PTR(Index::Conflict, self);

		RETVAL = &PL_sv_undef;

		if (conflict -> ours) {
			RETVAL = git_index_entry_to_sv(
				conflict -> ours, NULL, GIT_SV_TO_MAGIC(self)
			);
		}

	OUTPUT: RETVAL

SV *
ancestor(self)
	SV *self

	PREINIT:
		Index_Conflict conflict;

	CODE:
		conflict = GIT_SV_TO_PTR(Index::Conflict, self);

		RETVAL = &PL_sv_undef;

		if (conflict -> ancestor) {
			RETVAL = git_index_entry_to_sv(
				conflict -> ancestor, NULL, GIT_SV_TO_MAGIC(self)
			);
		}

	OUTPUT: RETVAL

SV *
theirs(self)
	SV *self

	PREINIT:
		Index_Conflict conflict;

	CODE:
		conflict = GIT_SV_TO_PTR(Index::Conflict, self);

		RETVAL = &PL_sv_undef;

		if (conflict -> theirs) {
			RETVAL = git_index_entry_to_sv(
				conflict -> theirs, NULL, GIT_SV_TO_MAGIC(self)
			);
		}

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	PREINIT:
		Index_Conflict conflict;

	CODE:
		conflict = GIT_SV_TO_PTR(Index::Conflict, self);
		git_index_entry_free(conflict -> ours);
		git_index_entry_free(conflict -> theirs);
		git_index_entry_free(conflict -> ancestor);

		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
		Safefree(conflict);
