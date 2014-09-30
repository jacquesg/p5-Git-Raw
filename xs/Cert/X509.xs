MODULE = Git::Raw			PACKAGE = Git::Raw::Cert::X509

BOOT:
{
	AV *isa = get_av("Git::Raw::Cert::X509::ISA", 1);
	av_push(isa, newSVpv("Git::Raw::Cert", 0));
}

SV *
data(self)
	Cert_X509 self

	CODE:
		RETVAL = newSVpv((const char *) self -> data, self -> len);

	OUTPUT: RETVAL
