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
		git_repository *ref_owner;

	CODE:
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

SV *
entry_count(self)
	Reflog self

	PREINIT:
		size_t count;

	CODE:
		count = git_reflog_entrycount (self);
		RETVAL = newSViv ((int) count);

	OUTPUT: RETVAL

void
entries(self, ...)
	SV *self

	PROTOTYPE: $;$$
	PREINIT:
		Reflog reflog;
		size_t start = 0, end, entry_count;

	PPCODE:
		reflog = GIT_SV_TO_PTR(Reflog, self);
		entry_count = git_reflog_entrycount (reflog);

		if (items >= 2) {
			SV *index = ST(1);

			if (!SvIOK(index) || SvIV(index) < 0)
				croak_usage("Invalid type for 'index'");

			start = SvUV(index);
			if (start >= entry_count)
				croak_usage("index %" PRIuZ " out of range", start);

			if (items >= 3) {
				SV *count = ST(2);
				size_t retrieve_count;

				if (!SvIOK(count) || SvIV(count) < 0)
					croak_usage("Invalid type for 'count'");
				if (SvIV(count) == 0)
					croak_usage("Invalid value for 'count'");

				retrieve_count = SvUV(count);
				if ((start + retrieve_count) > entry_count)
					croak_usage("count %" PRIuZ " out of range", retrieve_count);

				entry_count = retrieve_count;
			} else
				entry_count -= start;
		}

		end = start + entry_count;

		for (; start < end; ++start) {
			int rc;
			SV *committer;
			Signature sig;

			const git_reflog_entry *e =
				git_reflog_entry_byindex(reflog, start);

			HV *entry = newHV();

			rc = git_signature_dup(&sig, git_reflog_entry_committer(e));
			git_check_error(rc);

			GIT_NEW_OBJ(committer, "Git::Raw::Signature", sig);

			hv_stores(entry, "committer", committer);
			hv_stores(entry, "message", newSVpv(git_reflog_entry_message(e), 0));
			hv_stores(entry, "new_id", git_oid_to_sv(git_reflog_entry_id_new(e)));
			hv_stores(entry, "old_id", git_oid_to_sv(git_reflog_entry_id_old(e)));

			mXPUSHs(newRV_noinc((SV *) entry));
		}

		XSRETURN(entry_count);

void
DESTROY(self)
	SV *self

	CODE:
		git_reflog_free(GIT_SV_TO_PTR(Reflog, self));
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
