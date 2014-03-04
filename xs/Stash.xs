MODULE = Git::Raw			PACKAGE = Git::Raw::Stash

void
save(class, repo, stasher, msg, ...)
	SV *class
	Repository repo
	Signature stasher
	SV *msg

	PROTOTYPE: $$$$;$

	PREINIT:
		int rc;

		git_oid oid;
		unsigned int flags = GIT_STASH_DEFAULT;

	CODE:
		if (items == 5) {
			SV **flag;
			size_t count = 0;

			if (!SvROK(ST(4)) || SvTYPE(SvRV(ST(4))) != SVt_PVAV)
				Perl_croak(aTHX_ "Invalid type");

			while ((flag = av_fetch((AV *) SvRV(ST(4)), count++, 0))) {
				if (SvPOK(*flag)) {
					const char *opt = SvPVbyte_nolen(*flag);

					if (strcmp(opt, "keep_index") == 0)
						flags |= GIT_STASH_KEEP_INDEX;
					else if (strcmp(opt, "include_untracked") == 0)
						flags |= GIT_STASH_INCLUDE_UNTRACKED;
					else if (strcmp(opt, "include_ignored") == 0)
						flags |= GIT_STASH_INCLUDE_IGNORED;
				}
			}
		}

		rc = git_stash_save(&oid, repo, stasher, SvPVbyte_nolen(msg), flags);
		git_check_error(rc);

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
			cb,
			NULL
		};

		rc = git_stash_foreach(
			payload.repo_ptr, git_stash_foreach_cb, &payload
		);

		git_check_error(rc);

void
drop(class, repo, index)
	SV *class
	Repository repo
	size_t index

	PREINIT:
		int rc;

	CODE:
		rc = git_stash_drop(repo, index);
		git_check_error(rc);
