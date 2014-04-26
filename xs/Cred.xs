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

	CODE:
		rc = git_cred_userpass_plaintext_new(
			&cred,
			git_ensure_pv(user, "user"),
			git_ensure_pv(pass, "pass")
		);
		git_check_error(rc);

		Newxz(out, 1, git_raw_cred);
		out -> cred = cred;
		RETVAL = out;

	OUTPUT: RETVAL

Cred
sshkey(class, user, public, private, ...)
	SV *class
	SV *user
	SV *public
	SV *private

	PROTOTYPE: $$$$;$
	PREINIT:
		int rc;

		Cred out;
		git_cred *cred;
		const char *passphrase = NULL;

	CODE:
		if (items == 5)
			passphrase = git_ensure_pv(ST(4), "pass");

		rc = git_cred_ssh_key_new(
			&cred,
			git_ensure_pv(user, "user"),
			git_ensure_pv(public, "public"),
			git_ensure_pv(private, "private"),
			passphrase
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

	CODE:
		rc = git_cred_ssh_key_from_agent(
			&cred,
			git_ensure_pv(user, "user")
		);
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

	CODE:
		rc = git_cred_ssh_interactive_new(
			&cred,
			git_ensure_pv(user, "user"),
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
