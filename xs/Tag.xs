MODULE = Git::Raw			PACKAGE = Git::Raw::Tag

SV *
lookup(class, repo, id)
	SV *class
	Repository repo
	SV *id

	CODE:
		STRLEN len;
		git_oid oid;
		git_object *o;

		int rc = git_oid_fromstrn(&oid, SvPVbyte(id, len), len);
		git_check_error(rc);

		rc = git_object_lookup_prefix(&o, repo, &oid, len, GIT_OBJ_TAG);
		git_check_error(rc);

		RETVAL = git_obj_to_sv(o);

	OUTPUT: RETVAL

void
delete(class, repo, name, is_local)
	SV *class
	Repository repo
	SV *name

	CODE:
		int rc = git_tag_delete(repo, SvPVbyte_nolen(name));
		git_check_error(rc);

SV *
id(self)
	Tag self

	CODE:
		const git_oid *oid = git_tag_id(self);
		RETVAL = git_oid_to_sv((git_oid *) oid);

	OUTPUT: RETVAL

SV *
name(self)
	Tag self

	CODE:
		const char *msg = git_tag_name(self);
		RETVAL = newSVpv(msg, 0);

	OUTPUT: RETVAL

SV *
message(self)
	Tag self

	CODE:
		const char *msg = git_tag_message(self);
		RETVAL = newSVpv(msg, 0);

	OUTPUT: RETVAL

Signature
tagger(self)
	Tag self

	CODE:
		Signature c = (Signature) git_tag_tagger(self);
		RETVAL = git_signature_dup(c);

	OUTPUT: RETVAL

SV *
target(self)
	Tag self

	CODE:
		git_object *o;

		int rc = git_tag_target(&o, self);
		git_check_error(rc);

		RETVAL = git_obj_to_sv(o);

	OUTPUT: RETVAL

void
DESTROY(self)
	Tag self

	CODE:
		git_tag_free(self);
