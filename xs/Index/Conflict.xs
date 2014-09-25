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
			Index_Entry entry;
			Newxz(entry, 1, git_raw_index_entry);

			entry -> index_entry = (git_index_entry *) conflict -> ours;
			GIT_NEW_OBJ_WITH_MAGIC(
				RETVAL, "Git::Raw::Index::Entry",
				entry, GIT_SV_TO_MAGIC(self)
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
			Index_Entry entry;
			Newxz(entry, 1, git_raw_index_entry);

			entry -> index_entry = (git_index_entry *) conflict -> ancestor;
			GIT_NEW_OBJ_WITH_MAGIC(
				RETVAL, "Git::Raw::Index::Entry",
				entry, GIT_SV_TO_MAGIC(self)
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
			Index_Entry entry;
			Newxz(entry, 1, git_raw_index_entry);

			entry -> index_entry = (git_index_entry *) conflict -> theirs;
			GIT_NEW_OBJ_WITH_MAGIC(
				RETVAL, "Git::Raw::Index::Entry",
				entry, GIT_SV_TO_MAGIC(self)
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
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
		Safefree(conflict);
