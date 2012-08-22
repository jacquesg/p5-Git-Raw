MODULE = Git::Raw			PACKAGE = Git::Raw::Tree

SV *
lookup(class, repo, id)
	SV *class
	Repository repo
	SV *id

	CODE:
		STRLEN len;
		git_oid oid;
		git_object *o;

		int rc = git_oid_fromstrn(&oid, SvPVbyte(id, len), len);
		git_check_error(rc);

		rc = git_object_lookup_prefix(&o, repo, &oid, len, GIT_OBJ_TREE);
		git_check_error(rc);

		RETVAL = git_obj_to_sv(o);

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

void
DESTROY(self)
	Tree self

	CODE:
		git_tree_free(self);
