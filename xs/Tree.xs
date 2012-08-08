MODULE = Git::Raw			PACKAGE = Git::Raw::Tree

SV *
id(self)
	Tree self

	CODE:
		char out[41];
		const git_oid *oid = git_tree_id(self);

		git_oid_fmt(out, oid);
		out[40] = '\0';

		RETVAL = newSVpv(out, 0);

	OUTPUT: RETVAL

AV *
entries(self)
	Tree self

	CODE:
		AV *entries = newAV();
		int rc, i, count = git_tree_entrycount(self);

		for (i = 0; i < count; i++) {
			TreeEntry curr = git_tree_entry_byindex(self, i);

			SV *entry = sv_setref_pv(
				newSV(0), "Git::Raw::TreeEntry", (void *) curr
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
