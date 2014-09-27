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
		len = 0;
		id_str = git_ensure_pv_with_len(id, "id", &len);

	CODE:
		rc = git_oid_fromstrn(&oid, id_str, len);
		git_check_error(rc);

		repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		rc = git_tree_lookup_prefix(&tree, repo_ptr -> repository, &oid, len);

		if (rc == GIT_ENOTFOUND) {
			RETVAL = &PL_sv_undef;
		} else {
			git_check_error(rc);

			GIT_NEW_OBJ_WITH_MAGIC(
				RETVAL, SvPVbyte_nolen(class), tree, SvRV(repo)
			);
		}

	OUTPUT: RETVAL

SV *
owner(self)
	SV *self

	PREINIT:
		SV *repo;

	CODE:
		repo = GIT_SV_TO_MAGIC(self);
		RETVAL = newRV_inc(repo);

	OUTPUT: RETVAL

SV *
id(self)
	Tree self

	CODE:
		RETVAL = git_oid_to_sv(git_tree_id(self));

	OUTPUT: RETVAL

void
entries(self)
	SV *self

	PREINIT:
		int ctx;

		Tree self_ptr;

	PPCODE:
		ctx = GIMME_V;

		if (ctx != G_VOID) {
			int rc, count;

			self_ptr = GIT_SV_TO_PTR(Tree, self);
			count = git_tree_entrycount(self_ptr);

			if (ctx == G_ARRAY) {
				int i;

				for (i = 0; i < count; i++) {
					SV *tmp;
					Tree_Entry entry;

					Tree_Entry tmp_entry = (Tree_Entry)
						git_tree_entry_byindex(self_ptr, i);

					rc = git_tree_entry_dup(&entry, tmp_entry);
					git_check_error(rc);

					GIT_NEW_OBJ_WITH_MAGIC(
						tmp, "Git::Raw::Tree::Entry",
						entry, GIT_SV_TO_MAGIC(self)
					);
					mXPUSHs(tmp);
				}

				XSRETURN((int) count);
			} else {
				mXPUSHs(newSViv((int) count));
				XSRETURN(1);
			}
		} else
			XSRETURN_EMPTY;

SV *
entry_byname(self, name)
	SV *self
	SV *name

	PREINIT:
		int rc;

		Tree_Entry tmp_entry, entry;

	CODE:
		tmp_entry = (Tree_Entry) git_tree_entry_byname(
			GIT_SV_TO_PTR(Tree, self),
			git_ensure_pv(name, "name")
		);

		if (!tmp_entry) {
			RETVAL = &PL_sv_undef;
		} else {
			rc = git_tree_entry_dup(&entry, tmp_entry);
			git_check_error(rc);

			GIT_NEW_OBJ_WITH_MAGIC(
				RETVAL, "Git::Raw::Tree::Entry",
				entry, GIT_SV_TO_MAGIC(self)
			);
		}

	OUTPUT: RETVAL

SV *
entry_bypath(self, path)
	SV *self
	SV *path

	PREINIT:
		int rc;

		Tree_Entry entry;

	CODE:
		rc = git_tree_entry_bypath(
			&entry, GIT_SV_TO_PTR(Tree, self),
			git_ensure_pv(path, "path")
		);

		if (rc == GIT_ENOTFOUND) {
			RETVAL = &PL_sv_undef;
		} else {
			git_check_error(rc);

			GIT_NEW_OBJ_WITH_MAGIC(
				RETVAL, "Git::Raw::Tree::Entry", entry, GIT_SV_TO_MAGIC(self)
			);
		}

	OUTPUT: RETVAL

Diff
diff(self, ...)
	Tree self

	PROTOTYPE: $;$

	PREINIT:
		int rc;

		Diff diff;

		Tree tree = NULL;

		git_diff_options diff_opts = GIT_DIFF_OPTIONS_INIT;

	CODE:
		if (items == 2) {
			HV *opts  = git_ensure_hv(ST(1), "diff_opts");
			git_hv_to_diff_opts(opts, &diff_opts, &tree);
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

		if (diff_opts.pathspec.count > 0)
			Safefree(diff_opts.pathspec.strings);
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

		rc = git_merge_trees(&index, repo_ptr -> repository,
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
