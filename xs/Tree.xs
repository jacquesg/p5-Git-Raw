MODULE = Git::Raw			PACKAGE = Git::Raw::Tree

SV *
lookup(class, repo, id)
	SV *class
	Repository repo
	SV *id

	CODE:
		git_oid oid;
		git_object *o;

		STRLEN len;
		const char *id_str = SvPVbyte(id, len);

		int rc = git_oid_fromstrn(&oid, id_str, len);
		git_check_error(rc);

		rc = git_object_lookup_prefix(&o, repo, &oid, len, GIT_OBJ_TREE);
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), o);

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
	Tree self

	CODE:
		AV *entries = newAV();
		int rc, i, count = git_tree_entrycount(self);

		for (i = 0; i < count; i++) {
			TreeEntry curr = (TreeEntry) git_tree_entry_byindex(self, i);

			SV *entry = sv_setref_pv(
				newSV(0), "Git::Raw::TreeEntry",
				(void *) git_tree_entry_dup(curr)
			);

			av_push(entries, entry);
		}

		RETVAL = entries;

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
				rc = git_diff_workdir_to_tree(
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
	Tree self

	CODE:
		git_tree_free(self);
