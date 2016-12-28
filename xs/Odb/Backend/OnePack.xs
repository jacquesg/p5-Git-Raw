MODULE = Git::Raw			PACKAGE = Git::Raw::Odb::Backend::OnePack

Odb_Backend
new(class, indexfile)
	SV *class
	SV *indexfile

	PREINIT:
		int rc;
		Odb_Backend backend;

	CODE:
		rc = git_odb_backend_one_pack(&backend,
			git_ensure_pv(indexfile, "indexfile"));
		git_check_error(rc);

		RETVAL = backend;

	OUTPUT: RETVAL
