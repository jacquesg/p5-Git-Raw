MODULE = Git::Raw			PACKAGE = Git::Raw::Tree

SV *
lookup(class, repo, id)
	SV *class
	SV *repo
	SV *id

	CODE:
		git_oid oid;
		git_object *obj;

		STRLEN len;
		const char *id_str = SvPVbyte(id, len);

		int rc = git_oid_fromstrn(&oid, id_str, len);
		git_check_error(rc);

		rc = git_object_lookup_prefix(&obj, GIT_SV_TO_PTR(Repository, repo), &oid, len, GIT_OBJ_TREE);
		git_check_error(rc);

		GIT_NEW_OBJ_DOUBLE(RETVAL, class, obj, repo);

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
		AV *entries = newAV();
		Tree self_ptr = GIT_SV_TO_PTR(Tree, self);
		int rc, i, count = git_tree_entrycount(self_ptr);

		for (i = 0; i < count; i++) {
			TreeEntry entry = (TreeEntry) git_tree_entry_byindex(self_ptr, i);

			SV *sv = sv_setref_pv(
				newSV(0), "Git::Raw::TreeEntry",
				git_tree_entry_dup(entry)
			);
			xs_object_magic_attach_struct(
				aTHX_ SvRV(sv),
				SvREFCNT_inc_NN(xs_object_magic_get_struct(aTHX_ SvRV(self)))
			);

			av_push(entries, sv);
		}

		RETVAL = entries;

	OUTPUT: RETVAL

SV *
entry_byname(self, name)
	SV *self
	SV *name

	CODE:
		STRLEN len;
		const char *name_str = SvPVbyte(name, len);

		TreeEntry entry = (TreeEntry) git_tree_entry_byname(GIT_SV_TO_PTR(Tree, self), name_str);
		if (!entry) Perl_croak(aTHX_ "Invalid name");

		SV *sv = sv_setref_pv(
			newSV(0), "Git::Raw::TreeEntry",
			git_tree_entry_dup(entry)
		);
		xs_object_magic_attach_struct(
			aTHX_ SvRV(sv),
			SvREFCNT_inc_NN(xs_object_magic_get_struct(aTHX_ SvRV(self)))
		);

		RETVAL = sv;

	OUTPUT: RETVAL

SV *
entry_bypath(self, path)
	SV *self
	SV *path

	CODE:
		int rc;
		STRLEN len;
		const char *path_str = SvPVbyte(path, len);
		TreeEntry entry;

		rc = git_tree_entry_bypath(&entry, GIT_SV_TO_PTR(Tree, self), path_str);
		git_check_error(rc);

		SV *sv = sv_setref_pv(
			newSV(0), "Git::Raw::TreeEntry",
			git_tree_entry_dup(entry)
		);
		xs_object_magic_attach_struct(
			aTHX_ SvRV(sv),
			SvREFCNT_inc_NN(xs_object_magic_get_struct(aTHX_ SvRV(self)))
		);

		RETVAL = sv;

	OUTPUT: RETVAL

Diff
diff(self, repo, ...)
	Tree self
	Repository repo

	PROTOTYPE: $$;$
	CODE:
		int rc;
		Diff diff;

		switch (items) {
			case 2: {
				rc = git_diff_tree_to_workdir(
					&diff, repo, self, NULL
				);
				git_check_error(rc);

				break;
			}

			case 3: {
				Tree new = GIT_SV_TO_PTR(Tree, ST(2));

				rc = git_diff_tree_to_tree(
					&diff, repo, self, new, NULL
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
