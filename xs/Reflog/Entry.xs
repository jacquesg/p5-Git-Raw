MODULE = Git::Raw			PACKAGE = Git::Raw::Reflog::Entry

SV *
new_id(self)
	Reflog_Entry self

	CODE:
		RETVAL = git_oid_to_sv(git_reflog_entry_id_new(self));

	OUTPUT: RETVAL

SV *
old_id(self)
	Reflog_Entry self

	CODE:
		RETVAL = git_oid_to_sv(git_reflog_entry_id_old(self));

	OUTPUT: RETVAL

Signature
committer(self)
	Reflog_Entry self

	PREINIT:
		int rc;

		Signature sig;

	CODE:
		rc = git_signature_dup(&sig, git_reflog_entry_committer(self));
		git_check_error(rc);

		RETVAL = sig;

	OUTPUT: RETVAL

SV *
message(self)
	Reflog_Entry self

	PREINIT:
		const char *message;

	CODE:
		if ((message = git_reflog_entry_message(self)) != NULL)
			RETVAL = newSVpv(message, 0);
		else
			RETVAL = &PL_sv_undef;

	OUTPUT: RETVAL

void
DESTROY(self)
	SV* self

	CODE:
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
