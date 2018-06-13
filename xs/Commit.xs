MODULE = Git::Raw			PACKAGE = Git::Raw::Commit

SV *
annotated(self)
	SV *self

	PREINIT:
		int rc;

		SV *repo;
		AnnotatedCommit commit;
		Repository repo_ptr;

	CODE:
		repo = GIT_SV_TO_MAGIC(self);
		repo_ptr = INT2PTR(Repository, SvIV((SV *) repo));

		rc = git_annotated_commit_lookup(&commit,
			repo_ptr -> repository,
			git_commit_id(GIT_SV_TO_PTR(Commit, self))
		);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::AnnotatedCommit",
			commit, repo
		);

	OUTPUT: RETVAL

SV *
create(class, repo, msg, author, committer, parents, tree, ...)
	SV *class
	SV *repo
	SV *msg
	Signature author
	Signature committer
	AV *parents
	Tree tree

	PREINIT:
		int rc;

		SV **c;
		size_t i = 0, count = 0;
		git_oid oid;

		Repository repo_ptr;

		const char *update_ref = "HEAD";

		Commit commit, *commit_parents = NULL;

	CODE:
		if (items > 7) {
			SV *sv_update_ref = ST(7);

			if (SvOK(sv_update_ref))
				update_ref = git_ensure_pv(sv_update_ref, "update_ref");
			else
				update_ref = NULL;
		}

		while ((c = av_fetch(parents, i++, 0))) {
			if (!c || !SvOK(*c))
				continue;

			Renew(commit_parents, count + 1, git_commit *);
			commit_parents[count++] = GIT_SV_TO_PTR(Commit, *c);
		}

		repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		rc = git_commit_create(
			&oid, repo_ptr -> repository, update_ref, author, committer, NULL,
			git_ensure_pv(msg, "msg"), tree, count,
			(const git_commit **) commit_parents
		);

		Safefree(commit_parents);
		git_check_error(rc);

		rc = git_commit_lookup(&commit, repo_ptr -> repository, &oid);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, SvPVbyte_nolen(class), commit, SvRV(repo)
		);

	OUTPUT: RETVAL

SV *
lookup(class, repo, id)
	SV *class
	SV *repo
	SV *id

	PREINIT:
		int rc;

		git_oid oid;

		Commit commit;
		Repository repo_ptr;

		STRLEN len;
		const char *id_str;

	INIT:
		id_str = git_ensure_pv_with_len(id, "id", &len);

	CODE:
		rc = git_oid_fromstrn(&oid, id_str, len);
		git_check_error(rc);

		repo_ptr = GIT_SV_TO_PTR(Repository, repo);
		rc = git_commit_lookup_prefix(&commit, repo_ptr -> repository, &oid, len);

		if (rc == GIT_ENOTFOUND) {
			RETVAL = &PL_sv_undef;
		} else {
			git_check_error(rc);

			GIT_NEW_OBJ_WITH_MAGIC(
				RETVAL, SvPVbyte_nolen(class), commit, SvRV(repo)
			);
		}

	OUTPUT: RETVAL

SV *
owner(self)
	SV *self

	PREINIT:
		SV *repo;

	CODE:
		repo = GIT_SV_TO_MAGIC(self);
		RETVAL = newRV_inc(repo);

	OUTPUT: RETVAL

SV *
id(self)
	Commit self

	CODE:
		RETVAL = git_oid_to_sv(git_commit_id(self));

	OUTPUT: RETVAL

SV *
message(self)
	Commit self

	PREINIT:
		const char *msg;

	CODE:
		msg = git_commit_message(self);
		RETVAL = newSVpv(msg, 0);

	OUTPUT: RETVAL

SV *
message_trailers(self)
	Commit self

	PREINIT:
		int rc;
		size_t i;
		const char *msg;
		git_message_trailer_array trailers = {0};
		HV *result;

	CODE:
		msg = git_commit_message(self);
		if (msg == NULL)
			XSRETURN_UNDEF;

		rc = git_message_trailers(&trailers, msg);
		git_check_error(rc);

		result = newHV();

		for (i = 0; i < trailers.count; ++i) {
			const char *key = trailers.trailers[i].key;
			const char *value = trailers.trailers[i].value;
			STRLEN length = strlen (key);

			if (!hv_exists(result, key, length))
				hv_store(result, key, length, newRV_noinc (MUTABLE_SV (newAV())), 0);

			av_push (MUTABLE_AV (SvRV (*hv_fetch(result, key, length, 0))),
				newSVpv(value, 0));
		}

		git_message_trailer_array_free(&trailers);
		RETVAL = newRV_noinc (MUTABLE_SV (result));

	OUTPUT: RETVAL

SV *
summary(self)
	Commit self

	PREINIT:
		const char *summary;

	CODE:
		summary = git_commit_summary(self);
		RETVAL = newSVpv(summary, 0);

	OUTPUT: RETVAL

SV *
body(self)
	Commit self

	PREINIT:
		const char *body;

	CODE:
		body = git_commit_body(self);
		RETVAL = newSVpv(body, 0);

	OUTPUT: RETVAL

Signature
author(self)
	Commit self

	PREINIT:
		int rc;
		Signature a, r;

	CODE:
		a = (Signature) git_commit_author(self);
		rc = git_signature_dup(&r, a);
		git_check_error(rc);

		RETVAL = r;

	OUTPUT: RETVAL

Signature
committer(self)
	Commit self

	PREINIT:
		int rc;
		Signature c, r;

	CODE:
		c = (Signature) git_commit_committer(self);
		rc = git_signature_dup(&r, c);
		git_check_error(rc);

		RETVAL = r;

	OUTPUT: RETVAL

SV *
time(self)
	Commit self

	PREINIT:
		char *buf;
		git_time_t time;

	CODE:
		time = git_commit_time(self);

		Newx(buf, snprintf(NULL, 0, "%" PRId64, time) + 1, char);
		sprintf(buf, "%" PRId64, time);

		RETVAL = newSVpv(buf, 0);
		Safefree(buf);

	OUTPUT: RETVAL

int
offset(self)
	Commit self

	CODE:
		RETVAL = git_commit_time_offset(self);

	OUTPUT: RETVAL

SV *
tree(self)
	SV *self

	PREINIT:
		int rc;

		SV *repo;
		Tree tree;

	CODE:
		repo = GIT_SV_TO_MAGIC(self);

		rc = git_commit_tree(&tree, GIT_SV_TO_PTR(Commit, self));
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(RETVAL, "Git::Raw::Tree", tree, repo);

	OUTPUT: RETVAL

void
parents(self)
	SV *self

	PREINIT:
		int ctx;

	PPCODE:
		ctx = GIMME_V;

		if (ctx != G_VOID) {
			int rc, count;
			Commit child;
			SV *repo = GIT_SV_TO_MAGIC(self);

			child = GIT_SV_TO_PTR(Commit, self);
			count = git_commit_parentcount(child);

			if (ctx == G_ARRAY) {
				int i;

				for (i = 0; i < count; i++) {
					SV *tmp;
					Commit parent;

					rc = git_commit_parent(&parent, child, i);
					git_check_error(rc);

					GIT_NEW_OBJ_WITH_MAGIC(
						tmp, "Git::Raw::Commit", parent, repo
					);
					mXPUSHs(tmp);
				}

				XSRETURN((int) count);
			} else {
				mXPUSHs(newSViv((int) count));
				XSRETURN(1);
			}
		} else
			XSRETURN_EMPTY;

SV *
merge(self, commit, ...)
	SV *self
	Commit commit

	PROTOTYPE: $;$;$
	PREINIT:
		int rc;

		SV *repo;
		Repository repo_ptr;

		Index index;
		git_merge_options merge_opts = GIT_MERGE_OPTIONS_INIT;

	CODE:
		repo = GIT_SV_TO_MAGIC(self);
		repo_ptr = INT2PTR(Repository, SvIV((SV *) repo));

		if (items == 3) {
			HV *opts = git_ensure_hv(ST(2), "merge_opts");
			git_hv_to_merge_opts(opts, &merge_opts);
		}

		rc = git_merge_commits(
			&index,
			repo_ptr -> repository,
			GIT_SV_TO_PTR(Commit, self),
			commit, &merge_opts);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Index", index, repo
		);

	OUTPUT: RETVAL

SV *
ancestor(self, gen)
	SV *self
	unsigned int gen

	PREINIT:
		int rc;

		SV *repo;
		Commit anc;

	CODE:
		repo = GIT_SV_TO_MAGIC(self);

		rc = git_commit_nth_gen_ancestor(
				&anc,
				GIT_SV_TO_PTR(Commit, self),
				gen
		);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Commit", anc, repo
		);

	OUTPUT: RETVAL

SV *
as_email(commit, ...)
	Commit commit

	PROTOTYPE: $;$$
	PREINIT:
		int rc;

		git_repository *repo;
		git_buf buf = GIT_BUF_INIT_CONST(NULL, 0);
		git_diff_options diff_opts = GIT_DIFF_OPTIONS_INIT;
		git_diff_format_email_flags_t flags = GIT_DIFF_FORMAT_EMAIL_NONE;

		size_t patch_no = 1, total_patches = 1;

	CODE:
		if (items >= 2) {
			if (SvOK(ST(1))) {
				SV *opt;
				HV *hopt;
				HV *opts;

				opts = git_ensure_hv(ST(1), "format_opts");

				if ((opt = git_hv_int_entry(opts, "patch_no")))
					patch_no = (size_t) SvIV(opt);

				if ((opt = git_hv_int_entry(opts, "total_patches")))
					total_patches = (size_t) SvIV(opt);

				if ((hopt = git_hv_hash_entry(opts, "flags"))) {
					if ((opt = git_hv_int_entry(hopt, "exclude_subject_patch_marker"))) {
						if (SvIV(opt))
							flags |= GIT_DIFF_FORMAT_EMAIL_EXCLUDE_SUBJECT_PATCH_MARKER;
					}
				}
			}
		}

		if (items >= 3) {
			HV *opts  = git_ensure_hv(ST(2), "diff_opts");
			git_hv_to_diff_opts(opts, &diff_opts, NULL);
		}

		repo = git_commit_owner(commit);

		rc = git_diff_commit_as_email(
			&buf, repo, commit,
			patch_no, total_patches,
			flags,
			&diff_opts
		);
		if (rc != GIT_OK) {
			git_buf_free(&buf);
			git_check_error(rc);
		}

		RETVAL = newSVpv(buf.ptr, buf.size);
		git_buf_free(&buf);

	OUTPUT: RETVAL

SV *
diff(self, ...)
	SV *self

	PROTOTYPE: $;$$
	PREINIT:
		int rc;
		unsigned int parent_count, requested_parent = 0;

		SV *repo;
		Repository repo_ptr;

		Diff diff;
		Commit commit, parent = NULL;
		Tree our_tree = NULL, parent_tree = NULL;

		git_diff_options diff_opts = GIT_DIFF_OPTIONS_INIT;

	CODE:
		commit = GIT_SV_TO_PTR(Commit, self);

		parent_count = git_commit_parentcount(commit);
		if (items >= 2) {
			if (SvOK(ST(1))) {
				if (parent_count == 0)
					croak_usage("Commit has no parents");

				requested_parent = git_ensure_iv(ST(1), "parent");
			}
		}

		if (items >= 3) {
			HV *opts  = git_ensure_hv(ST(2), "diff_opts");
			git_hv_to_diff_opts(opts, &diff_opts, NULL);
		}

		if (parent_count > 0) {
			if (requested_parent > (parent_count - 1))
				croak_usage("Commit parent %u is out of range", requested_parent);

			rc = git_commit_parent(&parent, commit, 0);
			git_check_error(rc);

			rc = git_commit_tree(&parent_tree, parent);
			git_check_error(rc);
		}

		rc = git_commit_tree(&our_tree, commit);
		git_check_error(rc);

		repo = GIT_SV_TO_MAGIC(self);
		repo_ptr = INT2PTR(Repository, SvIV((SV *) repo));

		rc = git_diff_tree_to_tree(
			&diff, repo_ptr -> repository,
			parent_tree, our_tree, &diff_opts
		);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Diff", diff, repo
		);

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		git_commit_free(GIT_SV_TO_PTR(Commit, self));
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
