MODULE = Git::Raw			PACKAGE = Git::Raw::TreeBuilder

SV *
new(class, repo, ...)
	const char *class
	SV *repo

	CODE:
		Tree source = NULL;
		TreeBuilder builder;
		int rc;
		Repository repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		if(items > 2) {
			source = GIT_SV_TO_PTR(Tree, ST(2));
		}

		rc = git_treebuilder_create(&builder, source);
		git_check_error(rc);
		GIT_NEW_OBJ(RETVAL, class, builder, SvRV(repo));

	OUTPUT: RETVAL

void
clear(self)
	TreeBuilder self

	CODE:
		git_treebuilder_clear(self);

unsigned int
entry_count(self)
	TreeBuilder self

	CODE:
		RETVAL = git_treebuilder_entrycount(self);

	OUTPUT: RETVAL

SV *
get(self, filename)
	SV *self
	const char *filename

	CODE:
		TreeBuilder builder;
		SV *repo;
		TreeEntry entry;

		builder = GIT_SV_TO_PTR(TreeBuilder, self);
		repo    = GIT_SV_TO_REPO(self);

		entry = git_tree_entry_dup(git_treebuilder_get(builder, filename));

		GIT_NEW_OBJ(RETVAL, "Git::Raw::TreeEntry", entry, repo);

	OUTPUT: RETVAL

SV *
insert(self, filename, object, mode)
	SV *self
	const char *filename
	SV *object
	int mode

	CODE:
		TreeBuilder builder;
		TreeEntry entry;
		const git_oid *oid;
		SV *repo;
		int rc;

		builder = GIT_SV_TO_PTR(TreeBuilder, self);
		repo    = GIT_SV_TO_REPO(self);

		if(sv_isobject(object) && sv_derived_from(object, "Git::Raw::Blob")) {
			oid = git_blob_id(GIT_SV_TO_PTR(Blob, object));
		} else {
			oid = git_tree_id(GIT_SV_TO_PTR(Tree, object));
		}

		rc = git_treebuilder_insert(&entry, builder, filename, oid, mode);
		git_check_error(rc);

		GIT_NEW_OBJ(RETVAL, "Git::Raw::TreeEntry", git_tree_entry_dup(entry), repo);

	OUTPUT: RETVAL

void
remove(self, filename)
	TreeBuilder self
	const char *filename

	CODE:
		int rc;

		rc = git_treebuilder_remove(self, filename);
		git_check_error(rc);

SV *
write(self, repo)
	TreeBuilder self
	SV *repo

	CODE:
		int rc;
		git_oid oid;
		Tree tree;
		Repository repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		rc = git_treebuilder_write(&oid, repo_ptr, self);
		git_check_error(rc);

		rc = git_tree_lookup(&tree, repo_ptr, &oid);
		git_check_error(rc);

		rc = git_treebuilder_write(&oid, repo_ptr, self);
		GIT_NEW_OBJ(RETVAL, "Git::Raw::Tree", tree, SvRV(repo));

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		git_treebuilder_free(GIT_SV_TO_PTR(TreeBuilder, self));
		SvREFCNT_dec(xs_object_magic_get_struct(aTHX_ SvRV(self)));
