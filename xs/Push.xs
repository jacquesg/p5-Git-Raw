MODULE = Git::Raw			PACKAGE = Git::Raw::Push

SV *
new(class, remote)
	SV *class
	SV *remote

	PREINIT:
		int rc;

		git_push *p = NULL;
		Push push = NULL;

		Remote r = NULL;

	CODE:
		r = GIT_SV_TO_PTR(Remote, remote);

		rc = git_push_new(&p, r -> remote);
		git_check_error(rc);

		Newxz(push, 1, git_raw_push);
		git_init_push_callbacks(&push -> callbacks);
		push -> push = p;

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, SvPVbyte_nolen(class), push, SvRV(remote)
		);

	OUTPUT: RETVAL

void
add_refspec(self, refspec)
	Push self
	SV *refspec

	PREINIT:
		int rc;

	CODE:
		rc = git_push_add_refspec(self -> push, SvPVbyte_nolen(refspec));
		git_check_error(rc);

SV *
finish(self)
	Push self

	PREINIT:
		int rc;

	CODE:
		self -> success = 1;

		rc = git_push_finish(self -> push);
		git_check_error(rc);

		if (self -> callbacks.status != NULL) {
			rc = git_push_status_foreach(
				self -> push,
				git_push_status_cbb,
				self);

			if (rc != GIT_EUSER)
				git_check_error(rc);
		}

		RETVAL = newSViv(self -> success);

	OUTPUT: RETVAL

SV *
unpack_ok(self)
	Push self

	CODE:
		RETVAL = newSViv(git_push_unpack_ok(self -> push));

	OUTPUT: RETVAL

void
update_tips(self)
	SV *self

	PREINIT:
		int rc;

		SV *remote;

		Push push;
		Remote remote_ptr;
		Signature sig;

	CODE:
		push = GIT_SV_TO_PTR(Push, self);

		if (!push -> success)
			croak_usage("Push did not complete successfully");

		remote = GIT_SV_TO_MAGIC(self);
		remote_ptr = INT2PTR(Remote, SvIV((SV *) remote));

		rc = git_signature_default(&sig, git_remote_owner(remote_ptr -> remote));
		git_check_error(rc);

		rc = git_push_update_tips(push -> push, sig, NULL);
		git_signature_free(sig);
		git_check_error(rc);

void
callbacks(self, callbacks)
	SV *self
	HV *callbacks

	PREINIT:
		int rc;

		Push push;

		git_packbuilder_progress pack_progress = NULL;
		git_push_transfer_progress transfer_progress = NULL;

	CODE:
		push = GIT_SV_TO_PTR(Push, self);

		git_clean_push_callbacks(&push -> callbacks);

		if ((push -> callbacks.transfer_progress =
			get_callback_option(callbacks, "transfer_progress"))) {

			transfer_progress = git_push_transfer_progress_cbb;
		}

		if ((push -> callbacks.packbuilder_progress =
			get_callback_option(callbacks, "pack_progress"))) {

			pack_progress = git_packbuilder_progress_cbb;
		}

		push -> callbacks.status = get_callback_option(callbacks, "status");

		rc = git_push_set_callbacks(
			push -> push,
			pack_progress,
			&push -> callbacks,
			transfer_progress,
			&push -> callbacks);
		git_check_error(rc);

void
DESTROY(self)
	SV *self

	PREINIT:
		Push push;

	CODE:
		push = GIT_SV_TO_PTR(Push, self);
		git_push_free(push -> push);
		git_clean_push_callbacks(&push -> callbacks);
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
		Safefree(push);
