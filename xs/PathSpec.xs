MODULE = Git::Raw			PACKAGE = Git::Raw::PathSpec

SV *
new(class, ...)
	SV *class

	PROTOTYPE: $;@
	PREINIT:
		int i, count, rc;

		git_strarray paths = {NULL, 0};

		PathSpec ps;

	CODE:
		if (items == 1)
			croak_usage("No 'paths' provided");

		count = items - 1;
		Newxz(paths.strings, count, char *);
		for (i = 0; i < count; ++i) {
			if (!SvPOK(ST(i + 1))) {
				Safefree(paths.strings);
				croak_usage("Expected a string for 'path'");
			}
			paths.strings[i] = SvPVbyte_nolen(ST(i + 1));
		}

		paths.count = (size_t) count;

		rc = git_pathspec_new(&ps, &paths);
		Safefree(paths.strings);
		git_check_error(rc);

		GIT_NEW_OBJ(
			RETVAL, SvPVbyte_nolen(class), ps
		);

	OUTPUT: RETVAL

SV *
match(self, obj, ...)
	PathSpec self
	SV *obj

	PROTOTYPE: $$;$
	PREINIT:
		unsigned flags = 0;

		git_pathspec_match_list *list = NULL;

	CODE:
		if (items == 3) {
			HV *hopt, *opts = git_ensure_hv(ST(2), "options");

			if ((hopt = git_hv_hash_entry(opts, "flags"))) {
				git_flag_opt(hopt, "ignore_case", GIT_PATHSPEC_IGNORE_CASE, &flags);
				git_flag_opt(hopt, "use_case", GIT_PATHSPEC_USE_CASE, &flags);
				git_flag_opt(hopt, "no_glob", GIT_PATHSPEC_NO_GLOB, &flags);
				git_flag_opt(hopt, "no_match_error", GIT_PATHSPEC_NO_MATCH_ERROR, &flags);
				git_flag_opt(hopt, "find_failures", GIT_PATHSPEC_FIND_FAILURES, &flags);
				git_flag_opt(hopt, "failures_only", GIT_PATHSPEC_FAILURES_ONLY, &flags);
			}
		}

		if (sv_isobject(obj)) {
			int rc = 0;

			if (sv_derived_from(obj, "Git::Raw::Repository")) {
				Repository repo = GIT_SV_TO_PTR(Repository, obj);
				rc = git_pathspec_match_workdir(
					&list,
					repo -> repository,
					flags, self);
			} else if (sv_derived_from(obj, "Git::Raw::Index")) {
				rc = git_pathspec_match_index(
					&list,
					GIT_SV_TO_PTR(Index, obj),
					flags, self);
			} else if (sv_derived_from(obj, "Git::Raw::Tree")) {
				rc = git_pathspec_match_tree(
					&list,
					GIT_SV_TO_PTR(Tree, obj),
					flags, self);
			} else if (sv_derived_from(obj, "Git::Raw::Diff")) {
				rc = git_pathspec_match_diff(
					&list,
					GIT_SV_TO_PTR(Diff, obj),
					flags, self);
			}
			git_check_error(rc);
		}

		if (list == NULL)
			croak_usage("Expected a 'Git::Raw::Repository', 'Git::Raw::Index', "
				"'Git::Raw::Tree' or 'Git::Raw::Diff' object");

		GIT_NEW_OBJ(
			RETVAL, "Git::Raw::PathSpec::MatchList", list
		);

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	PREINIT:
		PathSpec ps;

	CODE:
		ps = GIT_SV_TO_PTR(PathSpec, self);
		git_pathspec_free(ps);
