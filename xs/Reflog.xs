MODULE = Git::Raw			PACKAGE = Git::Raw::Reflog

SV *
open(class, reference)
	SV *class
	SV *reference

	PREINIT:
		int rc;

		Reference ref;
		Reflog reflog;

	CODE:
		ref = GIT_SV_TO_PTR(Reference, reference);

		rc = git_reflog_read(
			&reflog,
			git_reference_owner(ref),
			git_reference_name(ref)
		);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, SvPVbyte_nolen(class), reflog, reference
		);

	OUTPUT: RETVAL

void
delete(self)
	SV *self

	PREINIT:
		int rc;

		Reference ref;
	
	CODE:
		ref = GIT_SV_TO_PTR(Reference, GIT_SV_TO_MAGIC(self));

		rc = git_reflog_delete(
			git_reference_owner(ref), git_reference_name(ref)
		);
		git_check_error(rc);

void
append(self, message, ...)
	SV *self
	const char *message

	PROTOTYPE: $$;$

	PREINIT:
		int rc;

		git_oid id;
		Signature sig;
		Reference ref;
		Repository ref_owner;

	CODE:
		if (items > 3)
			Perl_croak(aTHX_ "Wrong number of arguments");

		ref = GIT_SV_TO_PTR(Reference, GIT_SV_TO_MAGIC(self));
		ref_owner = git_reference_owner(ref);

		rc = git_reference_name_to_id(
			&id, ref_owner, git_reference_name(ref)
		);
		git_check_error(rc);

		if (items == 3) {
			sig = GIT_SV_TO_PTR(Signature, ST(2));
		} else {
			rc = git_signature_default(&sig, ref_owner);
			git_check_error(rc);
		}

		rc = git_reflog_append(
			GIT_SV_TO_PTR(Reflog, self),
			&id, sig, message
		);

		if (items != 3)
			git_signature_free(sig);

		git_check_error(rc);

void
drop(self, index)
	Reflog self
	size_t index

	PREINIT:
		int rc;

	CODE:
		rc = git_reflog_drop(self, index, 1);
		git_check_error(rc);

void
write(self)
	Reflog self

	PREINIT:
		int rc;

	CODE:
		rc = git_reflog_write(self);
		git_check_error(rc);

void
entries(self)
	SV *self

	PREINIT:
		int rc;
		size_t i, entry_count;

		Reflog reflog;
		Signature sig;

	PPCODE:
		reflog = GIT_SV_TO_PTR(Reflog, self);

		entry_count = git_reflog_entrycount (reflog);
		for (i = 0; i < entry_count; ++i) {
			SV *committer;

			const git_reflog_entry *e =
				git_reflog_entry_byindex(reflog, i);

			HV *entry = newHV();

			rc = git_signature_dup(&sig, git_reflog_entry_committer(e));
			git_check_error(rc);

			GIT_NEW_OBJ(committer, "Git::Raw::Signature", sig);

			hv_stores(entry, "committer", committer);
			hv_stores(entry, "message", newSVpv(git_reflog_entry_message(e), 0));
			hv_stores(entry, "new_id", git_oid_to_sv(git_reflog_entry_id_new(e)));
			hv_stores(entry, "old_id", git_oid_to_sv(git_reflog_entry_id_old(e)));

			EXTEND(SP, 1);
			PUSHs(sv_2mortal(newRV_noinc((SV *) entry)));
		}

		XSRETURN(entry_count);

void
DESTROY(self)
	SV *self

	CODE:
		git_reflog_free(GIT_SV_TO_PTR(Reflog, self));
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
