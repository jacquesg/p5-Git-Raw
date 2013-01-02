MODULE = Git::Raw			PACKAGE = Git::Raw::Repository

SV *
init(class, path, is_bare)
	SV *class
	SV *path
	unsigned is_bare

	CODE:
		Repository r;
		const char *path_str = SvPVbyte_nolen(path);

		int rc = git_repository_init(&r, path_str, is_bare);
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), r);

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

		/* Bare repository check */
		if ((opt = hv_fetchs(opts, "bare", 0)) && (SvIV(*opt) != 0))
			clone_opts.bare = 1;
		else
			clone_opts.bare = 0;

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
		Repository r;
		const char *path_str = SvPVbyte_nolen(path);

		int rc = git_repository_open(&r, path_str);
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), r);

	OUTPUT: RETVAL

SV *
discover(class, path)
	SV *class
	SV *path

	CODE:
		Repository r;
		char path_str[GIT_PATH_MAX];
		const char *start = SvPVbyte_nolen(path);

		int rc = git_repository_discover(
			path_str, GIT_PATH_MAX, start, 1, NULL
		);
		git_check_error(rc);

		rc = git_repository_open(&r, path_str);
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), r);

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

Index
index(self)
	Repository self

	CODE:
		Index out;

		int rc = git_repository_index(&out, self);
		git_check_error(rc);

		RETVAL = out;

	OUTPUT: RETVAL

SV *
head(self)
	SV *self

	CODE:
		Reference r;

		int rc = git_repository_head(&r, GIT_SV_TO_PTR(Repository, self));
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), "Git::Raw::Reference", r); \
		xs_object_magic_attach_struct(
			aTHX_ SvRV(RETVAL),
			SvREFCNT_inc_NN(SvRV(self))
		);

	OUTPUT: RETVAL

SV *
lookup(self, id)
	Repository self
	SV *id

	CODE:
		git_oid oid;
		git_object *o;

		STRLEN len;
		const char *id_str = SvPVbyte(id, len);

		int rc = git_oid_fromstrn(&oid, id_str, len);
		git_check_error(rc);

		rc = git_object_lookup_prefix(&o, self, &oid, len, GIT_OBJ_ANY);
		git_check_error(rc);

		RETVAL = git_obj_to_sv(o);

	OUTPUT: RETVAL

void
checkout(self, target, strategy)
	Repository self
	SV *target
	HV *strategy

	CODE:
		int rc;
		git_checkout_opts opts = GIT_CHECKOUT_OPTS_INIT;

		opts.checkout_strategy = git_hv_to_checkout_strategy(strategy);

		rc = git_checkout_tree(self, git_sv_to_obj(target), &opts);
		git_check_error(rc);

void
reset(self, target, type)
	Repository self
	SV *target
	SV *type

	CODE:
		int rc;
		STRLEN len;
		git_reset_t t;
		const char *type_str = SvPVbyte(type, len);

		if (strcmp(type_str, "soft"))
			t = GIT_RESET_SOFT;

		if (strcmp(type_str, "mixed"))
			t = GIT_RESET_MIXED;

		rc = git_reset(self, git_sv_to_obj(target), t);
		git_check_error(rc);

AV *
status(self, path)
	Repository self
	SV *path

	CODE:
		unsigned iflags;
		AV *flags = newAV();
		const char *file = SvPVbyte_nolen(path);

		int rc = git_status_file(&iflags, self, file);
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
		const char *rules_str = SvPVbyte_nolen(rules);

		int rc = git_ignore_add_rule(self, rules_str);
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
			Remote r;
			SV *remote;

			rc = git_remote_load(&r, self, remotes.strings[i]);
			git_check_error(rc);

			remote = sv_setref_pv(newSV(0), "Git::Raw::Remote", r);

			av_push(output, remote);
		}

		git_strarray_free(&remotes);

		RETVAL = output;

	OUTPUT: RETVAL

SV *
path(self)
	Repository self

	CODE:
		const char *path = git_repository_path(self);
		RETVAL = newSVpv(path, 0);

	OUTPUT: RETVAL

SV *
workdir(self)
	Repository self

	CODE:
		const char *path = git_repository_workdir(self);
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
DESTROY(self)
	Repository self

	CODE:
		git_repository_free(self);
