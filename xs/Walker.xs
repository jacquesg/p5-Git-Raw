MODULE = Git::Raw			PACKAGE = Git::Raw::Walker

SV *
create(class, repo)
	SV *class
	SV *repo

	PREINIT:
		int rc;

		Repository repo_ptr;
		Walker walk;

	CODE:
		repo_ptr = GIT_SV_TO_PTR(Repository, repo);
		rc = git_revwalk_new(&walk, repo_ptr -> repository);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, SvPVbyte_nolen(class), walk, SvRV(repo)
		);

	OUTPUT: RETVAL

void
sorting(self, order)
	Walker self
	SV *order

	PREINIT:
		size_t i = 0;
		AV *order_list;

		SV **entry;
		unsigned int mode = GIT_SORT_NONE;

	CODE:
		order_list = git_ensure_av(order, "order");
		while ((entry = av_fetch(order_list, i++, 0))) {
			if (SvPOK(*entry)) {
				const char *mode_str = SvPVbyte_nolen(*entry);

				if (strcmp(mode_str, "none") == 0)
					mode = GIT_SORT_NONE;
				else if (strcmp(mode_str, "topological") == 0)
					mode |= GIT_SORT_TOPOLOGICAL;
				else if (strcmp(mode_str, "time") == 0)
					mode |= GIT_SORT_TIME;
				else if (strcmp(mode_str, "reverse") == 0)
					mode |= GIT_SORT_REVERSE;
				else
					croak_usage("Invalid 'order' value");
			} else
				croak_usage("Invalid type for 'order' value");
		}

		git_revwalk_sorting(self, mode);

void
push(self, commit)
	Walker self
	Commit commit

	PREINIT:
		int rc;

	CODE:
		rc = git_revwalk_push(self, git_commit_id(commit));
		git_check_error(rc);

void
push_glob(self, glob)
	Walker self
	const char* glob

	PREINIT:
		int rc;

	CODE:
		rc = git_revwalk_push_glob(self, glob);
		git_check_error(rc);

void
push_ref(self, ref)
	Walker self
	const char* ref

	PREINIT:
		int rc;

	CODE:
		rc = git_revwalk_push_ref(self, ref);
		git_check_error(rc);

void
push_head(self)
	Walker self

	PREINIT:
		int rc;

	CODE:
		rc = git_revwalk_push_head(self);
		git_check_error(rc);

void
push_range(self, ...)
	SV *self

	PROTOTYPE: $;@
	PREINIT:
		int rc = 0;

		git_repository *repo;
		Walker walk;

		char *range = NULL;

	CODE:
		walk = GIT_SV_TO_PTR(Walker, self);
		repo = git_revwalk_repository(walk);

		if (items == 3) {
			size_t buffer_size = 2 * GIT_OID_HEXSZ + 2 + 1;
			git_oid start, end;

			if (git_sv_to_commitish(repo, ST(1), &start) == NULL)
				croak_resolve("Could not resolve 'start' to a commit id");
			if (git_sv_to_commitish(repo, ST(2), &end) == NULL)
				croak_resolve("Could not resolve 'end' to a commit id");

			Newx(range, buffer_size, char);

			git_oid_tostr(range, GIT_OID_HEXSZ + 1, &start);
			strncpy(range + GIT_OID_HEXSZ, "..", buffer_size-GIT_OID_HEXSZ);
			git_oid_tostr(range + GIT_OID_HEXSZ + 2, GIT_OID_HEXSZ + 1, &end);
			rc = git_revwalk_push_range(walk, range);
			Safefree(range);
		} else if (items == 2) {
			range = (char *) git_ensure_pv(ST(1), "range");
			rc = git_revwalk_push_range(walk, range);
		} else
			croak_usage("'range' not provided");

		git_check_error(rc);

void
hide(self, commit)
	Walker self
	Commit commit

	PREINIT:
		int rc;

	CODE:
		rc = git_revwalk_hide(self, git_commit_id(commit));
		git_check_error(rc);

void
hide_glob(self, glob)
	Walker self
	char* glob

	PREINIT:
		int rc;

	CODE:
		rc = git_revwalk_hide_glob(self, glob);
		git_check_error(rc);

void
hide_ref(self, ref)
	Walker self
	char* ref

	PREINIT:
		int rc;

	CODE:
		rc = git_revwalk_hide_ref(self, ref);
		git_check_error(rc);

void
hide_head(self)
	Walker self

	PREINIT:
		int rc;

	CODE:
		rc = git_revwalk_hide_head(self);
		git_check_error(rc);

SV *
next(self)
	SV *self

	PREINIT:
		int rc;

		SV *repo;

		Walker walk;

		git_oid oid;
		Commit commit = NULL;

	CODE:
		repo = GIT_SV_TO_MAGIC(self);
		walk = GIT_SV_TO_PTR(Walker, self);

		rc = git_revwalk_next(&oid, walk);
		if (rc == GIT_ITEROVER)
			XSRETURN_UNDEF;
		git_check_error(rc);

		rc = git_commit_lookup(&commit, git_revwalk_repository(walk), &oid);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Commit", commit, repo
		);

	OUTPUT: RETVAL

void
all(self)
	SV *self

	PREINIT:
		int ctx;

	PPCODE:
		ctx = GIMME_V;

		if (ctx != G_VOID) {
			int rc;
			git_oid oid;
			size_t count = 0;
			SV *repo = GIT_SV_TO_MAGIC(self);
			Walker walk = GIT_SV_TO_PTR(Walker, self);

			while ((rc = git_revwalk_next(&oid, walk)) != GIT_ITEROVER) {
				git_check_error(rc);

				if (ctx == G_ARRAY) {
					Commit commit = NULL;
					SV *tmp;

					rc = git_commit_lookup(&commit, git_revwalk_repository(walk), &oid);
					git_check_error(rc);

					GIT_NEW_OBJ_WITH_MAGIC(
						tmp, "Git::Raw::Commit", commit, repo
					);

					mXPUSHs(tmp);
				}

				++count;
			}

			if (ctx == G_ARRAY) {
				XSRETURN((int) count);
			} else {
				mXPUSHs(newSViv((int) count));
				XSRETURN(1);
			}
		} else
			XSRETURN_EMPTY;

void
reset(self)
	Walker self

	CODE:
		git_revwalk_reset(self);

void
DESTROY(self)
	SV *self

	CODE:
		git_revwalk_free(GIT_SV_TO_PTR(Walker, self));
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
