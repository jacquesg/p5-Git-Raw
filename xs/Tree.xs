MODULE = Git::Raw			PACKAGE = Git::Raw::Tree

SV *
lookup(class, repo, id)
	SV *class
	SV *repo
	SV *id

	CODE:
		Tree tree;
		git_oid oid;

		STRLEN len;
		const char *id_str = SvPVbyte(id, len);
		Repository repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		int rc = git_oid_fromstrn(&oid, id_str, len);
		git_check_error(rc);

		rc = git_tree_lookup_prefix(&tree, repo_ptr, &oid, len);
		git_check_error(rc);

		GIT_NEW_OBJ(RETVAL, SvPVbyte_nolen(class), tree, SvRV(repo));

	OUTPUT: RETVAL

SV *
id(self)
	Tree self

	CODE:
		const git_oid *oid = git_tree_id(self);
		RETVAL = git_oid_to_sv((git_oid *) oid);

	OUTPUT: RETVAL

AV *
entries(self)
	SV *self

	CODE:
		SV *repo = GIT_SV_TO_REPO(self);

		AV *entries = newAV();
		Tree self_ptr = GIT_SV_TO_PTR(Tree, self);
		int i, count = git_tree_entrycount(self_ptr);

		for (i = 0; i < count; i++) {
			SV *tmp;
			TreeEntry entry = (TreeEntry) git_tree_entry_byindex(self_ptr, i);

			GIT_NEW_OBJ(
				tmp, "Git::Raw::TreeEntry",
				git_tree_entry_dup(entry), repo
			);

			av_push(entries, tmp);
		}

		RETVAL = entries;

	OUTPUT: RETVAL

SV *
entry_byname(self, name)
	SV *self
	SV *name

	CODE:
		SV *repo = GIT_SV_TO_REPO(self);

		STRLEN len;
		const char *name_str = SvPVbyte(name, len);

		TreeEntry entry = (TreeEntry) git_tree_entry_byname(
			GIT_SV_TO_PTR(Tree, self), name_str
		);

		if (!entry) Perl_croak(aTHX_ "Invalid name");

		GIT_NEW_OBJ(
			RETVAL, "Git::Raw::TreeEntry",
			git_tree_entry_dup(entry), repo
		);

	OUTPUT: RETVAL

SV *
entry_bypath(self, path)
	SV *self
	SV *path

	CODE:
		SV *repo = GIT_SV_TO_REPO(self);

		int rc;
		STRLEN len;
		const char *path_str = SvPVbyte(path, len);

		TreeEntry entry;

		rc = git_tree_entry_bypath(
			&entry, GIT_SV_TO_PTR(Tree, self), path_str
		);
		git_check_error(rc);

		GIT_NEW_OBJ(RETVAL, "Git::Raw::TreeEntry", entry, repo);

	OUTPUT: RETVAL

Diff
diff(self, ...)
	Tree self

	PROTOTYPE: $;$
	CODE:
		int rc;
		Diff diff;

		switch (items) {
			case 1: {
				rc = git_diff_tree_to_workdir(
					&diff, git_tree_owner(self), self, NULL
				);
				git_check_error(rc);

				break;
			}

			case 2: {
				Tree new = GIT_SV_TO_PTR(Tree, ST(1));

				rc = git_diff_tree_to_tree(
					&diff, git_tree_owner(self), self, new, NULL
				);
				git_check_error(rc);

				break;
			}

			default: Perl_croak(aTHX_ "Wrong number of arguments");
		}

		RETVAL = diff;

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		git_tree_free(GIT_SV_TO_PTR(Tree, self));
		SvREFCNT_dec(xs_object_magic_get_struct(aTHX_ SvRV(self)));
