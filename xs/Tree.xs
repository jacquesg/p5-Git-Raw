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

	CODE:
		id_str = SvPVbyte(id, len);

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
		int rc;
		int i, count;

		Tree self_ptr;
		TreeEntry entry;
		AV *entries = newAV();

	CODE:
		self_ptr = GIT_SV_TO_PTR(Tree, self);

		count = git_tree_entrycount(self_ptr);

		for (i = 0; i < count; i++) {
			SV *tmp;
			TreeEntry tmp_entry = (TreeEntry)
				git_tree_entry_byindex(self_ptr, i);

			rc = git_tree_entry_dup(&entry, tmp_entry);
			git_check_error(rc);

			GIT_NEW_OBJ_WITH_MAGIC(
				tmp, "Git::Raw::TreeEntry",
				entry, GIT_SV_TO_REPO(self)
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

		TreeEntry tmp_entry, entry;

	CODE:
		name_str = SvPVbyte(name, len);

		tmp_entry = (TreeEntry) git_tree_entry_byname(
			GIT_SV_TO_PTR(Tree, self), name_str
		);

		if (!tmp_entry) Perl_croak(aTHX_ "Invalid name");

		rc = git_tree_entry_dup(&entry, tmp_entry);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::TreeEntry",
			entry, GIT_SV_TO_REPO(self)
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

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::TreeEntry", entry, GIT_SV_TO_REPO(self)
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
		if (items > 2)
			Perl_croak(aTHX_ "Wrong number of arguments");

		if (items == 2) {
			SV **opt;
			HV *opts;

			if (!SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVHV)
				Perl_croak(aTHX_ "Invalid type");

			opts = (HV *) SvRV(ST(1));
			if ((opt = hv_fetchs(opts, "tree", 0))) {
				tree = GIT_SV_TO_PTR(Tree, *opt);
			}

			if ((opt = hv_fetchs(opts, "flags", 0))) {
				if (!SvROK(*opt) || SvTYPE(SvRV(*opt)) != SVt_PVHV)
					Perl_croak(aTHX_ "Expected a list of 'flags'");

				diff_opts.flags |=
					git_hv_to_diff_flag((HV *) SvRV(*opt));
			}

			if ((opt = hv_fetchs(opts, "prefix", 0))) {
				SV **ab;

				if ((ab = hv_fetchs((HV *) SvRV(*opt), "a", 0))) {
					if (!SvPOK(*ab))
						Perl_croak(aTHX_ "Expected a string for prefix");

					diff_opts.old_prefix = SvPVbyte_nolen(*ab);
				}

				if ((ab = hv_fetchs((HV *) SvRV(*opt), "b", 0))) {
					if (!SvPOK(*ab))
						Perl_croak(aTHX_ "Expected a string for prefix");

					diff_opts.new_prefix = SvPVbyte_nolen(*ab);
				}
			}

			if ((opt = hv_fetchs(opts, "context_lines", 0))) {
				if (!SvIOK(*opt))
					Perl_croak(aTHX_ "Expected an integer for 'context_lines'");

				diff_opts.context_lines = SvIV(*opt);
			}

			if ((opt = hv_fetchs(opts, "interhunk_lines", 0))) {
				if (!SvIOK(*opt))
					Perl_croak(aTHX_ "Expected an integer for 'interhunk_lines'");

				diff_opts.interhunk_lines = SvIV(*opt);
			}

			if ((opt = hv_fetchs(opts, "paths", 0))) {
				SV **path;
				size_t count = 0;

				if (!SvROK(*opt) || SvTYPE(SvRV(*opt)) != SVt_PVAV)
					Perl_croak(aTHX_ "Expected a list of 'paths'");

				while ((path = av_fetch((AV *) SvRV(*opt), count, 0))) {
					if (SvOK(*path)) {
						Renew(paths, count + 1, char *);
						paths[count++] = SvPVbyte_nolen(*path);
					}
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
		SvREFCNT_dec(GIT_SV_TO_REPO(self));
