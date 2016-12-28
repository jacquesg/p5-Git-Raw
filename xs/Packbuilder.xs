MODULE = Git::Raw			PACKAGE = Git::Raw::Packbuilder

INCLUDE: const-xs-packbuilder.inc

SV *
new(class, repo)
	SV *class
	SV *repo

	PREINIT:
		int rc;

		Repository repo_ptr;
		Packbuilder pb;

	CODE:
		repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		Newxz(pb, 1, git_raw_packbuilder);

		rc = git_packbuilder_new(&pb -> packbuilder, repo_ptr -> repository);
		git_check_error(rc);

		GIT_NEW_OBJ_WITH_MAGIC(
			RETVAL, "Git::Raw::Packbuilder", pb, SvRV(repo)
		);

	OUTPUT: RETVAL

void
insert(self, object, recursive=&PL_sv_yes)
	Packbuilder self
	SV *object
	SV *recursive

	PREINIT:
		int rc = GIT_OK;

	CODE:
		if (!sv_isobject(object))
			croak_usage("Invalid type for 'object', expected an object");

		if (sv_derived_from(object, "Git::Raw::Walker")) {
			Walker walker = GIT_SV_TO_PTR(Walker, object);
			rc = git_packbuilder_insert_walk(self -> packbuilder, walker);
		} else {
			git_object *o = git_sv_to_obj(object);
			if (o == NULL)
				croak_usage("Unsupported object type");

			if (SvTRUE(recursive))
				rc = git_packbuilder_insert_recur(self -> packbuilder, git_object_id(o), NULL);
			else
				rc = git_packbuilder_insert(self -> packbuilder, git_object_id(o), NULL);
		}

		git_check_error(rc);


void
write(self, path)
	Packbuilder self
	SV *path

	PREINIT:
		int rc;

		static const char *cbname = "transfer_progress";
		static const I32 cbnamelen = strlen("transfer_progress");

		const char *p;

	CODE:
		p = git_ensure_pv(path, "path");
		if (self -> callbacks && hv_exists(self -> callbacks, cbname, cbnamelen))
			rc = git_packbuilder_write(self -> packbuilder, p, 0,
				git_transfer_progress_cbb, self -> callbacks);
		else
			rc = git_packbuilder_write(self -> packbuilder, p, 0,
				NULL, NULL);
		git_check_error(rc);

SV *
object_count(self)
	Packbuilder self

	CODE:
		size_t count = git_packbuilder_object_count(self -> packbuilder);
		RETVAL = newSVuv(count);

	OUTPUT: RETVAL

SV *
written(self)
	Packbuilder self

	CODE:
		size_t written = git_packbuilder_written(self -> packbuilder);
		RETVAL = newSVuv(written);

	OUTPUT: RETVAL

void
threads(self, count)
	Packbuilder self
	SV *count

	PREINIT:
		I32 c;
	CODE:
		c = git_ensure_iv(count, "count");
		if (c < 0)
			croak_usage("thread count should be >= 0");

		git_packbuilder_set_threads(self -> packbuilder, (unsigned int)c);

SV *
hash(self)
	Packbuilder self

	CODE:
		RETVAL = git_oid_to_sv(git_packbuilder_hash(self -> packbuilder));

	OUTPUT: RETVAL

void
callbacks(self, callbacks)
	Packbuilder self
	HV *callbacks

	PREINIT:
		int rc;
		SV *cb;

	CODE:
		if (!self -> callbacks)
			self -> callbacks = newHV();

		if ((cb = get_callback_option(callbacks, "pack_progress"))) {
			hv_stores(self -> callbacks, "pack_progress", cb);
			rc = git_packbuilder_set_callbacks(self -> packbuilder,
				git_packbuilder_progress_cbb, self -> callbacks);
			git_check_error(rc);
		}

		if ((cb = get_callback_option(callbacks, "transfer_progress")))
			hv_stores(self -> callbacks, "transfer_progress", cb);

void
DESTROY(self)
	SV *self

	PREINIT:
		Packbuilder pb;

	CODE:
		pb = GIT_SV_TO_PTR(Packbuilder, self);
		if (pb -> callbacks)
			hv_undef(pb -> callbacks);
		git_packbuilder_free(pb -> packbuilder);
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
		Safefree(pb);

