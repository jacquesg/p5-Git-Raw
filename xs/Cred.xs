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

Cred
keyfile(class, public, private, pass)
	SV *class
	SV *public
	SV *private
	SV *pass

	CODE:
#ifdef GIT_SSH
		Cred out;

		const char *publickey  = SvPVbyte_nolen(public);
		const char *privatekey = SvPVbyte_nolen(private);
		const char *passphrase = SvPVbyte_nolen(private);

		int rc = git_cred_ssh_keyfile_passphrase_new(
			&out, publickey, privatekey, passphrase
		);
		git_check_error(rc);

		RETVAL = out;
#else
		RETVAL = &PL_sv_undef;
#endif

	OUTPUT: RETVAL
