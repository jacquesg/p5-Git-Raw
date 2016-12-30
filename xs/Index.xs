MODULE = Git::Raw			PACKAGE = Git::Raw::Index

SV *
new(class)
	SV *class

	PREINIT:
		int rc;
		Index index;

	CODE:
		rc = git_index_new(&index);
		git_check_error(rc);

		GIT_NEW_OBJ(
			RETVAL, "Git::Raw::Index", index
		);

	OUTPUT: RETVAL


void
add(self, entry)
	Index self
	SV *entry

	PREINIT:
		int rc = 0;

	CODE:
		if (SvPOK(entry))
			rc = git_index_add_bypath(self, SvPVbyte_nolen(entry));
		else {
			Index_Entry e = GIT_SV_TO_PTR(Index::Entry, entry);
			rc = git_index_add(self, e);
		}

		git_check_error(rc);

void
add_frombuffer(self, path, buffer)
	Index self
	SV *path
	SV *buffer

	PREINIT:
		int rc;
		git_index_entry entry;
		const char *b;
		STRLEN len;

	CODE:
		if (!SvOK(buffer))
			croak_usage("Buffer not provided");

		if (SvROK(buffer))
			buffer = SvRV(buffer);

		memset(&entry, 0x0, sizeof(git_index_entry));
		entry.mode = GIT_FILEMODE_BLOB;
		entry.path = git_ensure_pv(path, "path");

		b = git_ensure_pv_with_len(buffer, "buffer", &len);
		rc = git_index_add_frombuffer(self, &entry,
			b, (size_t) len);
		git_check_error(rc);

void
add_all(self, opts)
	Index self
	HV *opts

	PREINIT:
		int rc;

		SV *callback;
		AV *lopt;
		HV *hopt;
		git_strarray paths = {0, 0};

		unsigned int flags = GIT_INDEX_ADD_DEFAULT;

	CODE:
		if ((lopt = git_hv_list_entry(opts, "paths")))
			git_list_to_paths(lopt, &paths);

		if ((hopt = git_hv_hash_entry(opts, "flags"))) {
			git_flag_opt(hopt, "force", GIT_INDEX_ADD_FORCE, &flags);
			git_flag_opt(hopt, "disable_pathspec_match", GIT_INDEX_ADD_DISABLE_PATHSPEC_MATCH, &flags);
			git_flag_opt(hopt, "check_pathspec", GIT_INDEX_ADD_CHECK_PATHSPEC, &flags);
		}

		callback = get_callback_option(opts, "notification");

		rc = git_index_add_all(
			self,
			&paths,
			flags,
			git_index_matched_path_cbb,
			callback);
		Safefree(paths.strings);
		git_check_error(rc);

void
clear(self)
	Index self

	CODE:
		git_index_clear(self);

SV *
checksum(self)
	Index self

	CODE:
		RETVAL = git_oid_to_sv(git_index_checksum(self));

	OUTPUT: RETVAL

void
read(self, ...)
	Index self

	PROTOTYPE: $;$
	PREINIT:
		int rc, force = 0;

	CODE:
		if (items == 2)
			force = git_ensure_iv(ST(1), "force");

		rc = git_index_read(self, force);
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
	SV *self

	PROTOTYPE: $;$
	PREINIT:
		int rc;
		git_oid oid;
		Index index;

		SV *repo;
		Repository repo_ptr;
		Tree tree;

	CODE:
		index = GIT_SV_TO_PTR(Index, self);

		if (items == 2) {
			repo = SvRV(ST(1));
			repo_ptr = INT2PTR(Repository, SvIV((SV *) repo));

			rc = git_index_write_tree_to(
				&oid, index, repo_ptr -> repository
			);
		} else {
			repo = GIT_SV_TO_MAGIC(self);
			if (repo == NULL)
				croak_usage("No repository associated with this index");

			repo_ptr = INT2PTR(Repository, SvIV((SV *) repo));

			rc = git_index_write_tree(&oid, index);
		}
		git_check_error(rc);

		rc = git_tree_lookup(&tree, repo_ptr -> repository,
			&oid
		);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Tree",
			tree, repo
		);

	OUTPUT: RETVAL

SV *
find(self, path)
	SV *self
	SV *path

	PREINIT:
		int rc;
		size_t pos;
		Index index;

	CODE:
		RETVAL = &PL_sv_undef;

		index = GIT_SV_TO_PTR(Index, self);

		rc = git_index_find(&pos, index, git_ensure_pv(path, "path"));
		if (rc != GIT_ENOTFOUND) {
			git_check_error(rc);

			RETVAL = git_index_entry_to_sv(
				git_index_get_byindex(index, pos), NULL,
				GIT_SV_TO_MAGIC(self)
			);
		}

	OUTPUT: RETVAL

SV *
merge(self, ancestor, theirs, ours, ...)
	SV *self
	Index_Entry ancestor
	Index_Entry theirs
	Index_Entry ours

	PROTOTYPE: $$$$;$
	PREINIT:
		int rc;

		SV *repo;
		Repository repo_ptr;

		git_merge_file_options options = GIT_MERGE_FILE_OPTIONS_INIT;
		Merge_File_Result result = NULL;

	CODE:
		if (items == 5 && SvOK(ST(4))) {
			HV *opts = git_ensure_hv(ST(4), "merge_opts");
			git_hv_to_merge_file_opts(opts, &options);
		}

		repo = GIT_SV_TO_MAGIC(self);
		repo_ptr = INT2PTR(Repository, SvIV((SV *) repo));

		Newxz(result, 1, git_merge_file_result);

		rc = git_merge_file_from_index(result, repo_ptr -> repository,
			ancestor,
			ours,
			theirs,
			&options);
		if (rc != GIT_OK) {
			Safefree(result);
			git_check_error(rc);
		}

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Merge::File::Result",
			(Merge_File_Result) result, repo
		);

	OUTPUT: RETVAL

void
remove(self, path)
	Index self
	SV *path

	PREINIT:
		int rc;

	CODE:
		rc = git_index_remove_bypath(self, git_ensure_pv(path, "path"));
		git_check_error(rc);

void
remove_all(self, opts)
	Index self
	HV *opts

	PREINIT:
		int rc;

		SV *callback;
		AV *lopt;
		git_strarray paths = {0, 0};

	CODE:
		if ((lopt = git_hv_list_entry(opts, "paths")))
			git_list_to_paths(lopt, &paths);

		callback = get_callback_option(opts, "notification");

		rc = git_index_remove_all(
			self,
			&paths,
			git_index_matched_path_cbb,
			callback);
		Safefree(paths.strings);
		git_check_error(rc);

SV *
path(self)
	Index self

	PREINIT:
		const char *path = NULL;

	CODE:
		if ((path = git_index_path(self)) == NULL)
			XSRETURN_UNDEF;

		RETVAL = newSVpv(path, 0);

	OUTPUT: RETVAL

SV *
owner(self)
	SV *self

	PREINIT:
		SV *repo;

	CODE:
		repo = GIT_SV_TO_MAGIC(self);
		if (repo == NULL)
			RETVAL = &PL_sv_undef;
		else
			RETVAL = newRV_inc(repo);

	OUTPUT: RETVAL

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
			repo_ptr -> repository,
			GIT_SV_TO_PTR(Index, self),
			&checkout_opts
		);
		Safefree(checkout_opts.paths.strings);
		git_check_error(rc);

void
entries(self)
	SV *self

	PREINIT:
		size_t i, count;

		Index index_ptr = NULL;

	PPCODE:
		index_ptr = GIT_SV_TO_PTR(Index, self);
		count = git_index_entrycount(index_ptr);

		if (count > 0) {
			SV *repo = GIT_SV_TO_MAGIC(self);

			for (i = 0; i < count; ++i) {
				SV *entry = git_index_entry_to_sv(
					git_index_get_byindex(index_ptr, i), NULL, repo);
				mXPUSHs(entry);
			}
		}

		XSRETURN(count);

void
add_conflict(self, ancestor, theirs, ours)
	Index self
	Index_Entry ancestor
	Index_Entry theirs
	Index_Entry ours

	PREINIT:
		int rc;

	CODE:
		rc = git_index_conflict_add(self,
			ancestor, ours, theirs
		);
		git_check_error(rc);

SV *
get_conflict(self, path)
	SV *self
	SV *path

	PREINIT:
		int rc;

		Index index;
		const git_index_entry *ancestor, *ours, *theirs;
		Index_Conflict conflict = NULL;

	CODE:
		index = GIT_SV_TO_PTR(Index, self);

		rc = git_index_conflict_get(
			&ancestor, &ours, &theirs,
			index, git_ensure_pv(path, "path")
		);

		RETVAL = &PL_sv_undef;
		if (rc != GIT_ENOTFOUND) {
			git_check_error(rc);

			Newxz(conflict, 1, git_raw_index_conflict);

			conflict -> ancestor = git_index_entry_dup(ancestor, NULL);
			conflict -> ours = git_index_entry_dup(ours, NULL);
			conflict -> theirs = git_index_entry_dup(theirs, NULL);

			GIT_NEW_OBJ_WITH_MAGIC(
				RETVAL, "Git::Raw::Index::Conflict",
				conflict, GIT_SV_TO_MAGIC(self)
			);
		}

	OUTPUT: RETVAL

void
remove_conflict(self, path)
	Index self
	SV *path

	PREINIT:
		int rc;

	CODE:
		rc = git_index_conflict_remove(self,
			git_ensure_pv(path, "path")
		);
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
			SV *c = NULL;
			Index_Conflict conflict = NULL;
			Newxz(conflict, 1, git_raw_index_conflict);

			conflict -> ancestor = git_index_entry_dup(ancestor, NULL);
			conflict -> ours = git_index_entry_dup(ours, NULL);
			conflict -> theirs = git_index_entry_dup(theirs, NULL);

			GIT_NEW_OBJ_WITH_MAGIC(
				c, "Git::Raw::Index::Conflict",
				conflict, repo
			);

			num_conflicts++;

			mXPUSHs(c);
		}

		git_index_conflict_iterator_free(iter);
		git_check_error(rc);

		XSRETURN(num_conflicts);

void
update_all(self, opts)
	Index self
	HV *opts

	PREINIT:
		int rc;

		SV *callback;
		AV *lopt;
		git_strarray paths = {0, 0};

	CODE:
		if ((lopt = git_hv_list_entry(opts, "paths")))
			git_list_to_paths(lopt, &paths);

		callback = get_callback_option(opts, "notification");

		rc = git_index_update_all(
			self,
			&paths,
			git_index_matched_path_cbb,
			callback);
		Safefree(paths.strings);
		git_check_error(rc);

void
capabilities(self)
	Index self

	PREINIT:
		int ctx = GIMME_V;

	PPCODE:
		if (ctx != G_VOID) {
			if (ctx == G_ARRAY) {
				int caps = git_index_caps(self);

				mXPUSHs(newSVpv("ignore_case", 0));
				mXPUSHs(newSViv((caps & GIT_INDEXCAP_IGNORE_CASE) ? 1 : 0));
				mXPUSHs(newSVpv("no_filemode", 0));
				mXPUSHs(newSViv((caps & GIT_INDEXCAP_NO_FILEMODE) ? 1 : 0));
				mXPUSHs(newSVpv("no_symlinks", 0));
				mXPUSHs(newSViv((caps & GIT_INDEXCAP_NO_SYMLINKS) ? 1 : 0));

				XSRETURN(6);
			} else {
				mXPUSHs(newSViv(3));
				XSRETURN(1);
			}
		} else
			XSRETURN_EMPTY;

SV *
version(self, ...)
	Index self

	PROTOTYPE: $;$

	CODE:
		if (items == 2) {
			int rc = git_index_set_version(self,
				(unsigned int)git_ensure_iv(ST(1), "version"));
			git_check_error(rc);
		}

		RETVAL = newSViv (git_index_version(self));

	OUTPUT: RETVAL

void
DESTROY(self)
	SV* self

	CODE:
		git_index_free(GIT_SV_TO_PTR(Index, self));
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
