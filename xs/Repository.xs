MODULE = Git::Raw			PACKAGE = Git::Raw::Repository

Repository
init(class, path, is_bare)
	SV *class
	SV *path
	unsigned is_bare

	CODE:
		Repository r;
		const char *path_str = SvPVbyte_nolen(path);

		int rc = git_repository_init(&r, path_str, is_bare);
		git_check_error(rc);

		RETVAL = r;

	OUTPUT: RETVAL

Repository
open(class, path)
	SV *class
	SV *path

	CODE:
		Repository r;
		const char *path_str = SvPVbyte_nolen(path);

		int rc = git_repository_open(&r, path_str);
		git_check_error(rc);

		RETVAL = r;

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
	Repository self

	CODE:
		git_object *o;
		git_reference *r;
		const git_oid *oid;

		int rc = git_repository_head(&r, self);
		git_check_error(rc);

		oid = git_reference_oid(r);

		rc = git_object_lookup(&o, self, oid, GIT_OBJ_ANY);
		git_check_error(rc);

		RETVAL = git_obj_to_sv(o);

	OUTPUT: RETVAL

SV *
lookup(self, id)
	Repository self
	SV *id

	CODE:
		STRLEN len;
		git_oid oid;
		git_object *o;

		int rc = git_oid_fromstrn(&oid, SvPVbyte(id, len), len);
		git_check_error(rc);

		rc = git_object_lookup_prefix(&o, self, &oid, len, GIT_OBJ_ANY);
		git_check_error(rc);

		RETVAL = git_obj_to_sv(o);

	OUTPUT: RETVAL

Commit
commit(self, msg, author, cmtter, parents, tree)
	Repository self
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

				if (sv_isobject(iter) && sv_derived_from(iter, "Git::Raw::Commit"))
					paren[i] = INT2PTR(git_commit *, SvIV((SV *) SvRV(iter)));
				else Perl_croak(aTHX_ "parent is not of type Git::Raw::Commit");
			}
		}

		int rc = git_commit_create(
			&oid, self, "HEAD", author, cmtter, NULL,
			SvPVbyte_nolen(msg), tree, count,
			(const git_commit **) paren
		);
		git_check_error(rc);

		rc = git_commit_lookup(&c, self, &oid);
		git_check_error(rc);

		RETVAL = c;

	OUTPUT: RETVAL

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
			av_push(flags, newSVpv(":index_new", 0));

		if (iflags & GIT_STATUS_INDEX_MODIFIED)
			av_push(flags, newSVpv(":index_modified", 0));

		if (iflags & GIT_STATUS_INDEX_DELETED)
			av_push(flags, newSVpv(":index_deleted", 0));

		if (iflags & GIT_STATUS_WT_NEW)
			av_push(flags, newSVpv(":worktree_new", 0));

		if (iflags & GIT_STATUS_WT_MODIFIED)
			av_push(flags, newSVpv(":worktree_modified", 0));

		if (iflags & GIT_STATUS_WT_DELETED)
			av_push(flags, newSVpv(":worktree_deleted", 0));

		if (iflags & GIT_STATUS_IGNORED)
			av_push(flags, newSVpv(":ignored", 0));

		RETVAL = flags;

	OUTPUT: RETVAL

Tag
tag(self, name, msg, tagger, target)
	Repository self
	SV *name
	SV *msg
	Signature tagger
	SV *target

	CODE:
		Tag t;
		git_oid oid;
		git_object *o;

		o = git_sv_to_obj(target);

		if (o == NULL)
			Perl_croak(aTHX_ "target is not of a valid type");

		int rc = git_tag_create(
			&oid, self, SvPVbyte_nolen(name),
			o, tagger, SvPVbyte_nolen(msg), 0
		);
		git_check_error(rc);

		rc = git_tag_lookup(&t, self, &oid);
		git_check_error(rc);

		RETVAL = t;

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

Walker
walker(self)
	Repository self

	CODE:
		Walker w;

		int rc = git_revwalk_new(&w, self);
		git_check_error(rc);

		RETVAL = w;

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
