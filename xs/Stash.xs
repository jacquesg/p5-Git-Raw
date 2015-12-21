MODULE = Git::Raw			PACKAGE = Git::Raw::Stash

void
apply(class, repo, index, ...)
	SV *class
	Repository repo
	size_t index

	PREINIT:
		int rc;

		git_stash_apply_options stash_apply_opts = GIT_STASH_APPLY_OPTIONS_INIT;

	CODE:
		if (items >= 4) {
			HV *opts = git_ensure_hv(ST(3), "stash_apply_opts");
			git_hv_to_stash_apply_opts(opts, &stash_apply_opts);
		}

		rc = git_stash_apply(
			repo -> repository,
			index,
			&stash_apply_opts
		);
		git_check_error(rc);

void
pop(class, repo, index, ...)
	SV *class
	Repository repo
	size_t index

	PREINIT:
		int rc;

		git_stash_apply_options stash_apply_opts = GIT_STASH_APPLY_OPTIONS_INIT;

	CODE:
		if (items >= 4) {
			HV *opts = git_ensure_hv(ST(3), "stash_apply_opts");
			git_hv_to_stash_apply_opts(opts, &stash_apply_opts);
		}

		rc = git_stash_pop(
			repo -> repository,
			index,
			&stash_apply_opts
		);
		git_check_error(rc);

SV *
save(class, repo, stasher, msg, ...)
	SV *class
	SV *repo
	Signature stasher
	SV *msg

	PROTOTYPE: $$$$;$

	PREINIT:
		int rc;

		Repository repo_ptr;

		git_oid oid;
		unsigned int stash_flags = GIT_STASH_DEFAULT;

	CODE:
		repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		if (items == 5) {
			AV *flags;
			SV **flag;
			size_t i = 0, count = 0;

			flags = git_ensure_av(ST(4), "opts");

			while ((flag = av_fetch(flags, i++, 0))) {
				const char *opt = NULL;
				if (!SvPOK(*flag))
					continue;

				opt = git_ensure_pv(*flag, "flag");

				if (strcmp(opt, "keep_index") == 0)
					stash_flags |= GIT_STASH_KEEP_INDEX;
				else if (strcmp(opt, "include_untracked") == 0)
					stash_flags |= GIT_STASH_INCLUDE_UNTRACKED;
				else if (strcmp(opt, "include_ignored") == 0)
					stash_flags |= GIT_STASH_INCLUDE_IGNORED;
				else
					croak_usage("Unknown value for flag '%s', expected "
						"'keep_index', 'include_untracked' or 'include_ignored'",
						opt);

				++count;
			}
		}

		rc = git_stash_save(&oid, repo_ptr -> repository,
			stasher,
			git_ensure_pv(msg, "msg"),
			stash_flags
		);

		RETVAL = &PL_sv_undef;
		if (rc != GIT_ENOTFOUND) {
			Commit commit;
			git_check_error(rc);

			rc = git_commit_lookup(&commit,
				repo_ptr -> repository, &oid
			);
			git_check_error(rc);

			GIT_NEW_OBJ_WITH_MAGIC(
				RETVAL, "Git::Raw::Commit", commit, SvRV(repo)
			);
		}

	OUTPUT: RETVAL

void
foreach(class, repo, cb)
	SV *class
	SV *repo
	SV *cb

	PREINIT:
		int rc;

	CODE:
		git_foreach_payload payload = {
			GIT_SV_TO_PTR(Repository, repo),
			repo,
			git_ensure_cv(cb, "callback")
		};

		rc = git_stash_foreach(
			payload.repo_ptr -> repository, git_stash_foreach_cb, &payload
		);
		if (rc != GIT_EUSER)
			git_check_error(rc);

void
drop(class, repo, index)
	SV *class
	Repository repo
	size_t index

	PREINIT:
		int rc;

	CODE:
		rc = git_stash_drop(repo -> repository, index);
		git_check_error(rc);
