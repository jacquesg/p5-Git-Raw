MODULE = Git::Raw			PACKAGE = Git::Raw::Cred

Cred
userpass(class, user, pass)
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
sshkey(class, user, public, private, pass)
	SV *class
	SV *user
	SV *public
	SV *private
	SV *pass

	CODE:
		Cred out;

		const char *username   = SvPVbyte_nolen(user);
		const char *publickey  = SvPVbyte_nolen(public);
		const char *privatekey = SvPVbyte_nolen(private);
		const char *passphrase = SvPVbyte_nolen(pass);

		int rc = git_cred_ssh_key_new(
			&out, username, publickey, privatekey, passphrase
		);
		git_check_error(rc);

		RETVAL = out;

	OUTPUT: RETVAL

Cred
sshagent(class, user)
	SV *class
	SV *user

	CODE:
		Cred out;

		const char *username   = SvPVbyte_nolen(user);

		int rc = git_cred_ssh_key_from_agent(&out, username);
		git_check_error(rc);

		RETVAL = out;

	OUTPUT: RETVAL
