MODULE = Git::Raw			PACKAGE = Git::Raw::Diff::Delta

SV *
status(self)
	Diff_Delta self

	PREINIT:
		const char *status = NULL;

	CODE:
		if (self -> status == GIT_DELTA_UNMODIFIED)
			status = "unmodified";
		else if (self -> status == GIT_DELTA_ADDED)
			status = "added";
		else if (self -> status == GIT_DELTA_DELETED)
			status = "deleted";
		else if (self -> status == GIT_DELTA_MODIFIED)
			status = "modified";
		else if (self -> status == GIT_DELTA_RENAMED)
			status = "renamed";
		else if (self -> status == GIT_DELTA_COPIED)
			status = "copied";
		else if (self -> status == GIT_DELTA_IGNORED)
			status = "ignored";
		else if (self -> status == GIT_DELTA_UNTRACKED)
			status = "untracked";
		else if (self -> status == GIT_DELTA_TYPECHANGE)
			status = "type_change";
		else if (self -> status == GIT_DELTA_UNREADABLE)
			status = "unreadable";
		else if (self -> status == GIT_DELTA_CONFLICTED)
			status = "conflicted";

		RETVAL = newSVpv (status, 0);

	OUTPUT: RETVAL

SV *
flags(self)
	Diff_Delta self

	PREINIT:
		AV *flags = newAV();

	CODE:
		if (self -> flags & GIT_DIFF_FLAG_BINARY)
			av_push(flags, newSVpv("binary", 0));
		if (self -> flags & GIT_DIFF_FLAG_VALID_ID)
			av_push(flags, newSVpv("valid_id", 0));

		RETVAL = newRV_noinc((SV *) flags);

	OUTPUT: RETVAL

SV *
similarity(self)
	Diff_Delta self

	CODE:
		RETVAL = newSVuv(self -> similarity);

	OUTPUT: RETVAL

SV *
file_count(self)
	Diff_Delta self

	CODE:
		RETVAL = newSVuv(self -> nfiles);

	OUTPUT: RETVAL

SV *
old_file(self)
	SV *self

	PREINIT:
		Diff_Delta self_ptr;

	CODE:
		self_ptr = GIT_SV_TO_PTR(Diff::Delta, self);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Diff::File", &self_ptr -> old_file, SvRV(self));

	OUTPUT: RETVAL

SV *
new_file(self)
	SV *self

	PREINIT:
		Diff_Delta self_ptr;

	CODE:
		self_ptr = GIT_SV_TO_PTR(Diff::Delta, self);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Diff::File", &self_ptr -> new_file, SvRV(self));

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
