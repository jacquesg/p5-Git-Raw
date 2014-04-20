MODULE = Git::Raw			PACKAGE = Git::Raw::Cred

Cred
userpass(class, user, pass)
	SV *class
	SV *user
	SV *pass

	PREINIT:
		int rc;

		Cred out;
		const char *usr, *pwd;

	CODE:
		usr = SvPVbyte_nolen(user);
		pwd = SvPVbyte_nolen(pass);

		rc = git_cred_userpass_plaintext_new(&out, usr, pwd);
		git_check_error(rc);

		RETVAL = out;

	OUTPUT: RETVAL

Cred
sshkey(class, user, public, private, pass)
	SV *class
	SV *user
	SV *public
	SV *private
	SV *pass

	PREINIT:
		int rc;

		Cred out;
		const char *username, *publickey, *privatekey, *passphrase;

	CODE:
		username   = SvPVbyte_nolen(user);
		publickey  = SvPVbyte_nolen(public);
		privatekey = SvPVbyte_nolen(private);
		passphrase = SvPVbyte_nolen(pass);

		rc = git_cred_ssh_key_new(
			&out, username, publickey, privatekey, passphrase
		);
		git_check_error(rc);

		RETVAL = out;

	OUTPUT: RETVAL

Cred
sshagent(class, user)
	SV *class
	SV *user

	PREINIT:
		int rc;

		Cred out;
		const char *username;

	CODE:
		username = SvPVbyte_nolen(user);

		rc = git_cred_ssh_key_from_agent(&out, username);
		git_check_error(rc);

		RETVAL = out;

	OUTPUT: RETVAL

Cred
sshinteractive(class, user, callback)
	SV *class
	SV *user
	SV *callback

	PREINIT:
		int rc;

		Cred out;
		const char *username;

	CODE:
		username = SvPVbyte_nolen(user);

		if (SvTYPE(SvRV(callback)) != SVt_PVCV)
			Perl_croak(aTHX_ "Expected a subroutine for callback");

		SvREFCNT_inc(callback);
		rc = git_cred_ssh_interactive_new(
			&out,
			username,
			(git_cred_ssh_interactive_callback) git_ssh_interactive_cbb,
			callback);
		git_check_error(rc);

		RETVAL = out;

	OUTPUT: RETVAL
