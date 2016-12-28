MODULE = Git::Raw			PACKAGE = Git::Raw::Odb::Backend::Pack

Odb_Backend
new(class, directory)
	SV *class
	SV *directory

	PREINIT:
		int rc;
		Odb_Backend backend;

	CODE:
		rc = git_odb_backend_pack(&backend,
			git_ensure_pv(directory, "directory"));
		git_check_error(rc);

		RETVAL = backend;

	OUTPUT: RETVAL
