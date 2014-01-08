MODULE = Git::Raw			PACKAGE = Git::Raw::Cred

Cred
userpass(class, user, pass)
	SV *class
	SV *user
	SV *pass

	PREINIT:
		int rc;
		const char *usr, *pwd;
		Cred out;

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
		const char *username, *publickey, *privatekey, *passphrase;
		Cred out;

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
		const char *username;
		Cred out;

	CODE:
		username = SvPVbyte_nolen(user);

		rc = git_cred_ssh_key_from_agent(&out, username);
		git_check_error(rc);

		RETVAL = out;

	OUTPUT: RETVAL
