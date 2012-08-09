MODULE = Git::Raw			PACKAGE = Git::Raw::Reference

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

		case (git_reference_type(self)) {
			case GIT_REF_OID: type = newSVpv(":direct", 0); break;
			case GIT_REF_SYMBOLIC: type = newSVpv(":symbolic", 0); break;

		RETVAL = type;

	OUTPUT: RETVAL

SV *
target(self)
	Tag self

	CODE:
		int rc;
		SV *result;

		switch (git_reference_type(self)) {
			case GIT_REF_OID: {
				const git_oid *oid = git_reference_oid(self);

				result = git_oid_to_sv(oid);
				break;
			}

			case GIT_REF_SYMBOLIC: {
				const char *target = git_reference_target(self);

				result = newSVpv(target, 0);
				break;
			}

			default: Perl_croak(aTHX_ "Invalid reference type");
		}

		RETVAL = result;

	OUTPUT: RETVAL

void
DESTROY(self)
	Reference self

	CODE:
		git_reference_free(self);
