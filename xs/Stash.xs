MODULE = Git::Raw			PACKAGE = Git::Raw::Stash

void
save(class, repo, stasher, msg)
	SV *class
	Repository repo
	Signature stasher
	SV *msg

	PREINIT:
		int rc;
		git_oid oid;
		const char *message;

	CODE:
		message = SvPVbyte_nolen(msg);
		rc = git_stash_save(&oid, repo, stasher, message, 0);
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
			.repo_ptr = GIT_SV_TO_PTR(Repository, repo),
			.repo     = repo,
			.cb       = cb
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
