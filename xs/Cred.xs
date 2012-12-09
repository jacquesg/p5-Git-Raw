MODULE = Git::Raw			PACKAGE = Git::Raw::Cred

Cred
plaintext(class, user, pass)
	SV *class
	SV *user
	SV *pass

	CODE:
		Cred out;
		const char *usr = SvPVbyte_nolen(user);
		const char *pwd = SvPVbyte_nolen(pass);

		int rc = git_cred_userpass_plaintext_new(&out, usr, pwd);
		git_check_error(rc);

		RETVAL = out;

	OUTPUT: RETVAL
