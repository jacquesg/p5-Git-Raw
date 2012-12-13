MODULE = Git::Raw			PACKAGE = Git::Raw::Reference

SV *
lookup(class, name, repo)
	SV *class
	SV *name
	Repository repo

	CODE:
		Reference r;

		const char *name_str = SvPVbyte_nolen(name);

		int rc = git_reference_lookup(&r, repo, name_str);
		git_check_error(rc);

		RETVAL = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), r);

	OUTPUT: RETVAL

void
delete(self)
	SV *self

	CODE:
		int rc;
		Reference ref;

		if (sv_isobject(self) && sv_derived_from(self, "Git::Raw::Reference"))
			ref = INT2PTR(Reference, SvIV((SV *) SvRV(self)));
		else
			Perl_croak(aTHX_ "self is not of type Git::Raw::Reference");

		rc = git_reference_delete(ref);
		git_check_error(rc);

		SvROK_off(self);

SV *
name(self)
	Reference self

	CODE:
		const char *msg = git_reference_name(self);
		RETVAL = newSVpv(msg, 0);

	OUTPUT: RETVAL

SV *
type(self)
	Reference self

	CODE:
		SV *type;

		switch (git_reference_type(self)) {
			case GIT_REF_OID: type = newSVpv("direct", 0); break;
			case GIT_REF_SYMBOLIC: type = newSVpv("symbolic", 0); break;
			default: break;
		}

		RETVAL = type;

	OUTPUT: RETVAL

SV *
target(self, repo)
	Reference self
	Repository repo

	CODE:
		int rc;
		SV *result;

		switch (git_reference_type(self)) {
			case GIT_REF_OID: {
				git_object *o;
				const git_oid *oid;

				oid = git_reference_target(self);

				rc = git_object_lookup(
					&o, repo, oid, GIT_OBJ_ANY
				);
				git_check_error(rc);

				result = git_obj_to_sv(o);
				break;
			}

			case GIT_REF_SYMBOLIC: {
				Reference f;
				const char *target;

				target = git_reference_symbolic_target(self);

				rc = git_reference_lookup(&f, repo, target);
				git_check_error(rc);

				result = sv_setref_pv(
					newSV(0), "Git::Raw::Reference",
					(void *) f
				);
				break;
			}

			default: Perl_croak(aTHX_ "Invalid reference type");
		}

		RETVAL = result;

	OUTPUT: RETVAL

bool
is_branch(self)
	Reference self

	CODE:
		RETVAL = git_reference_is_branch(self);

	OUTPUT: RETVAL

bool
is_packed(self)
	Reference self

	CODE:
		RETVAL = git_reference_is_packed(self);

	OUTPUT: RETVAL

bool
is_remote(self)
	Reference self

	CODE:
		RETVAL = git_reference_is_remote(self);

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		Reference ref;

		if (sv_isobject(self) && sv_derived_from(self, "Git::Raw::Reference"))
			ref = INT2PTR(Reference, SvIV((SV *) SvRV(self)));
		else
			Perl_croak(aTHX_ "self is not of type Git::Raw::Reference");

		if (SvROK(self))
			git_reference_free(ref);
