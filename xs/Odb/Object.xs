MODULE = Git::Raw			PACKAGE = Git::Raw::Odb::Object

SV *
id(self)
	Odb_Object self

	CODE:
		RETVAL = git_oid_to_sv(git_odb_object_id(self));

	OUTPUT: RETVAL

SV *
size(self)
	Odb_Object self

	CODE:
		RETVAL = newSViv(git_odb_object_size(self));

	OUTPUT: RETVAL

SV *
type(self)
	Odb_Object self

	CODE:
		RETVAL = newSViv(git_odb_object_type(self));

	OUTPUT: RETVAL

SV *
data(self)
	Odb_Object self

	CODE:
		RETVAL = newSVpv(git_odb_object_data(self), git_odb_object_size(self));

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	CODE:
		git_odb_object_free(GIT_SV_TO_PTR(Odb::Object, self));

