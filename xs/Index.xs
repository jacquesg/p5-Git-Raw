MODULE = Git::Raw			PACKAGE = Git::Raw::Index

void
add(self, entry)
	Index self
	SV *entry

	PREINIT:
		int rc = 0;

	CODE:
		if (SvPOK(entry))
			rc = git_index_add_bypath(self, SvPVbyte_nolen(entry));
		else if (SvROK(entry))
			rc = git_index_add(self, GIT_SV_TO_PTR(Index::Entry, entry));

		git_check_error(rc);

void
clear(self)
	Index self

	CODE:
		git_index_clear(self);

void
read(self)
	Index self

	PREINIT:
		int rc;

	CODE:
		rc = git_index_read(self, 0);
		git_check_error(rc);

void
write(self)
	Index self

	PREINIT:
		int rc;

	CODE:
		rc = git_index_write(self);
		git_check_error(rc);

void
read_tree(self, tree)
	Index self
	Tree tree

	PREINIT:
		int rc;

	CODE:
		rc = git_index_read_tree(self, tree);
		git_check_error(rc);

SV *
write_tree(self)
	Index self

	PREINIT:
		int rc;
		git_oid oid;

	CODE:
		rc = git_index_write_tree(&oid, self);
		git_check_error(rc);

		RETVAL = git_oid_to_sv(&oid);

	OUTPUT: RETVAL

void
remove(self, path)
	Index self
	SV *path

	PREINIT:
		int rc;

	CODE:
		rc = git_index_remove(self, SvPVbyte_nolen(path), 0);
		git_check_error(rc);

void
conflict_cleanup(self)
	Index self

	CODE:
		git_index_conflict_cleanup(self);

SV *
has_conflicts(self)
	Index self

	CODE:
		RETVAL = newSViv(git_index_has_conflicts(self));

	OUTPUT: RETVAL

void
conflicts(self)
	SV *self

	PREINIT:
		int rc;

		git_index_conflict_iterator *iter;
		const git_index_entry *ancestor, *ours, *theirs;

		size_t num_conflicts = 0;

	PPCODE:
		rc = git_index_conflict_iterator_new(
			&iter, GIT_SV_TO_PTR(Index, self)
		);
		git_check_error(rc);

		while ((rc = git_index_conflict_next(
			&ancestor, &ours, &theirs, iter)) == GIT_OK) {
			HV *entries = newHV();
			SV *entry;

			GIT_NEW_OBJ_WITH_MAGIC(
				entry, "Git::Raw::Index::Entry",
				(Index_Entry) ancestor, SvRV(self)
			);

			hv_stores(entries, "ancestor", entry);

			GIT_NEW_OBJ_WITH_MAGIC(
				entry, "Git::Raw::Index::Entry",
				(Index_Entry) ours, SvRV(self)
			);

			hv_stores(entries, "ours", entry);

			GIT_NEW_OBJ_WITH_MAGIC(
				entry, "Git::Raw::Index::Entry",
				(Index_Entry) theirs, SvRV(self)
			);

			hv_stores(entries, "theirs", entry);
			num_conflicts++;

			EXTEND(SP, 1);
			PUSHs(sv_2mortal(newRV_noinc((SV *) entries)));
		}

		git_index_conflict_iterator_free(iter);

		if (rc != GIT_ITEROVER)
			git_check_error(rc);

		XSRETURN(num_conflicts);

void
DESTROY(self)
	SV* self

	CODE:
		git_index_free(GIT_SV_TO_PTR(Index, self));
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
