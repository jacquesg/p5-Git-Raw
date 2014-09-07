MODULE = Git::Raw			PACKAGE = Git::Raw::Index::Conflict

SV *
ours(self)
	Index_Conflict self

	CODE:
		RETVAL = &PL_sv_undef;

		if (self -> ours)
			RETVAL = self -> ours;

	OUTPUT: RETVAL

SV *
ancestor(self)
	Index_Conflict self

	CODE:
		RETVAL = &PL_sv_undef;

		if (self -> ancestor)
			RETVAL = self -> ancestor;

	OUTPUT: RETVAL

SV *
theirs(self)
	Index_Conflict self

	CODE:
		RETVAL = &PL_sv_undef;

		if (self -> theirs)
			RETVAL = self -> theirs;

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
