MODULE = Git::Raw			PACKAGE = Git::Raw::Cert

SV *
type(self)
	Cert self

	CODE:
		RETVAL = &PL_sv_undef;

		switch (self -> cert_type) {
			case GIT_CERT_X509:
				RETVAL = newSVpv("x509", 0);
				break;

			case GIT_CERT_HOSTKEY_LIBSSH2:
				RETVAL = newSVpv("hostkey", 0);
				break;
		}

	OUTPUT: RETVAL
