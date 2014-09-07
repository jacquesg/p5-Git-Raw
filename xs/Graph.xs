MODULE = Git::Raw			PACKAGE = Git::Raw::Graph

SV *
ahead_behind(class, repo, local, upstream)
	SV *class
	SV *repo
	SV *local
	SV *upstream

	PREINIT:
		int rc;

		Repository repo_ptr;

		size_t i, ahead, behind;
		git_oid local_id, upstream_id;

		git_revwalk *walker = NULL;
		HV *r = NULL;
		AV *a = NULL, *b = NULL;

	CODE:
		repo_ptr = GIT_SV_TO_PTR(Repository, repo);
		if (git_sv_to_commitish(repo_ptr -> repository, local, &local_id) == NULL)
			croak_resolve("Could not resolve 'local' to a commit id");

		if (git_sv_to_commitish(repo_ptr -> repository, upstream, &upstream_id) == NULL)
			croak_resolve("Could not resolve 'upstream' to a commit id");

		rc = git_graph_ahead_behind(
			&ahead, &behind,
			repo_ptr -> repository,
			&local_id, &upstream_id
		);
		git_check_error(rc);

		r = newHV();
		if (ahead > 0 || behind > 0) {
			git_oid commit_id;
			Commit commit;
			SV *c = NULL;

			rc = git_revwalk_new(&walker, repo_ptr -> repository);
			git_check_error(rc);

			if (ahead > 0) {
				git_revwalk_reset(walker);
				git_revwalk_sorting(walker, GIT_SORT_TOPOLOGICAL);
				rc = git_revwalk_push(walker, &local_id);
				git_check_error(rc);

				a = newAV();
				for (i = 0; i < ahead; ++i) {
					rc = git_revwalk_next(&commit_id, walker);
					git_check_error(rc);

					rc = git_commit_lookup(
						&commit, repo_ptr -> repository,
						&commit_id
					);
					git_check_error(rc);

					GIT_NEW_OBJ_WITH_MAGIC(
						c, "Git::Raw::Commit", commit, SvRV(repo)
					);
					av_push(a, c);
				}

				hv_stores(r, "ahead", newRV_noinc((SV *) a));
			}

			if (behind > 0) {
				git_revwalk_reset(walker);
				git_revwalk_sorting(walker, GIT_SORT_TOPOLOGICAL);
				rc = git_revwalk_push(walker, &upstream_id);
				git_check_error(rc);

				b = newAV();
				for (i = 0; i < behind; ++i) {
					rc = git_revwalk_next(&commit_id, walker);
					git_check_error(rc);

					rc = git_commit_lookup(
						&commit, repo_ptr -> repository,
						&commit_id
					);
					git_check_error(rc);

					GIT_NEW_OBJ_WITH_MAGIC(
						c, "Git::Raw::Commit", commit, SvRV(repo)
					);
					av_push(b, c);
				}

				hv_stores(r, "behind", newRV_noinc((SV *) b));
			}
		}

		git_revwalk_free(walker);
		RETVAL = newRV_noinc((SV *) r);

	OUTPUT: RETVAL

SV *
is_descendant_of(class, repo, commitish, ancestor)
	SV *class
	Repository repo
	SV *commitish
	SV *ancestor

	PREINIT:
		int result = 0;

		git_oid commitish_id, ancestor_id;

	CODE:
		if (git_sv_to_commitish(repo -> repository, commitish, &commitish_id) == NULL)
			croak_resolve("Could not resolve 'commitish' to a commit id");

		if (git_sv_to_commitish(repo -> repository, ancestor, &ancestor_id) == NULL)
			croak_resolve("Could not resolve 'ancestor' to a commit id");

		result = git_graph_descendant_of(repo -> repository, &commitish_id, &ancestor_id);

		RETVAL = newSViv(result);

	OUTPUT: RETVAL
