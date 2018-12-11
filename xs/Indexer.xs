MODULE = Git::Raw			PACKAGE = Git::Raw::Indexer

SV *
new(class, path, odb)
	SV *class
	SV *path
	SV *odb

	PREINIT:
		int rc;
		Indexer indexer;

	CODE:
		rc = git_indexer_new(&indexer, git_ensure_pv(path, "path"),
			0, GIT_SV_TO_PTR(Odb, odb), NULL);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Indexer", indexer, SvRV(odb)
		);

	OUTPUT: RETVAL

void
append(self, data, progress)
	Indexer self
	SV *data
	TransferProgress progress

	PREINIT:
		int rc;
		const char *d;
		STRLEN len;

	CODE:
		d = git_ensure_pv_with_len(data, "data", &len);
		rc = git_indexer_append(self, d, len, progress);
		git_check_error(rc);

void
commit(self, progress)
	Indexer self
	TransferProgress progress

	PREINIT:
		int rc;

	CODE:
		rc = git_indexer_commit(self, progress);
		git_check_error(rc);

SV *
hash(self)
	Indexer self

	CODE:
		RETVAL = git_oid_to_sv(git_indexer_hash(self));

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		git_indexer_free(GIT_SV_TO_PTR(Indexer, self));
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));

