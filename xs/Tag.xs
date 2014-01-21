MODULE = Git::Raw			PACKAGE = Git::Raw::Tag

SV *
create(class, repo, name, msg, tagger, target)
	SV *class
	SV *repo
	SV *name
	SV *msg
	Signature tagger
	SV *target

	PREINIT:
		int rc;
		Tag tag;

		git_oid oid;
		git_object *obj;
		Repository repo_ptr;

	CODE:
		obj = git_sv_to_obj(target);

		if (obj == NULL)
			Perl_croak(aTHX_ "Target is not of a valid type");

		repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		rc = git_tag_create(
			&oid, repo_ptr, SvPVbyte_nolen(name),
			obj, tagger, SvPVbyte_nolen(msg), 0
		);
		git_check_error(rc);

		rc = git_tag_lookup(&tag, repo_ptr, &oid);
		git_check_error(rc);

		GIT_NEW_OBJ(RETVAL, SvPVbyte_nolen(class), tag, SvRV(repo));

	OUTPUT: RETVAL

SV *
lookup(class, repo, id)
	SV *class
	SV *repo
	SV *id

	PREINIT:
		int rc;

		Tag tag;
		git_oid oid;

		STRLEN len;
		const char *id_str;

	CODE:
		id_str = SvPVbyte(id, len);

		rc = git_oid_fromstrn(&oid, id_str, len);
		git_check_error(rc);

		rc = git_tag_lookup_prefix(&tag, GIT_SV_TO_PTR(Repository, repo), &oid, len);
		git_check_error(rc);

		GIT_NEW_OBJ(RETVAL, SvPVbyte_nolen(class), tag, SvRV(repo));

	OUTPUT: RETVAL

void
foreach(class, repo, cb)
	SV *class
	SV *repo
	SV *cb

	PREINIT:
		int rc;

	CODE:
		git_foreach_payload payload = {
			GIT_SV_TO_PTR(Repository, repo),
			repo,
			cb,
			SvPVbyte_nolen(class)
		};

		rc = git_tag_foreach(payload.repo_ptr, git_tag_foreach_cbb, &payload);

		if (rc != GIT_EUSER)
			git_check_error(rc);

void
delete(self)
	SV *self

	PREINIT:
		int rc;

		Tag tag_ptr;
		Repository repo;

	CODE:
		tag_ptr = GIT_SV_TO_PTR(Tag, self);

		repo = INT2PTR(
			Repository, SvIV((SV *) GIT_SV_TO_REPO(self))
		);

		rc = git_tag_delete(repo, git_tag_name(tag_ptr));
		git_check_error(rc);

		git_tag_free(tag_ptr);
		sv_setiv(SvRV(self), 0);

SV *
id(self)
	Tag self

	PREINIT:
		const git_oid *oid;

	CODE:
		oid = git_tag_id(self);
		RETVAL = git_oid_to_sv((git_oid *) oid);

	OUTPUT: RETVAL

SV *
name(self)
	Tag self

	PREINIT:
		const char *name;

	CODE:
		name = git_tag_name(self);
		RETVAL = newSVpv(name, 0);

	OUTPUT: RETVAL

SV *
message(self)
	Tag self

	PREINIT:
		const char *msg;

	CODE:
		msg = git_tag_message(self);
		RETVAL = newSVpv(msg, 0);

	OUTPUT: RETVAL

Signature
tagger(self)
	Tag self

	PREINIT:
		Signature c;

	CODE:
		c = (Signature) git_tag_tagger(self);
		RETVAL = git_signature_dup(c);

	OUTPUT: RETVAL

SV *
target(self)
	SV *self

	PREINIT:
		int rc;
		git_object *obj;

	CODE:
		rc = git_tag_target(&obj, GIT_SV_TO_PTR(Tag, self));
		git_check_error(rc);

		RETVAL = git_obj_to_sv(obj, self);

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		git_tag_free(GIT_SV_TO_PTR(Tag, self));
		SvREFCNT_dec(xs_object_magic_get_struct(aTHX_ SvRV(self)));
