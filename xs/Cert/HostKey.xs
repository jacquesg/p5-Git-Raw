MODULE = Git::Raw			PACKAGE = Git::Raw::Cert::HostKey

BOOT:
{
	AV *isa = get_av("Git::Raw::Cert::HostKey::ISA", 1);
	av_push(isa, newSVpv("Git::Raw::Cert", 0));
}

void
ssh_types(self)
	Cert_HostKey self

	PREINIT:
		int ctx;

		git_cert_ssh_t type;

	PPCODE:
		ctx = GIMME_V;

		if (ctx != G_VOID) {
			int count = 0;

			type = self -> type;

			if (type & GIT_CERT_SSH_MD5) {
				if (ctx == G_ARRAY)
					mXPUSHs(newSVpv("md5", 0));
				count++;
			}

			if (type & GIT_CERT_SSH_SHA1) {
				if (ctx == G_ARRAY)
					mXPUSHs(newSVpv("sha1", 0));
				count++;
			}

			if (ctx == G_ARRAY)
				XSRETURN(count);
			else {
				mXPUSHs(newSViv(count));
				XSRETURN(1);
			}
		} else
			XSRETURN_EMPTY;

SV *
sha1(self)
	Cert_HostKey self

	PREINIT:
		git_cert_ssh_t type;

	CODE:
		type = self -> type;

		RETVAL = &PL_sv_undef;
		if (type & GIT_CERT_SSH_SHA1)
			RETVAL = newSVpv((const char *) &self -> hash_sha1[0], 20);

	OUTPUT: RETVAL

SV *
md5(self)
	Cert_HostKey self

	PREINIT:
		git_cert_ssh_t type;

	CODE:
		type = self -> type;

		RETVAL = &PL_sv_undef;
		if (type & GIT_CERT_SSH_MD5)
			RETVAL = newSVpv((const char *) &self -> hash_md5[0], 16);

	OUTPUT: RETVAL
