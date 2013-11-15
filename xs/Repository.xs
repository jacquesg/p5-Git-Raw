MODULE = Git::Raw			PACKAGE = Git::Raw::Repository

SV *
init(class, path, is_bare)
	SV *class
	SV *path
	unsigned is_bare

	CODE:
		Repository repo;

		int rc = git_repository_init(
			&repo, SvPVbyte_nolen(path), is_bare
		);
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), repo);

	OUTPUT: RETVAL

SV *
clone(class, url, path, opts)
	SV *class
	SV *url
	SV *path
	HV *opts

	CODE:
		int rc;
		SV **opt;
		Repository repo;

		git_clone_options clone_opts = GIT_CLONE_OPTIONS_INIT;

		/* TODO: support all clone_opts */
		/* Bare repository */
		if ((opt = hv_fetchs(opts, "bare", 0)) && (SvIV(*opt) != 0))
			clone_opts.bare = 1;
		else
			clone_opts.bare = 0;

		/* Cred acquire */
		if ((opt = hv_fetchs(opts, "cred_acquire", 0))) {
			SV *cb = *opt;

			SvREFCNT_inc(cb);

			clone_opts.remote_callbacks.credentials =
							git_cred_acquire_cbb;
			clone_opts.remote_callbacks.payload = cb;
		}

		rc = git_clone(
			&repo, SvPVbyte_nolen(url), SvPVbyte_nolen(path),
			&clone_opts
		);

		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), repo);

	OUTPUT: RETVAL

SV *
open(class, path)
	SV *class
	SV *path

	CODE:
		Repository repo;

		int rc = git_repository_open(&repo, SvPVbyte_nolen(path));
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), repo);

	OUTPUT: RETVAL

SV *
discover(class, path)
	SV *class
	SV *path

	CODE:
		Repository repo;
		char found[GIT_PATH_MAX];

		int rc = git_repository_discover(
			found, GIT_PATH_MAX, SvPVbyte_nolen(path), 1, NULL
		);
		git_check_error(rc);

		rc = git_repository_open(&repo, found);
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), repo);

	OUTPUT: RETVAL

Config
config(self)
	Repository self

	CODE:
		Config cfg;

		int rc = git_repository_config(&cfg, self);
		git_check_error(rc);

		RETVAL = cfg;

	OUTPUT: RETVAL

SV *
index(self)
	SV *self

	CODE:
		Index index;

		int rc = git_repository_index(&index, GIT_SV_TO_PTR(Repository, self));
		git_check_error(rc);

		GIT_NEW_OBJ(RETVAL, "Git::Raw::Index", index, SvRV(self));

	OUTPUT: RETVAL

SV *
head(self, ...)
	SV *self

	PROTOTYPE: $;$
	CODE:
		int rc;
		Reference head;
		Repository repo = GIT_SV_TO_PTR(Repository, self);

		if (items == 2) {
			Reference new_head = GIT_SV_TO_PTR(Reference, ST(1));

			rc = git_repository_set_head(
				repo, git_reference_name(new_head)
			);
			git_check_error(rc);
		}

		rc = git_repository_head(&head, repo);
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), "Git::Raw::Reference", head);

		xs_object_magic_attach_struct(
			aTHX_ SvRV(RETVAL), SvREFCNT_inc_NN(SvRV(self))
		);

	OUTPUT: RETVAL

SV *
lookup(self, id)
	SV *self
	SV *id

	CODE:
		git_oid oid;
		git_object *obj;

		STRLEN len;
		const char *id_str = SvPVbyte(id, len);

		int rc = git_oid_fromstrn(&oid, id_str, len);
		git_check_error(rc);

		rc = git_object_lookup_prefix(
			&obj, GIT_SV_TO_PTR(Repository, self), &oid, len, GIT_OBJ_ANY
		);
		git_check_error(rc);

		RETVAL = git_obj_to_sv(obj, self);

	OUTPUT: RETVAL

void
checkout(self, target, opts)
	Repository self
	SV *target
	HV *opts

	CODE:
		int rc;
		SV *strategy;

		git_checkout_opts checkout_opts = GIT_CHECKOUT_OPTS_INIT;

		/* TODO: support all checkout_opts */
		strategy = *hv_fetchs(opts, "checkout_strategy", 0);
		checkout_opts.checkout_strategy =
			git_hv_to_checkout_strategy((HV *) SvRV(strategy));

		rc = git_checkout_tree(
			self, git_sv_to_obj(target), &checkout_opts
		);
		git_check_error(rc);

void
reset(self, target, type)
	Repository self
	SV *target
	SV *type

	CODE:
		int rc;
		git_reset_t reset;

		STRLEN len;
		const char *type_str = SvPVbyte(type, len);

		if (strcmp(type_str, "soft"))
			reset = GIT_RESET_SOFT;
		else if (strcmp(type_str, "mixed"))
			reset = GIT_RESET_MIXED;
		else
			Perl_croak(aTHX_ "Invalid type");

		rc = git_reset(self, git_sv_to_obj(target), reset);
		git_check_error(rc);

AV *
status(self, path)
	Repository self
	SV *path

	CODE:
		unsigned iflags;

		AV *flags = newAV();

		int rc = git_status_file(&iflags, self, SvPVbyte_nolen(path));
		git_check_error(rc);

		if (iflags & GIT_STATUS_INDEX_NEW)
			av_push(flags, newSVpv("index_new", 0));

		if (iflags & GIT_STATUS_INDEX_MODIFIED)
			av_push(flags, newSVpv("index_modified", 0));

		if (iflags & GIT_STATUS_INDEX_DELETED)
			av_push(flags, newSVpv("index_deleted", 0));

		if (iflags & GIT_STATUS_WT_NEW)
			av_push(flags, newSVpv("worktree_new", 0));

		if (iflags & GIT_STATUS_WT_MODIFIED)
			av_push(flags, newSVpv("worktree_modified", 0));

		if (iflags & GIT_STATUS_WT_DELETED)
			av_push(flags, newSVpv("worktree_deleted", 0));

		if (iflags & GIT_STATUS_IGNORED)
			av_push(flags, newSVpv("ignored", 0));

		RETVAL = flags;

	OUTPUT: RETVAL

void
ignore(self, rules)
	Repository self
	SV *rules

	CODE:
		int rc = git_ignore_add_rule(self, SvPVbyte_nolen(rules));
		git_check_error(rc);

Diff
diff(self, ...)
	Repository self

	PROTOTYPE: $;$
	CODE:
		int rc;

		Diff diff;
		Index index;

		rc = git_repository_index(&index, self);
		git_check_error(rc);

		switch (items) {
			case 1: {
				rc = git_diff_index_to_workdir(
					&diff, self, index, NULL
				);
				git_check_error(rc);

				break;
			}

			case 2: {
				Tree tree = GIT_SV_TO_PTR(Tree, ST(1));

				rc = git_diff_tree_to_index(
					&diff, self, tree, index, NULL
				);
				git_check_error(rc);

				break;
			}

			default: Perl_croak(aTHX_ "Wrong number of arguments");
		}

		RETVAL = diff;

	OUTPUT: RETVAL

AV *
remotes(self)
	Repository self

	CODE:
		int i;

		AV *output = newAV();
		git_strarray remotes;

		int rc = git_remote_list(&remotes, self);
		git_check_error(rc);

		for (i = 0; i < remotes.count; i++) {
			SV *sv;
			Remote remote;

			rc = git_remote_load(&remote, self, remotes.strings[i]);
			git_check_error(rc);

			sv = sv_setref_pv(newSV(0), "Git::Raw::Remote", remote);
			av_push(output, sv);
		}

		git_strarray_free(&remotes);

		RETVAL = output;

	OUTPUT: RETVAL

void
refs(self)
	SV *self

	PPCODE:
		int rc;
		int num_refs = 0;

		Reference ref;
		Repository repo_ptr;
		git_reference_iterator *itr;

		repo_ptr = GIT_SV_TO_PTR(Repository, self);

		rc = git_reference_iterator_new(&itr, repo_ptr);
		git_check_error(rc);

		while ((rc = git_reference_next(&ref, itr)) == 0) {
			SV *perl_ref;

			GIT_NEW_OBJ(perl_ref, "Git::Raw::Reference", ref, SvRV(self));

			EXTEND(SP, 1);
			PUSHs(sv_2mortal(perl_ref));

			num_refs++;
		}
		git_reference_iterator_free(itr);

		if (rc != GIT_ITEROVER)
			git_check_error(rc);

		XSRETURN(num_refs);

SV *
path(self)
	Repository self

	CODE:
		const char *path = git_repository_path(self);
		RETVAL = newSVpv(path, 0);

	OUTPUT: RETVAL

SV *
workdir(self, ...)
	Repository self

	PROTOTYPE: $;$
	CODE:
		const char *path;

		if (items == 2) {
			const char *new_path = SvPVbyte_nolen(ST(1));

			int rc = git_repository_set_workdir(self, new_path, 1);
			git_check_error(rc);
		}

		path = git_repository_workdir(self);
		RETVAL = newSVpv(path, 0);

	OUTPUT: RETVAL

bool
is_bare(self)
	Repository self

	CODE:
		RETVAL = git_repository_is_bare(self);

	OUTPUT: RETVAL

bool
is_empty(self)
	Repository self

	CODE:
		RETVAL = git_repository_is_empty(self);

	OUTPUT: RETVAL

void
refs(self)
	SV *self

	PPCODE:
		Repository repo_ptr;
		git_reference_iterator *itr;
		Reference ref;
		int rc;
		int num_refs = 0;

		repo_ptr = GIT_SV_TO_PTR(Repository, self);

		rc = git_reference_iterator_new(&itr, repo_ptr);
		git_check_error(rc);
		while((rc = git_reference_next(&ref, itr)) == 0) {
			SV *perl_ref;

			GIT_NEW_OBJ(perl_ref, "Git::Raw::Reference", ref, SvRV(self));

			EXTEND(SP, 1);
			PUSHs(sv_2mortal(perl_ref));
			num_refs++;
		}
		git_reference_iterator_free(itr);
		if(rc != GIT_ITEROVER) {
			git_check_error(rc);
		}
		
		XSRETURN(num_refs);

void
DESTROY(self)
	Repository self

	CODE:
		git_repository_free(self);
