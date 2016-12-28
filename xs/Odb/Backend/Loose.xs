MODULE = Git::Raw			PACKAGE = Git::Raw::Odb::Backend::Loose

Odb_Backend
new(class, directory, ...)
	SV *class
	SV *directory

	PREINIT:
		int rc, compression_level = -1;
		Odb_Backend backend;

	CODE:
		if (items >= 3)
			compression_level = git_ensure_iv(ST(2), "compression_level");

		rc = git_odb_backend_loose(&backend,
			git_ensure_pv(directory, "directory"),
			compression_level, 0, 0, 0);
		git_check_error(rc);

		RETVAL = backend;

	OUTPUT: RETVAL

