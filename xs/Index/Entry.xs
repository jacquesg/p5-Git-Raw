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
			&blob, repo_ptr -> repository, &entry -> id
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

	CODE:
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
