MODULE = Git::Raw			PACKAGE = Git::Raw::Tree

SV *
lookup(class, repo, id)
	SV *class
	SV *repo
	SV *id

	PREINIT:
		int rc;

		Tree tree;
		git_oid oid;

		STRLEN len;
		const char *id_str;

		Repository repo_ptr;

	INIT:
		id_str = SvPVbyte(id, len);

	CODE:
		rc = git_oid_fromstrn(&oid, id_str, len);
		git_check_error(rc);

		repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		rc = git_tree_lookup_prefix(&tree, repo_ptr, &oid, len);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, SvPVbyte_nolen(class), tree, SvRV(repo)
		);

	OUTPUT: RETVAL

SV *
id(self)
	Tree self

	CODE:
		RETVAL = git_oid_to_sv(git_tree_id(self));

	OUTPUT: RETVAL

AV *
entries(self)
	SV *self

	PREINIT:
		int rc;
		int i, count;

		Tree self_ptr;
		Tree_Entry entry;
		AV *entries = newAV();

	CODE:
		self_ptr = GIT_SV_TO_PTR(Tree, self);

		count = git_tree_entrycount(self_ptr);

		for (i = 0; i < count; i++) {
			SV *tmp;

			Tree_Entry tmp_entry = (Tree_Entry)
				git_tree_entry_byindex(self_ptr, i);

			rc = git_tree_entry_dup(&entry, tmp_entry);
			git_check_error(rc);

			GIT_NEW_OBJ_WITH_MAGIC(
				tmp, "Git::Raw::Tree::Entry",
				entry, GIT_SV_TO_MAGIC(self)
			);

			av_push(entries, tmp);
		}

		RETVAL = entries;

	OUTPUT: RETVAL

SV *
entry_byname(self, name)
	SV *self
	SV *name

	PREINIT:
		int rc;

		STRLEN len;
		const char *name_str;

		Tree_Entry tmp_entry, entry;

	CODE:
		name_str = SvPVbyte(name, len);

		tmp_entry = (Tree_Entry) git_tree_entry_byname(
			GIT_SV_TO_PTR(Tree, self), name_str
		);

		if (!tmp_entry) Perl_croak(aTHX_ "Invalid name");

		rc = git_tree_entry_dup(&entry, tmp_entry);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Tree::Entry",
			entry, GIT_SV_TO_MAGIC(self)
		);

	OUTPUT: RETVAL

SV *
entry_bypath(self, path)
	SV *self
	SV *path

	PREINIT:
		int rc;

		STRLEN len;
		const char *path_str;

		Tree_Entry entry;

	CODE:
		path_str = SvPVbyte(path, len);

		rc = git_tree_entry_bypath(
			&entry, GIT_SV_TO_PTR(Tree, self), path_str
		);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Tree::Entry", entry, GIT_SV_TO_MAGIC(self)
		);

	OUTPUT: RETVAL

Diff
diff(self, ...)
	Tree self

	PROTOTYPE: $;$

	PREINIT:
		int rc;

		Diff diff;

		char **paths = NULL;
		Tree tree = NULL;

		git_diff_options diff_opts = GIT_DIFF_OPTIONS_INIT;

	CODE:
		if (items == 2) {
			SV *opt;
			AV *lopt;
			HV *hopt;

			HV *opts;

			opts = git_ensure_hv(ST(1), "options");

			if ((opt = git_hv_sv_entry(opts, "tree")))
				tree = GIT_SV_TO_PTR(Tree, opt);

			if ((hopt = git_hv_hash_entry(opts, "flags")))
				diff_opts.flags |= git_hv_to_diff_flag(hopt);

			if ((hopt = git_hv_hash_entry(opts, "prefix"))) {
				SV *ab;

				if ((ab = git_hv_string_entry(hopt, "a")))
					diff_opts.old_prefix = SvPVbyte_nolen(ab);

				if ((ab = git_hv_string_entry(hopt, "b")))
					diff_opts.new_prefix = SvPVbyte_nolen(ab);
			}

			if ((opt = git_hv_int_entry(opts, "context_lines")))
				diff_opts.context_lines = (uint16_t) SvIV(opt);

			if ((opt = git_hv_int_entry(opts, "interhunk_lines")))
				diff_opts.interhunk_lines = (uint16_t) SvIV(opt);

			if ((lopt = git_hv_list_entry(opts, "paths"))) {
				SV **path;
				size_t i = 0, count = 0;

				while ((path = av_fetch(lopt, i++, 0))) {
					if (!SvOK(*path))
						continue;

					Renew(paths, count + 1, char *);
					paths[count++] = SvPVbyte_nolen(*path);
				}

				if (count > 0) {
					diff_opts.flags |= GIT_DIFF_DISABLE_PATHSPEC_MATCH;
					diff_opts.pathspec.strings = paths;
					diff_opts.pathspec.count   = count;
				}
			}
		}

		if (tree) {
			rc = git_diff_tree_to_tree(
				&diff, git_tree_owner(self), self, tree, &diff_opts
			);
		} else {
			rc = git_diff_tree_to_workdir(
				&diff, git_tree_owner(self), self, &diff_opts
			);
		}

		Safefree(paths);
		git_check_error(rc);

		RETVAL = diff;

	OUTPUT: RETVAL

SV *
merge(self, ancestor_tree, their_tree, ...)
	SV *self
	SV *ancestor_tree
	SV *their_tree

	PROTOTYPE: $$$;$
	PREINIT:
		int rc;

		SV *repo;
		Repository repo_ptr;

		Tree ancestor = NULL, ours = NULL, theirs = NULL;

		Index index;
		git_merge_options merge_opts = GIT_MERGE_OPTIONS_INIT;

	CODE:
		if (items == 4) {
			HV *opts = git_ensure_hv(ST(3), "options");
			git_hv_to_merge_opts(opts, &merge_opts);
		}

		if (SvOK(ancestor_tree))
			ancestor = GIT_SV_TO_PTR(Tree, ancestor_tree);

		if (SvOK(their_tree))
			theirs = GIT_SV_TO_PTR(Tree, their_tree);

		ours = GIT_SV_TO_PTR(Tree, self);

		repo = GIT_SV_TO_MAGIC(self);
		repo_ptr = INT2PTR(Repository, SvIV((SV *) repo));

		rc = git_merge_trees(&index, repo_ptr,
			ancestor, ours, theirs, &merge_opts);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Index", index, repo
		);

	OUTPUT: RETVAL

SV *
is_tree(self)
	SV *self

	CODE:
		RETVAL = newSVuv(1);

	OUTPUT: RETVAL

SV *
is_blob(self)
	SV *self

	CODE:
		RETVAL = newSVuv(0);

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		git_tree_free(GIT_SV_TO_PTR(Tree, self));
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
