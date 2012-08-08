MODULE = Git::Raw			PACKAGE = Git::Raw::Commit

Signature
author(self)
	Commit self

	CODE:
		Signature a = git_commit_author(self);
		RETVAL = git_signature_dup(a);

	OUTPUT: RETVAL

Signature
committer(self)
	Commit self

	CODE:
		Signature c = git_commit_committer(self);
		RETVAL = git_signature_dup(c);

	OUTPUT: RETVAL

SV *
id(self)
	Commit self

	CODE:
		char out[41];
		const git_oid *oid = git_commit_id(self);

		git_oid_fmt(out, oid);
		out[40] = '\0';

		RETVAL = newSVpv(out, 0);

	OUTPUT: RETVAL

SV *
message(self)
	Commit self

	CODE:
		const char *msg = git_commit_message(self);
		RETVAL = newSVpv(msg, 0);

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
		Tree t;

		int rc = git_commit_tree(&t, self);
		git_check_error(rc);

		RETVAL = t;

	OUTPUT: RETVAL

AV *
parents(self)
	Commit self

	CODE:
		AV *parents = newAV();
		int rc, i, count = git_commit_parentcount(self);

		for (i = 0; i < count; i++) {
			Commit curr;
			rc = git_commit_parent(&curr, self, i);
			git_check_error(rc);

			SV *parent = sv_setref_pv(
				newSV(0), "Git::Raw::Commit", (void *) curr
			);

			av_push(parents, parent);
		}

		RETVAL = parents;

	OUTPUT: RETVAL

void
DESTROY(self)
	Commit self

	CODE:
		git_commit_free(self);
