MODULE = Git::Raw			PACKAGE = Git::Raw::Cred

Cred
userpass(class, user, pass)
	SV *class
	SV *user
	SV *pass

	PREINIT:
		int rc;

		Cred out;
		git_cred *cred;
		const char *usr, *pwd;

	CODE:
		usr = SvPVbyte_nolen(user);
		pwd = SvPVbyte_nolen(pass);

		rc = git_cred_userpass_plaintext_new(&cred, usr, pwd);
		git_check_error(rc);

		Newxz(out, 1, git_raw_cred);
		out -> cred = cred;
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
		git_cred *cred;
		const char *username, *publickey, *privatekey, *passphrase;

	CODE:
		username   = SvPVbyte_nolen(user);
		publickey  = SvPVbyte_nolen(public);
		privatekey = SvPVbyte_nolen(private);
		passphrase = SvPVbyte_nolen(pass);

		rc = git_cred_ssh_key_new(
			&cred, username, publickey, privatekey, passphrase
		);
		git_check_error(rc);

		Newxz(out, 1, git_raw_cred);
		out -> cred = cred;
		RETVAL = out;

	OUTPUT: RETVAL

Cred
sshagent(class, user)
	SV *class
	SV *user

	PREINIT:
		int rc;

		Cred out;
		git_cred *cred;
		const char *username;

	CODE:
		username = SvPVbyte_nolen(user);

		rc = git_cred_ssh_key_from_agent(&cred, username);
		git_check_error(rc);

		Newxz(out, 1, git_raw_cred);
		out -> cred = cred;
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
		git_cred *cred;
		const char *username;

	CODE:
		username = SvPVbyte_nolen(user);

		rc = git_cred_ssh_interactive_new(
			&cred,
			username,
			(git_cred_ssh_interactive_callback) git_ssh_interactive_cbb,
			git_ensure_cv(callback, "callback"));
		git_check_error(rc);

		Newxz(out, 1, git_raw_cred);
		out -> cred = cred;
		out -> callback = callback;
		SvREFCNT_inc(out -> callback);

		RETVAL = out;

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	PREINIT:
		Cred cred;

	CODE:
		cred = GIT_SV_TO_PTR(Cred, self);

		SvREFCNT_dec(cred -> callback);
		Safefree(cred);
