MODULE = Git::Raw			PACKAGE = Git::Raw::Test

void
assert(class)
	SV *class

	PREINIT:
		const int value = 12345;

	CODE:
		croak_assert ("croaking: %d", value);
