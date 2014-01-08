MODULE = Git::Raw			PACKAGE = Git::Raw::Commit

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
		int count, rc;
		git_oid oid;
		Commit commit, *commit_parents = NULL;
		const char *update_ref = "HEAD";

	CODE:
		if(items > 7) {
			SV *sv_update_ref = ST(7);

			if (SvOK(sv_update_ref)) {
				update_ref = SvPVbyte_nolen(sv_update_ref);
			} else {
				update_ref = NULL;
			}
		}

		count = av_len(parents) + 1;

		if (count > 0) {
			int i; SV *iter;

			Newx(commit_parents, count, git_commit *);

			for (i = 0; i < count; i++) {
				iter = av_shift(parents);

				commit_parents[i] = GIT_SV_TO_PTR(Commit, iter);
			}
		}

		rc = git_commit_create(
			&oid, GIT_SV_TO_PTR(Repository, repo), update_ref, author, committer, NULL,
			SvPVbyte_nolen(msg), tree, count,
			(const git_commit **) commit_parents
		);
		git_check_error(rc);

		rc = git_commit_lookup(&commit, GIT_SV_TO_PTR(Repository, repo), &oid);
		git_check_error(rc);

		GIT_NEW_OBJ(RETVAL, SvPVbyte_nolen(class), commit, SvRV(repo));

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
		const char *id_str = SvPVbyte(id, len);

	CODE:
		rc = git_oid_fromstrn(&oid, id_str, len);
		git_check_error(rc);

		repo_ptr = GIT_SV_TO_PTR(Repository, repo);
		rc = git_commit_lookup_prefix(&commit, repo_ptr, &oid, len);
		git_check_error(rc);

		GIT_NEW_OBJ(RETVAL, SvPVbyte_nolen(class), commit, SvRV(repo));

	OUTPUT: RETVAL

SV *
id(self)
	Commit self

	PREINIT:
		const git_oid *oid;

	CODE:
		oid = git_commit_id(self);
		RETVAL = git_oid_to_sv((git_oid *) oid);

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

Signature
author(self)
	Commit self

	PREINIT:
		Signature a;

	CODE:
		a = (Signature) git_commit_author(self);
		RETVAL = git_signature_dup(a);

	OUTPUT: RETVAL

Signature
committer(self)
	Commit self

	PREINIT:
		Signature c;

	CODE:
		c = (Signature) git_commit_committer(self);
		RETVAL = git_signature_dup(c);

	OUTPUT: RETVAL

SV *
time(self)
	Commit self

	PREINIT:
		char *buf;
		git_time_t time;

	CODE:
		time = git_commit_time(self);

		Newx(buf, snprintf(NULL, 0, "%" PRId64, time)+1, char);
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
		Tree tree;
		SV *repo;

	CODE:
		repo = GIT_SV_TO_REPO(self);
		rc = git_commit_tree(&tree, GIT_SV_TO_PTR(Commit, self));
		git_check_error(rc);

		GIT_NEW_OBJ(RETVAL, "Git::Raw::Tree", tree, repo);

	OUTPUT: RETVAL

AV *
parents(self)
	SV *self

	PREINIT:
		int rc, i, count;
		SV *repo;

		AV *parents;
		Commit child;

	CODE:
		repo = GIT_SV_TO_REPO(self);
		child = GIT_SV_TO_PTR(Commit, self);
		count = git_commit_parentcount(child);
		parents = newAV();

		for (i = 0; i < count; i++) {
			SV *tmp;
			Commit parent;

			rc = git_commit_parent(&parent, child, i);
			git_check_error(rc);

			GIT_NEW_OBJ(tmp, "Git::Raw::Commit", parent, repo);
			av_push(parents, tmp);
		}

		RETVAL = parents;

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		git_commit_free(GIT_SV_TO_PTR(Commit, self));
		SvREFCNT_dec(xs_object_magic_get_struct(aTHX_ SvRV(self)));
