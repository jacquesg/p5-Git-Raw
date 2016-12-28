MODULE = Git::Raw			PACKAGE = Git::Raw::Mempack

BOOT:
{
	AV *isa = get_av("Git::Raw::Mempack::ISA", 1);
	av_push(isa, newSVpv("Git::Raw::Odb::Backend", 0));
}

Mempack
new(class)
	SV *class

	PREINIT:
		int rc;
		Odb_Backend backend;

	CODE:
		rc = git_mempack_new(&backend);
		git_check_error(rc);

		RETVAL = backend;

	OUTPUT: RETVAL

SV *
dump(self, repo)
	Odb_Backend self
	Repository repo

	PREINIT:
		int rc;
		git_buf buf = GIT_BUF_INIT_CONST(NULL, 0);

	CODE:
		rc = git_mempack_dump(&buf, repo -> repository,
			self);
		git_check_error(rc);

		RETVAL = newSVpv(buf.ptr, buf.size);

		git_buf_free(&buf);

	OUTPUT: RETVAL

void
reset(self)
	Odb_Backend self

	CODE:
		git_mempack_reset(self);

