MODULE = Git::Raw			PACKAGE = Git::Raw::Repository

Repository
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

		RETVAL = repo;

	OUTPUT: RETVAL

Repository
clone(class, url, path, opts)
	SV *class
	SV *url
	SV *path
	HV *opts

	PREINIT:
		int rc;

		SV **opt;
		Repository repo;

		git_raw_remote_callbacks cbs = {0, 0, 0, 0, 0};
		git_clone_options clone_opts = GIT_CLONE_OPTIONS_INIT;

	CODE:
		clone_opts.remote_callbacks.payload = &cbs;

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

		/* Callbacks */
		if ((opt = hv_fetchs(opts, "callbacks", 0))) {
			HV *callbacks;

			if (!SvROK(*opt) || SvTYPE(SvRV(*opt)) != SVt_PVHV)
				Perl_croak(aTHX_ "Invalid type");

			callbacks = (HV *) SvRV(*opt);

			if ((cbs.credentials =
				get_callback_option(callbacks, "credentials")))
				clone_opts.remote_callbacks.credentials =
					git_credentials_cbb;

			if ((cbs.progress =
				get_callback_option(callbacks, "progress")))
				clone_opts.remote_callbacks.progress =
					git_progress_cbb;

			if ((cbs.completion =
				get_callback_option(callbacks, "completion")))
				clone_opts.remote_callbacks.completion =
					git_completion_cbb;

			if ((cbs.transfer_progress =
				get_callback_option(callbacks, "transfer_progress")))
				clone_opts.remote_callbacks.transfer_progress =
					git_transfer_progress_cbb;

			if ((cbs.update_tips =
				get_callback_option(callbacks, "update_tips")))
				clone_opts.remote_callbacks.update_tips =
					git_update_tips_cbb;
		}

		rc = git_clone(
			&repo, SvPVbyte_nolen(url), SvPVbyte_nolen(path),
			&clone_opts
		);

		git_clean_remote_callbacks(&cbs);

		git_check_error(rc);

		RETVAL = repo;

	OUTPUT: RETVAL

Repository
open(class, path)
	SV *class
	SV *path

	PREINIT:
		int rc;
		Repository repo;

	CODE:
		rc = git_repository_open(&repo, SvPVbyte_nolen(path));
		git_check_error(rc);

		RETVAL = repo;

	OUTPUT: RETVAL

Repository
discover(class, path)
	SV *class
	SV *path

	PREINIT:
		int rc;

		Repository repo;

	CODE:
		git_buf buf = GIT_BUF_INIT_CONST(NULL, 0);

		rc = git_buf_grow(&buf, GIT_PATH_MAX);
		git_check_error(rc);

		rc = git_repository_discover(
			&buf, SvPVbyte_nolen(path), 1, NULL
		);

		if (rc != GIT_OK)
			git_buf_free(&buf);

		git_check_error(rc);

		rc = git_repository_open(&repo, (const char*) buf.ptr);
		git_buf_free(&buf);
		git_check_error(rc);

		RETVAL = repo;

	OUTPUT: RETVAL

Repository
new(class)
	SV *class

	PREINIT:
		int rc;
		Repository repo;

	CODE:
		rc = git_repository_new(&repo);
		git_check_error(rc);

		RETVAL = repo;

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

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Index", index, SvRV(self)
		);

	OUTPUT: RETVAL

SV *
head(self, ...)
	SV *self

	PROTOTYPE: $;$

	PREINIT:
		int rc;

		Reference head;
		Repository repo;
		Signature sig;

	CODE:
		repo = GIT_SV_TO_PTR(Repository, self);

		if (items == 2) {
			Reference new_head = GIT_SV_TO_PTR(Reference, ST(1));

			rc = git_signature_default(&sig, repo);
			git_check_error(rc);

			rc = git_repository_set_head(
				repo, git_reference_name(new_head),
				sig, NULL
			);
			git_signature_free(sig);
			git_check_error(rc);
		}

		rc = git_repository_head(&head, repo);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Reference", head, SvRV(self)
		);

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

	INIT:
		id_str = SvPVbyte(id, len);

	CODE:
		rc = git_oid_fromstrn(&oid, id_str, len);
		git_check_error(rc);

		rc = git_object_lookup_prefix(
			&obj, GIT_SV_TO_PTR(Repository, self), &oid, len, GIT_OBJ_ANY
		);
		git_check_error(rc);

		RETVAL = git_obj_to_sv(obj, SvRV(self));

	OUTPUT: RETVAL

void
checkout(self, target, opts)
	Repository self
	SV *target
	HV *opts

	PREINIT:
		int rc;

		git_checkout_options checkout_opts = GIT_CHECKOUT_OPTIONS_INIT;

	CODE:
		git_hv_to_checkout_opts(opts, &checkout_opts);

		rc = git_checkout_tree(
			self, git_sv_to_obj(target), &checkout_opts
		);

		Safefree(checkout_opts.paths.strings);
		git_check_error(rc);

void
reset(self, target, opts)
	Repository self
	SV *target
	HV *opts

	PREINIT:
		int rc;

		Signature sig;
		SV **opt;

	CODE:
		if ((opt = hv_fetchs(opts, "paths", 0))) {
			SV **path;

			size_t i = 0, count = 0;
			git_strarray paths = {0, 0};

			if (!SvROK(*opt) || SvTYPE(SvRV(*opt)) != SVt_PVAV)
				Perl_croak(aTHX_ "Expected a list of 'paths'");

			while ((path = av_fetch((AV *) SvRV(*opt), i++, 0))) {
				if (SvOK(*path)) {
					Renew(paths.strings, count + 1, char *);
					paths.strings[count++] = SvPVbyte_nolen(*path);
				}
			}

			paths.count = count;

			rc = git_reset_default(self, git_sv_to_obj(target), &paths);
			Safefree(paths.strings);
			git_check_error(rc);
		} else {
			if ((opt = hv_fetchs(opts, "type", 0))) {
				git_reset_t reset;
				const char *type_str = SvPVbyte_nolen(*opt);

				if (strcmp(type_str, "soft") == 0)
					reset = GIT_RESET_SOFT;
				else if (strcmp(type_str, "mixed") == 0)
					reset = GIT_RESET_MIXED;
				else
					Perl_croak(aTHX_ "Invalid type");

				rc = git_signature_default(&sig, self);
				git_check_error(rc);

				rc = git_reset(self, git_sv_to_obj(target), reset, sig, NULL);
				git_signature_free(sig);
				git_check_error(rc);
			}
		}

HV *
status(self, ...)
	Repository self

	PROTOTYPE: $;@

	PREINIT:
		int rc, i, count;

		HV *status_hv;

		git_status_list *list;
		git_status_options opt = GIT_STATUS_OPTIONS_INIT;

	CODE:
		opt.flags |= GIT_STATUS_OPT_DEFAULTS |
			GIT_STATUS_OPT_RENAMES_HEAD_TO_INDEX |
			GIT_STATUS_OPT_RENAMES_FROM_REWRITES;

		/*
		 * Core git does not recurse untracked dirs, it merely informs
		 * the user that the directory is untracked.
		 */
		opt.flags &= ~GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS;

		/*
		 * GIT_STATUS_OPT_RENAMES_INDEX_TO_WORKDIR seems to be broken
		 * if files are renamed in both the index and in the working
		 * tree. Core git does not tell you if the file was renamed in
		 * the worktree anyway.
		 */
		if (items > 1) {
			opt.flags |= GIT_STATUS_OPT_DISABLE_PATHSPEC_MATCH;

			Newx(opt.pathspec.strings, items - 1, char *);

			for (i = 1; i < items; i++) {
				size_t index = (size_t) i - 1;
				opt.pathspec.strings[index] =
					SvPVbyte_nolen(ST(i));
				opt.pathspec.count = index;
			}
		}

		rc = git_status_list_new(&list, self, &opt);
		Safefree(opt.pathspec.strings);
		git_check_error(rc);

		count = (int) git_status_list_entrycount(list);

		status_hv = newHV();
		for (i = 0; i < count; i++) {
			AV *flags;
			HV *file_status_hv;

			const char *path = NULL;
			const git_status_entry *entry = NULL;

			if ((entry = git_status_byindex(list, i)) == NULL)
				continue;

			flags = newAV();

			if (entry -> status & GIT_STATUS_INDEX_NEW)
				av_push(flags, newSVpv("index_new", 0));

			if (entry -> status & GIT_STATUS_INDEX_MODIFIED)
				av_push(flags, newSVpv("index_modified", 0));

			if (entry -> status & GIT_STATUS_INDEX_DELETED)
				av_push(flags, newSVpv("index_deleted", 0));

			if (entry -> status & GIT_STATUS_INDEX_RENAMED)
				av_push(flags, newSVpv("index_renamed", 0));

			if (entry -> status & GIT_STATUS_WT_NEW)
				av_push(flags, newSVpv("worktree_new", 0));

			if (entry -> status & GIT_STATUS_WT_MODIFIED)
				av_push(flags, newSVpv("worktree_modified", 0));

			if (entry -> status & GIT_STATUS_WT_DELETED)
				av_push(flags, newSVpv("worktree_deleted", 0));

			if (entry -> status & GIT_STATUS_WT_RENAMED)
				av_push(flags, newSVpv("worktree_renamed", 0));

			if (entry -> status & GIT_STATUS_IGNORED)
				av_push(flags, newSVpv("ignored", 0));

			file_status_hv = newHV();

			if (entry -> index_to_workdir) {
				if (entry -> status & GIT_STATUS_WT_RENAMED) {
					HV *worktree_status_hv = newHV();

					hv_stores(worktree_status_hv, "old_file",
						newSVpv(entry -> index_to_workdir -> old_file.path, 0));
					hv_stores(file_status_hv, "worktree", newRV_noinc((SV *) worktree_status_hv));
				}

				path = entry -> index_to_workdir -> new_file.path;
			}

			if (entry -> head_to_index) {
				if (entry -> status & GIT_STATUS_INDEX_RENAMED) {
					HV *index_status_hv = newHV();

					hv_stores(index_status_hv, "old_file",
						newSVpv(entry -> head_to_index -> old_file.path, 0));
					hv_stores(file_status_hv, "index", newRV_noinc((SV *) index_status_hv));
				}

				if (!path)
					path = entry -> head_to_index -> new_file.path;
			}

			hv_stores(file_status_hv, "flags", newRV_noinc((SV *) flags));
			hv_store(status_hv, path, strlen(path), newRV_noinc((SV *) file_status_hv), 0);
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

		char **paths = NULL;
		Tree tree = NULL;

		git_diff_options diff_opts = GIT_DIFF_OPTIONS_INIT;

	CODE:
		if (items > 2)
			Perl_croak(aTHX_ "Wrong number of arguments");

		rc = git_repository_index(&index, self);
		git_check_error(rc);

		if (items == 2) {
			SV **opt;
			HV *opts;

			if (!SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVHV)
				Perl_croak(aTHX_ "Invalid type");

			opts = (HV *) SvRV(ST(1));
			if ((opt = hv_fetchs(opts, "tree", 0))) {
				/* tree may be undefined */
				if (SvOK(*opt))
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

				diff_opts.context_lines = (uint16_t) SvIV(*opt);
			}

			if ((opt = hv_fetchs(opts, "interhunk_lines", 0))) {
				if (!SvIOK(*opt))
					Perl_croak(aTHX_ "Expected an integer for 'interhunk_lines'");

				diff_opts.interhunk_lines = (uint16_t) SvIV(*opt);
			}

			if ((opt = hv_fetchs(opts, "paths", 0))) {
				SV **path;
				size_t i = 0, count = 0;

				if (!SvROK(*opt) || SvTYPE(SvRV(*opt)) != SVt_PVAV)
					Perl_croak(aTHX_ "Expected a list of 'paths'");

				while ((path = av_fetch((AV *) SvRV(*opt), i++, 0))) {
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
			rc = git_diff_tree_to_index(
				&diff, self, tree, index, &diff_opts
			);
		} else {
			rc = git_diff_index_to_workdir(
				&diff, self, index, &diff_opts
			);
		}

		git_index_free(index);
		Safefree(paths);
		git_check_error(rc);

		RETVAL = diff;

	OUTPUT: RETVAL

SV *
merge_base(self, ...)
	Repository self

	PROTOTYPE: $;@

	PREINIT:
		int i, rc, count;

		git_oid merge_base, *oids = NULL;

	CODE:
		if (items < 3)
			Perl_croak(aTHX_ "At least 2 arguments needed");

		count = items - 1;
		Renew(oids, count, git_oid);
		for (i = 0; i < count; ++i) {
			if (git_sv_to_commitish(self, ST(i + 1), oids + i) == NULL) {
				Safefree(oids);
				Perl_croak(aTHX_ "Could not resolve 'object' to a commit id");
			}
		}

		rc = git_merge_base_many(
			&merge_base, self, (size_t) count, oids);
		Safefree(oids);
		git_check_error(rc);

		RETVAL = git_oid_to_sv(&merge_base);

	OUTPUT: RETVAL

SV *
merge_analysis(self, ref)
	Repository self
	Reference ref

	PREINIT:
		int rc;

		git_merge_head *merge_head;
		git_merge_analysis_t analysis;

		AV *result;
	CODE:
		rc = git_merge_head_from_ref(&merge_head, self, ref);
		git_check_error(rc);

		rc = git_merge_analysis(&analysis,
			self, (const git_merge_head **) &merge_head, 1);
		git_merge_head_free(merge_head);
		git_check_error(rc);

		result = newAV();
		if (analysis & GIT_MERGE_ANALYSIS_NORMAL)
			av_push(result, newSVpv("normal", 0));
		if (analysis & GIT_MERGE_ANALYSIS_UP_TO_DATE)
			av_push(result, newSVpv("up_to_date", 0));
		if (analysis & GIT_MERGE_ANALYSIS_FASTFORWARD)
			av_push(result, newSVpv("fast_forward", 0));
		if (analysis & GIT_MERGE_ANALYSIS_UNBORN)
			av_push(result, newSVpv("unborn", 0));

		RETVAL = newRV_noinc((SV *) result);

	OUTPUT: RETVAL

void
merge(self, ref, ...)
	Repository self
	Reference ref

	PROTOTYPE: $$;$;$
	PREINIT:
		int rc;

		git_merge_head *merge_head;

		SV **opt;

		git_merge_options merge_opts = GIT_MERGE_OPTIONS_INIT;
		git_checkout_options checkout_opts = GIT_CHECKOUT_OPTIONS_INIT;

	CODE:
		rc = git_merge_head_from_ref(&merge_head, self, ref);
		git_check_error(rc);

		if (items >= 3) {
			SV *opts = ST(2);
			if (!SvROK(opts) || SvTYPE(SvRV(opts)) != SVt_PVHV)
				Perl_croak(aTHX_ "Invalid type for 'merge_opts'");

			git_hv_to_merge_opts((HV *) SvRV(opts),
				&merge_opts);
		}

		if (items >= 4) {
			SV *opts = ST(3);
			if (!SvROK(opts) || SvTYPE(SvRV(opts)) != SVt_PVHV)
				Perl_croak(aTHX_ "Invalid type for 'checkout_opts'");

			git_hv_to_checkout_opts((HV *) SvRV(opts),
				&checkout_opts);
		}

		rc = git_merge(
			self, (const git_merge_head **) &merge_head,
			1, &merge_opts, &checkout_opts
		);
		Safefree(checkout_opts.paths.strings);
		git_merge_head_free(merge_head);
		git_check_error(rc);

void
branches(self, ...)
	SV *self

	PROTOTYPE: $;$
	PREINIT:
		int rc;

		Branch branch;
		int num_branches = 0;

		git_branch_t type;
		git_branch_iterator *itr;

		Repository repo;

	PPCODE:
		type = GIT_BRANCH_ALL;

		if (items == 2) {
			const char *type_str = NULL;

			if (!SvPOK(ST(1)))
				Perl_croak(aTHX_ "Expected a string for 'type'");

			type_str = SvPVbyte_nolen(ST(1));
			if (strcmp(type_str, "local") == 0)
				type = GIT_BRANCH_LOCAL;
			else if (strcmp(type_str, "remote") == 0)
				type = GIT_BRANCH_REMOTE;
			else if (strcmp(type_str, "all") == 0)
				type = GIT_BRANCH_ALL;
			else
				Perl_croak(aTHX_ "Unknown branch type '%s'", type_str);
		}

		repo = GIT_SV_TO_PTR(Repository, self);

		rc = git_branch_iterator_new(&itr, repo, type);
		git_check_error(rc);

		while ((rc = git_branch_next(&branch, &type, itr)) == 0) {
			SV *perl_ref;

			GIT_NEW_OBJ_WITH_MAGIC(
				perl_ref, "Git::Raw::Branch", branch, SvRV(self)
			);

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

		int num_remotes = 0;
		git_strarray remotes;

		Repository repo;

	PPCODE:
		repo = GIT_SV_TO_PTR(Repository, self);

		rc = git_remote_list(&remotes, repo);
		git_check_error(rc);

		for (i = 0; i < remotes.count; i++) {
			SV *perl_ref;
			git_remote *r = NULL;
			Remote remote = NULL;

			rc = git_remote_load(&r, repo, remotes.strings[i]);
			git_check_error(rc);

			Newx(remote, 1, git_raw_remote);
			git_init_remote_callbacks(&remote -> callbacks);
			remote -> remote = r;

			GIT_NEW_OBJ_WITH_MAGIC(
				perl_ref, "Git::Raw::Remote", remote, SvRV(self)
			);

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

			GIT_NEW_OBJ_WITH_MAGIC(
				perl_ref, "Git::Raw::Reference", ref, SvRV(self)
			);

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
			const char *new_dir = NULL;

			if (!SvPOK(ST(1)))
				Perl_croak(aTHX_ "Expected a string for 'new_dir'");

			new_dir = SvPVbyte_nolen(ST(1));

			rc = git_repository_set_workdir(self, new_dir, 1);
			git_check_error(rc);
		}

		path = git_repository_workdir(self);
		RETVAL = newSVpv(path, 0);

	OUTPUT: RETVAL

SV *
blame (self, file)
	SV *self
	const char *file

	PREINIT:
		int rc;
		Blame blame;

		git_blame_options options = GIT_BLAME_OPTIONS_INIT;

	CODE:
		rc = git_blame_file(
			&blame, GIT_SV_TO_PTR(Repository, self), file, &options);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Blame", blame, SvRV(self)
		);

	OUTPUT: RETVAL

SV *
state(self)
	Repository self

	PREINIT:
		int rc;
		const char *s;

	CODE:
		rc = git_repository_state(self);

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

		RETVAL = newSVpv(s, 0);

	OUTPUT: RETVAL

void
state_cleanup(self)
	Repository self

	PREINIT:
		int rc;

	CODE:
		rc = git_repository_state_cleanup(self);
		git_check_error(rc);

SV *
message(self)
	Repository self

	PREINIT:
		int rc;

		git_buf buf = GIT_BUF_INIT_CONST(NULL, 0);

	CODE:
		rc = git_repository_message(&buf, self);
		if (rc != GIT_OK)
			git_buf_free(&buf);
		git_check_error(rc);

		RETVAL = newSVpv(buf.ptr, 0);
		git_buf_free(&buf);

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

SV *
is_head_detached(self)
	Repository self

	CODE:
		RETVAL = newSViv(git_repository_head_detached(self));

	OUTPUT: RETVAL

void
DESTROY(self)
	Repository self

	CODE:
		git_repository_free(self);
