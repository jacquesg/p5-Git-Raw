MODULE = Git::Raw			PACKAGE = Git::Raw::Index::Entry

SV *
id(self)
	Index_Entry self

	CODE:
		RETVAL = git_oid_to_sv(&self -> index_entry -> id);

	OUTPUT: RETVAL

SV *
path(self)
	Index_Entry self

	CODE:
		RETVAL = newSVpv(self -> index_entry -> path, 0);

	OUTPUT: RETVAL

SV *
size(self)
	Index_Entry self

	CODE:
		RETVAL = newSVuv((size_t) self -> index_entry -> file_size);

	OUTPUT: RETVAL

SV *
stage(self)
	Index_Entry self

	CODE:
		RETVAL = newSViv(git_index_entry_stage(self -> index_entry));

	OUTPUT: RETVAL

SV *
clone(self, path)
	SV *self
	const char *path

	PREINIT:
		Index_Entry old_entry, new_entry = NULL;

	CODE:
		old_entry = GIT_SV_TO_PTR(Index::Entry, self);

		Newxz(new_entry, 1, git_raw_index_entry);
		new_entry -> owned = 1;
		new_entry -> index_entry =
			git_index_entry_dup(old_entry -> index_entry, path);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Index::Entry",
			new_entry, GIT_SV_TO_MAGIC(self)
		);

	OUTPUT: RETVAL

SV *
blob(self)
	SV *self

	PREINIT:
		int rc;
		Index_Entry entry;

		SV *repo;
		Repository repo_ptr;

		Blob blob;

	CODE:
		entry = GIT_SV_TO_PTR(Index::Entry, self);

		repo = GIT_SV_TO_MAGIC(self);
		repo_ptr = INT2PTR(Repository, SvIV((SV *) repo));

		RETVAL = &PL_sv_undef;

		rc = git_blob_lookup(
			&blob, repo_ptr -> repository,
			&entry -> index_entry -> id
		);
		if (rc != GIT_ENOTFOUND) {
			git_check_error(rc);
			GIT_NEW_OBJ_WITH_MAGIC(
				RETVAL, "Git::Raw::Blob", blob, repo
			);
		}

	OUTPUT: RETVAL

void
DESTROY(self)
	SV* self

	PREINIT:
		Index_Entry entry;

	CODE:
		entry = GIT_SV_TO_PTR(Index::Entry, self);
		if (entry -> owned)
			git_index_entry_free(entry -> index_entry);

		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
		Safefree(entry);
