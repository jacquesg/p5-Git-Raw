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
write_tree(self, ...)
	Index self

	PROTOTYPE: $;$
	PREINIT:
		int rc;
		git_oid oid;

	CODE:
		if (items == 2) {
			rc = git_index_write_tree_to(
				&oid, self, GIT_SV_TO_PTR(Repository, ST(1))
			);
		} else {
			rc = git_index_write_tree(&oid, self);
		}
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
checkout(self, ...)
	SV *self

	PROTOTYPE: $;$
	PREINIT:
		int rc;

		SV *repo;
		Repository repo_ptr;

		git_checkout_options checkout_opts = GIT_CHECKOUT_OPTIONS_INIT;

	CODE:
		repo = GIT_SV_TO_MAGIC(self);
		repo_ptr = INT2PTR(Repository, SvIV((SV *) repo));

		if (items == 2) {
			git_hv_to_checkout_opts((HV *) SvRV(ST(1)), &checkout_opts);
		}

		rc = git_checkout_index(
			repo_ptr,
			GIT_SV_TO_PTR(Index, self),
			&checkout_opts
		);
		git_check_error(rc);

void
entries(self)
	SV *self

	PREINIT:
		size_t i, count;

		SV *repo;

		Index index_ptr = NULL;

	PPCODE:
		index_ptr = GIT_SV_TO_PTR(Index, self);
		count = git_index_entrycount(index_ptr);

		if (count > 0) {
			EXTEND(SP, count);

			repo = GIT_SV_TO_MAGIC(self);

			for (i = 0; i < count; ++i) {
				const git_index_entry *e =
					git_index_get_byindex(index_ptr, i);

				if (e != NULL) {
					SV *entry = NULL;
					GIT_NEW_OBJ_WITH_MAGIC(
						entry, "Git::Raw::Index::Entry",
						(Index_Entry) e, repo
					);
					PUSHs(sv_2mortal(entry));
				}
			}
		}

		XSRETURN(count);

void
add_conflict(self, ancestor, ours, theirs)
	Index self
	SV *ancestor
	SV *ours
	SV *theirs

	PREINIT:
		int rc;

		Index_Entry a = NULL, o = NULL, t = NULL;

	CODE:
		if (SvOK(ancestor))
			a = GIT_SV_TO_PTR(Index::Entry, ancestor);

		if (SvOK(ours))
			o = GIT_SV_TO_PTR(Index::Entry, ours);

		if (SvOK(theirs))
			t = GIT_SV_TO_PTR(Index::Entry, theirs);

		rc = git_index_conflict_add(self, a, o, t);
		git_check_error(rc);

void
remove_conflict(self, path)
	Index self
	SV *path

	PREINIT:
		int rc;

	CODE:
		rc = git_index_conflict_remove(self, SvPVbyte_nolen(path));
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

		SV *repo;

		git_index_conflict_iterator *iter;
		const git_index_entry *ancestor, *ours, *theirs;

		size_t num_conflicts = 0;

	PPCODE:
		rc = git_index_conflict_iterator_new(
			&iter, GIT_SV_TO_PTR(Index, self)
		);
		git_check_error(rc);

		repo = GIT_SV_TO_MAGIC(self);

		while ((rc = git_index_conflict_next(
			&ancestor, &ours, &theirs, iter)) == GIT_OK) {
			HV *entries = newHV();

			if (ancestor != NULL) {
				SV *entry = NULL;

				GIT_NEW_OBJ_WITH_MAGIC(
					entry, "Git::Raw::Index::Entry",
					(Index_Entry) ancestor, repo
				);

				hv_stores(entries, "ancestor", entry);
			}

			if (ours != NULL) {
				SV *entry = NULL;

				GIT_NEW_OBJ_WITH_MAGIC(
					entry, "Git::Raw::Index::Entry",
					(Index_Entry) ours, repo
				);

				hv_stores(entries, "ours", entry);
			}

			if (theirs != NULL) {
				SV *entry = NULL;

				GIT_NEW_OBJ_WITH_MAGIC(
					entry, "Git::Raw::Index::Entry",
					(Index_Entry) theirs, repo
				);

				hv_stores(entries, "theirs", entry);
			}

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
