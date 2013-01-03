MODULE = Git::Raw			PACKAGE = Git::Raw::Commit

SV *
create(class, repo, msg, author, committer, parents, tree)
	SV *class
	Repository repo
	SV *msg
	Signature author
	Signature committer
	AV *parents
	Tree tree

	CODE:
		git_oid oid;
		Commit commit, *commit_parents;

		int count = av_len(parents) + 1;

		if (count > 0) {
			int i; SV *iter;

			Newx(commit_parents, count, git_commit *);

			for (i = 0; i < count; i++) {
				iter = av_shift(parents);

				commit_parents[i] = GIT_SV_TO_PTR(Commit, iter);
			}
		}

		int rc = git_commit_create(
			&oid, repo, "HEAD", author, committer, NULL,
			SvPVbyte_nolen(msg), tree, count,
			(const git_commit **) commit_parents
		);
		git_check_error(rc);

		rc = git_commit_lookup(&commit, repo, &oid);
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), commit);

	OUTPUT: RETVAL

SV *
lookup(class, repo, id)
	SV *class
	Repository repo
	SV *id

	CODE:
		git_oid oid;
		git_object *obj;

		STRLEN len;
		const char *id_str = SvPVbyte(id, len);

		int rc = git_oid_fromstrn(&oid, id_str, len);
		git_check_error(rc);

		rc = git_object_lookup_prefix(&obj, repo, &oid, len, GIT_OBJ_COMMIT);
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), obj);

	OUTPUT: RETVAL

SV *
id(self)
	Commit self

	CODE:
		const git_oid *oid = git_commit_id(self);
		RETVAL = git_oid_to_sv((git_oid *) oid);

	OUTPUT: RETVAL

SV *
message(self)
	Commit self

	CODE:
		const char *msg = git_commit_message(self);
		RETVAL = newSVpv(msg, 0);

	OUTPUT: RETVAL

Signature
author(self)
	Commit self

	CODE:
		Signature a = (Signature) git_commit_author(self);
		RETVAL = git_signature_dup(a);

	OUTPUT: RETVAL

Signature
committer(self)
	Commit self

	CODE:
		Signature c = (Signature) git_commit_committer(self);
		RETVAL = git_signature_dup(c);

	OUTPUT: RETVAL

SV *
time(self)
	Commit self

	CODE:
		git_time_t time = git_commit_time(self);

		const int n = snprintf(NULL, 0, "%" PRId64, time);
		char buf[n+1];

		snprintf(buf, n+1, "%" PRId64, time);

		RETVAL = newSVpv(buf, 0);

	OUTPUT: RETVAL

int
offset(self)
	Commit self

	CODE:
		RETVAL = git_commit_time_offset(self);

	OUTPUT: RETVAL

Tree
tree(self)
	Commit self

	CODE:
		Tree tree;

		int rc = git_commit_tree(&tree, self);
		git_check_error(rc);

		RETVAL = tree;

	OUTPUT: RETVAL

AV *
parents(self)
	Commit self

	CODE:
		AV *parents = newAV();
		int rc, i, count = git_commit_parentcount(self);

		for (i = 0; i < count; i++) {
			Commit parent;

			rc = git_commit_parent(&parent, self, i);
			git_check_error(rc);

			SV *sv = sv_setref_pv(
				newSV(0), "Git::Raw::Commit", parent
			);

			av_push(parents, sv);
		}

		RETVAL = parents;

	OUTPUT: RETVAL

void
DESTROY(self)
	Commit self

	CODE:
		git_commit_free(self);
