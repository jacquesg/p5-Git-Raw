MODULE = Git::Raw			PACKAGE = Git::Raw::TreeBuilder

SV *
new(class, repo, ...)
	const char *class
	SV *repo

	PREINIT:
		int rc;
		TreeBuilder builder;
		Tree source = NULL;

	CODE:
		if (items > 2) {
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

	PREINIT:
		const git_tree_entry *entry;

	CODE:
		entry = git_treebuilder_get(GIT_SV_TO_PTR(TreeBuilder, self), filename);

		if(entry) {
			GIT_NEW_OBJ(RETVAL, "Git::Raw::TreeEntry", git_tree_entry_dup(entry),
				GIT_SV_TO_REPO(self));
		} else {
			RETVAL = &PL_sv_undef;
		}

	OUTPUT: RETVAL

void
insert(self, filename, object, mode)
	SV *self
	const char *filename
	SV *object
	int mode

	PREINIT:
		int rc;

		const git_tree_entry *entry;
		const git_oid *oid;

		int is_returning = GIMME_V != G_VOID;

	PPCODE:
		if(sv_isobject(object) && sv_derived_from(object, "Git::Raw::Blob")) {
			oid = git_blob_id(GIT_SV_TO_PTR(Blob, object));
		} else {
			oid = git_tree_id(GIT_SV_TO_PTR(Tree, object));
		}

		rc = git_treebuilder_insert(is_returning ? &entry : NULL,
			GIT_SV_TO_PTR(TreeBuilder, self), filename, oid, mode);
		git_check_error(rc);

		if (is_returning) {
			GIT_NEW_OBJ(ST(0), "Git::Raw::TreeEntry", git_tree_entry_dup(entry), GIT_SV_TO_REPO(self));
			sv_2mortal(ST(0));
			XSRETURN(1);
		} else {
			XSRETURN_EMPTY;
		}

void
remove(self, filename)
	TreeBuilder self
	const char *filename

	PREINIT:
		int rc;

	CODE:
		rc = git_treebuilder_remove(self, filename);
		git_check_error(rc);

void
write(self)
	SV *self

	PREINIT:
		int rc;
		git_oid oid;
		Tree tree;
		SV *repo;
		Repository repo_ptr;
		int is_returning = GIMME_V != G_VOID;

	PPCODE:
		repo     = GIT_SV_TO_REPO(self);
		repo_ptr = INT2PTR(Repository, SvIV((SV *) repo));

		rc = git_treebuilder_write(&oid, repo_ptr, GIT_SV_TO_PTR(TreeBuilder, self));
		git_check_error(rc);

		if(is_returning) {
			rc = git_tree_lookup(&tree, repo_ptr, &oid);
			git_check_error(rc);

			GIT_NEW_OBJ(ST(0), "Git::Raw::Tree", tree, repo);
			sv_2mortal(ST(0));
			XSRETURN(1);
		} else {
			XSRETURN_EMPTY;
		}

void
DESTROY(self)
	SV *self

	CODE:
		git_treebuilder_free(GIT_SV_TO_PTR(TreeBuilder, self));
		SvREFCNT_dec(xs_object_magic_get_struct(aTHX_ SvRV(self)));
