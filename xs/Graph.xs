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
		if (git_sv_to_commitish(repo, commitish, &commitish_id) == NULL)
			Perl_croak(aTHX_ "Could not resolve 'commitish' to a commit id");

		if (git_sv_to_commitish(repo, ancestor, &ancestor_id) == NULL)
			Perl_croak(aTHX_ "Could not resolve 'ancestor' to a commit id");

		result = git_graph_descendant_of(repo, &commitish_id, &ancestor_id);

		RETVAL = newSViv(result);

	OUTPUT: RETVAL
