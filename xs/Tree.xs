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

	CODE:
		id_str = SvPVbyte(id, len);

		rc = git_oid_fromstrn(&oid, id_str, len);
		git_check_error(rc);

		rc = git_tree_lookup_prefix(&tree, GIT_SV_TO_PTR(Repository, repo), &oid, len);
		git_check_error(rc);

		GIT_NEW_OBJ(RETVAL, SvPVbyte_nolen(class), tree, SvRV(repo));

	OUTPUT: RETVAL

SV *
id(self)
	Tree self

	PREINIT:
		const git_oid *oid;

	CODE:
		oid = git_tree_id(self);
		RETVAL = git_oid_to_sv((git_oid *) oid);

	OUTPUT: RETVAL

AV *
entries(self)
	SV *self

	PREINIT:
		int i, count;

		Tree self_ptr;
		AV *entries = newAV();

	CODE:
		self_ptr = GIT_SV_TO_PTR(Tree, self);

		count = git_tree_entrycount(self_ptr);

		for (i = 0; i < count; i++) {
			SV *tmp;
			TreeEntry entry = (TreeEntry) git_tree_entry_byindex(self_ptr, i);

			GIT_NEW_OBJ(
				tmp, "Git::Raw::TreeEntry",
				git_tree_entry_dup(entry), GIT_SV_TO_REPO(self)
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
		STRLEN len;
		const char *name_str;

		TreeEntry entry;

	CODE:
		name_str = SvPVbyte(name, len);

		entry = (TreeEntry) git_tree_entry_byname(
			GIT_SV_TO_PTR(Tree, self), name_str
		);

		if (!entry) Perl_croak(aTHX_ "Invalid name");

		GIT_NEW_OBJ(
			RETVAL, "Git::Raw::TreeEntry",
			git_tree_entry_dup(entry), GIT_SV_TO_REPO(self)
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

		TreeEntry entry;

	CODE:
		path_str = SvPVbyte(path, len);

		rc = git_tree_entry_bypath(
			&entry, GIT_SV_TO_PTR(Tree, self), path_str
		);
		git_check_error(rc);

		GIT_NEW_OBJ(RETVAL, "Git::Raw::TreeEntry", entry, GIT_SV_TO_REPO(self));

	OUTPUT: RETVAL

Diff
diff(self, ...)
	Tree self

	PROTOTYPE: $;$

	PREINIT:
		int rc;
		Diff diff;

	CODE:
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
