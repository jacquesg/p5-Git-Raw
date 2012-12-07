MODULE = Git::Raw			PACKAGE = Git::Raw::Commit

SV *
create(class, repo, msg, author, cmtter, parents, tree)
	SV *class
	Repository repo
	SV *msg
	Signature author
	Signature cmtter
	AV *parents
	Tree tree

	CODE:
		SV *iter;
		int i = 0;
		git_oid oid;
		Commit c, *paren;

		int count = av_len(parents) + 1;

		if (count > 0) {
			Newx(paren, count, git_commit *);

			for (i = 0; i < count; i++) {
				iter = av_shift(parents);

				if (sv_isobject(iter) &&
				    sv_derived_from(iter, "Git::Raw::Commit"))
					paren[i] = INT2PTR(
						git_commit *,
						SvIV((SV *) SvRV(iter))
					);
				else Perl_croak(aTHX_ "parent is not of type Git::Raw::Commit");
			}
		}

		int rc = git_commit_create(
			&oid, repo, "HEAD", author, cmtter, NULL,
			SvPVbyte_nolen(msg), tree, count,
			(const git_commit **) paren
		);
		git_check_error(rc);

		rc = git_commit_lookup(&c, repo, &oid);
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), c);

	OUTPUT: RETVAL

SV *
lookup(class, repo, id)
	SV *class
	Repository repo
	SV *id

	CODE:
		git_oid oid;
		git_object *o;

		STRLEN len;
		const char *id_str = SvPVbyte(id, len);

		int rc = git_oid_fromstrn(&oid, id_str, len);
		git_check_error(rc);

		rc = git_object_lookup_prefix(&o, repo, &oid, len, GIT_OBJ_COMMIT);
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), o);

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
