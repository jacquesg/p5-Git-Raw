MODULE = Git::Raw			PACKAGE = Git::Raw::Graph

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
