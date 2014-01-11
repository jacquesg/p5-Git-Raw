MODULE = Git::Raw			PACKAGE = Git::Raw::Repository

SV *
init(class, path, is_bare)
	SV *class
	SV *path
	unsigned is_bare

	PREINIT:
		int rc;
		Repository repo;

	CODE:
		rc = git_repository_init(
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

	PREINIT:
		int rc;

		SV **opt;
		Repository repo;

		git_clone_options clone_opts = GIT_CLONE_OPTIONS_INIT;

	CODE:
		if ((opt = hv_fetchs(opts, "bare", 0)) && SvIV(*opt) != 0)
			clone_opts.bare = 1;

		if ((opt = hv_fetchs(opts, "ignore_cert_errors", 0)) && SvIV(*opt) != 0)
			clone_opts.ignore_cert_errors = 1;

		if ((opt = hv_fetchs(opts, "remote_name", 0)))
			clone_opts.remote_name = SvPVbyte_nolen(*opt);

		if ((opt = hv_fetchs(opts, "checkout_branch", 0)))
			clone_opts.checkout_branch = SvPVbyte_nolen(*opt);

		if ((opt = hv_fetchs(opts, "disable_checkout", 0)) && SvIV(*opt) != 0)
			clone_opts.checkout_opts.checkout_strategy = GIT_CHECKOUT_NONE;

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

	PREINIT:
		int rc;
		Repository repo;

	CODE:
		rc = git_repository_open(&repo, SvPVbyte_nolen(path));
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), repo);

	OUTPUT: RETVAL

SV *
discover(class, path)
	SV *class
	SV *path

	PREINIT:
		int rc;

		Repository repo;
		char found[GIT_PATH_MAX];

	CODE:
		rc = git_repository_discover(
			found, GIT_PATH_MAX, SvPVbyte_nolen(path), 1, NULL
		);
		git_check_error(rc);

		rc = git_repository_open(&repo, found);
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), repo);

	OUTPUT: RETVAL

SV *
new(class)
	SV *class

	PREINIT:
		int rc;
		Repository repo;

	CODE:
		rc = git_repository_new(&repo);
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), repo);

	OUTPUT: RETVAL

Config
config(self)
	Repository self

	PREINIT:
		int rc;
		Config cfg;

	CODE:
		rc = git_repository_config(&cfg, self);
		git_check_error(rc);

		RETVAL = cfg;

	OUTPUT: RETVAL

SV *
index(self)
	SV *self

	PREINIT:
		int rc;
		Index index;

	CODE:
		rc = git_repository_index(&index, GIT_SV_TO_PTR(Repository, self));
		git_check_error(rc);

		GIT_NEW_OBJ(RETVAL, "Git::Raw::Index", index, SvRV(self));

	OUTPUT: RETVAL

SV *
head(self, ...)
	SV *self

	PROTOTYPE: $;$

	PREINIT:
		int rc;

		Reference head;
		Repository repo;

	CODE:
		repo = GIT_SV_TO_PTR(Repository, self);

		if (items == 2) {
			Reference new_head = GIT_SV_TO_PTR(Reference, ST(1));

			rc = git_repository_set_head(
				repo, git_reference_name(new_head)
			);
			git_check_error(rc);
		}

		rc = git_repository_head(&head, repo);
		git_check_error(rc);

		GIT_NEW_OBJ(RETVAL, "Git::Raw::Reference", head, SvRV(self));

	OUTPUT: RETVAL

SV *
lookup(self, id)
	SV *self
	SV *id

	PREINIT:
		int rc;

		git_oid oid;
		git_object *obj;

		STRLEN len;
		const char *id_str;

	CODE:
		id_str = SvPVbyte(id, len);

		rc = git_oid_fromstrn(&oid, id_str, len);
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

	PREINIT:
		int rc;

		SV **opt;
		char **paths = NULL;

		git_checkout_opts checkout_opts = GIT_CHECKOUT_OPTS_INIT;

	CODE:
		/* TODO: support all checkout_opts */
		if ((opt = hv_fetchs(opts, "checkout_strategy", 0)))
			checkout_opts.checkout_strategy =
				git_hv_to_checkout_strategy(
					(HV *) SvRV(*opt)
				);

		if ((opt = hv_fetchs(opts, "paths", 0))) {
			SV **path;
			size_t count = 0;

			if (!SvROK(*opt) || SvTYPE(SvRV(*opt)) != SVt_PVAV)
				Perl_croak(aTHX_ "Invalid type");

			while ((path = av_fetch((AV *) SvRV(*opt), count, 0))) {
				if (SvOK(*path)) {
					Renew(paths, count+1, char *);
					paths[count++] = SvPVbyte_nolen(*path);
				}
			}

			if (count > 0) {
				checkout_opts.paths.strings = paths;
				checkout_opts.paths.count   = count;
			}
		}

		rc = git_checkout_tree(
			self, git_sv_to_obj(target), &checkout_opts
		);

		Safefree(paths);
		git_check_error(rc);

void
reset(self, target, type)
	Repository self
	SV *target
	SV *type

	PREINIT:
		int rc;
		git_reset_t reset;

		STRLEN len;
		const char *type_str;

	CODE:
		type_str = SvPVbyte(type, len);

		if (strcmp(type_str, "soft") == 0)
			reset = GIT_RESET_SOFT;
		else if (strcmp(type_str, "mixed") == 0)
			reset = GIT_RESET_MIXED;
		else
			Perl_croak(aTHX_ "Invalid type");

		rc = git_reset(self, git_sv_to_obj(target), reset);
		git_check_error(rc);

HV *
status(self, ...)
	Repository self

	PROTOTYPE: $;@

	PREINIT:
		int rc;

		size_t i, count;

		HV *status_hv = newHV();

		git_status_list *list;
		git_status_options opt = GIT_STATUS_OPTIONS_INIT;

	CODE:
		if (items > 1) {
			opt.flags |= GIT_STATUS_OPT_DISABLE_PATHSPEC_MATCH;

			Newx(opt.pathspec.strings, items - 1, char *);

			for (i = 1; i < items; i++)
				opt.pathspec.strings[i - 1] =
					SvPVbyte_nolen(ST(i));

			opt.pathspec.count = i - 1;
		}

		opt.flags |= GIT_STATUS_OPT_DEFAULTS;

		rc = git_status_list_new(&list, self, &opt);
		git_check_error(rc);

		count = git_status_list_entrycount(list);

		Safefree(opt.pathspec.strings);

		for (i = 0; i < count; i++) {
			AV *flags = newAV();

			const char *path;
			const git_status_entry *entry;

			av_clear(flags);

			entry = git_status_byindex(list, i);
			if (entry == NULL) continue;

			if (entry -> status & GIT_STATUS_INDEX_NEW)
				av_push(flags, newSVpv("index_new", 0));

			if (entry -> status & GIT_STATUS_INDEX_MODIFIED)
				av_push(flags, newSVpv("index_modified", 0));

			if (entry -> status & GIT_STATUS_INDEX_DELETED)
				av_push(flags, newSVpv("index_deleted", 0));

			if (entry -> status & GIT_STATUS_WT_NEW)
				av_push(flags, newSVpv("worktree_new", 0));

			if (entry -> status & GIT_STATUS_WT_MODIFIED)
				av_push(flags, newSVpv("worktree_modified", 0));

			if (entry -> status & GIT_STATUS_WT_DELETED)
				av_push(flags, newSVpv("worktree_deleted", 0));

			if (entry -> status & GIT_STATUS_IGNORED)
				av_push(flags, newSVpv("ignored", 0));

			if (entry -> head_to_index)
				path = entry -> head_to_index -> old_file.path;
			else
				path = entry -> index_to_workdir -> old_file.path;

			hv_store(status_hv, path, strlen(path), newRV_inc((SV *) flags), 0);
		}

		git_status_list_free(list);

		RETVAL = status_hv;

	OUTPUT: RETVAL

SV *
path_is_ignored(self, path)
	Repository self
	const char *path

	PREINIT:
		int rc, ignore;

	CODE:
		rc = git_ignore_path_is_ignored(&ignore, self, path);
		git_check_error(rc);

		RETVAL = newSViv(ignore);

	OUTPUT: RETVAL

void
ignore(self, rules)
	Repository self
	SV *rules

	PREINIT:
		int rc;

	CODE:
		rc = git_ignore_add_rule(self, SvPVbyte_nolen(rules));
		git_check_error(rc);

Diff
diff(self, ...)
	Repository self

	PROTOTYPE: $;$

	PREINIT:
		int rc;

		Diff diff;
		Index index;

	CODE:
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

			default:
				git_index_free(index);
				Perl_croak(aTHX_ "Wrong number of arguments");
		}

		git_index_free(index);

		RETVAL = diff;

	OUTPUT: RETVAL

void
branches(self)
	SV *self

	PREINIT:
		int rc;

		Branch branch;
		int num_branches = 0;

		git_branch_t type;
		git_branch_iterator *itr;

		Repository repo;

	PPCODE:
		repo = GIT_SV_TO_PTR(Repository, self);

		rc = git_branch_iterator_new(&itr, repo,
			GIT_BRANCH_LOCAL | GIT_BRANCH_REMOTE);
		git_check_error(rc);

		while ((rc = git_branch_next(&branch, &type, itr)) == 0) {
			SV *perl_ref;

			GIT_NEW_OBJ(perl_ref, "Git::Raw::Branch", branch, SvRV(self));

			EXTEND(SP, 1);
			PUSHs(sv_2mortal(perl_ref));

			num_branches++;
		}
		git_branch_iterator_free(itr);

		if (rc != GIT_ITEROVER)
			git_check_error(rc);

		XSRETURN(num_branches);

void
remotes(self)
	SV *self

	PREINIT:
		int rc;
		size_t i;

		Remote remote;
		int num_remotes = 0;
		git_strarray remotes;

		Repository repo;

	PPCODE:
		repo = GIT_SV_TO_PTR(Repository, self);

		rc = git_remote_list(&remotes, repo);
		git_check_error(rc);

		for (i = 0; i < remotes.count; i++) {
			SV *perl_ref;

			rc = git_remote_load(&remote, repo, remotes.strings[i]);
			git_check_error(rc);

			GIT_NEW_OBJ(perl_ref, "Git::Raw::Remote", remote, SvRV(self));

			EXTEND(SP, 1);
			PUSHs(sv_2mortal(perl_ref));

			num_remotes++;
		}

		git_strarray_free(&remotes);

		XSRETURN(num_remotes);

void
refs(self)
	SV *self

	PREINIT:
		int rc;

		Reference ref;
		int num_refs = 0;

		git_reference_iterator *itr;

	PPCODE:
		rc = git_reference_iterator_new(&itr, GIT_SV_TO_PTR(Repository, self));
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

	PREINIT:
		const char *path;

	CODE:
		path = git_repository_path(self);
		RETVAL = newSVpv(path, 0);

	OUTPUT: RETVAL

SV *
workdir(self, ...)
	Repository self

	PROTOTYPE: $;$

	PREINIT:
		int rc;
		const char *path;

	CODE:
		if (items == 2) {
			const char *new_path = SvPVbyte_nolen(ST(1));

			rc = git_repository_set_workdir(self, new_path, 1);
			git_check_error(rc);
		}

		path = git_repository_workdir(self);
		RETVAL = newSVpv(path, 0);

	OUTPUT: RETVAL

SV *
state(self)
	Repository self

	PREINIT:
		int rc;
		const char *s;

	CODE:
		rc = git_repository_state(self);
		git_check_error(rc);

		switch (rc) {
			case GIT_REPOSITORY_STATE_NONE:
				s = "none";
				break;

			case GIT_REPOSITORY_STATE_MERGE:
				s = "merge";
				break;

			case GIT_REPOSITORY_STATE_REVERT:
				s = "revert";
				break;

			case GIT_REPOSITORY_STATE_CHERRY_PICK:
				s = "cherry_pick";
				break;

			case GIT_REPOSITORY_STATE_BISECT:
				s = "bisect";
				break;

			case GIT_REPOSITORY_STATE_REBASE:
				s = "rebase";
				break;

			case GIT_REPOSITORY_STATE_REBASE_INTERACTIVE:
				s = "rebase_interactive";
				break;

			case GIT_REPOSITORY_STATE_REBASE_MERGE:
				s = "rebase_merge";
				break;

			case GIT_REPOSITORY_STATE_APPLY_MAILBOX:
				s = "apply_mailbox";
				break;

			case GIT_REPOSITORY_STATE_APPLY_MAILBOX_OR_REBASE:
				s = "mailbox_or_rebase";
				break;

			default:
				Perl_croak(aTHX_ "Unhandle state: %i", rc);
		}

		RETVAL = newSVpv(s, strlen(s));

	OUTPUT: RETVAL

SV *
is_bare(self)
	Repository self

	CODE:
		RETVAL = newSViv(git_repository_is_bare(self));

	OUTPUT: RETVAL

SV *
is_empty(self)
	Repository self

	CODE:
		RETVAL = newSViv(git_repository_is_empty(self));

	OUTPUT: RETVAL

SV *
is_shallow(self)
	Repository self

	CODE:
		RETVAL = newSViv(git_repository_is_shallow(self));

	OUTPUT: RETVAL

void
state_cleanup(self)
	Repository self

	PREINIT:
		int rc;

	CODE:
		rc = git_repository_state_cleanup(self);
		git_check_error(rc);

void
DESTROY(self)
	Repository self

	CODE:
		git_repository_free(self);
