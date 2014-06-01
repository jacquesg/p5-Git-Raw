#include <raw/raw.h>

/* reference counting */
gr_obj_data *gr_obj_data_alloc(int initial_ref_count) {
	gr_obj_data *data = NULL;

	Newxz(data, 1, gr_obj_data);
	if (initial_ref_count > 0) {
		Newxz(data -> refcount, 1, int);
		*data -> refcount = initial_ref_count;
	}

	return data;
}

gr_obj_data *gr_obj_data_dup(const gr_obj_data *src) {
	gr_obj_data *data = gr_obj_data_alloc(0);
	StructCopy(src, data, gr_obj_data);
	return data;
}

void gr_obj_data_free(gr_obj_data *data) {
	if (*data -> refcount == 0) {
		Safefree(data -> refcount);
	}

	Safefree(data);
}

void gr_obj_data_set_options(gr_obj_data* data, gr_obj_data_opts *opts) {
	data -> opts = opts;
}

void gr_obj_data_inc_refcount(gr_obj_data *data) {
	++(*data -> refcount);
}

int gr_obj_data_dec_refcount(gr_obj_data *data) {
	if (--(*data -> refcount) == 0)
		return 1;

	return 0;
}

/* magic */
STATIC int gr_obj_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
	gr_obj_data_inc_refcount((gr_obj_data *) mg -> mg_ptr);
	return 0;
}

STATIC MGVTBL null_mg_vtbl = {
	NULL, /* get */
	NULL, /* set */
	NULL, /* len */
	NULL, /* clear */
	NULL, /* free */
#if MGf_COPY
	NULL, /* copy */
#endif /* MGf_COPY */
#if MGf_DUP
	gr_obj_magic_dup, /* dup */
#endif /* MGf_DUP */
#if MGf_LOCAL
	NULL, /* local */
#endif /* MGf_LOCAL */
};


void gr_obj_magic_set(SV *sv, gr_obj_data *ptr) {
	MAGIC *mg = NULL;
	mg = sv_magicext(SvROK(sv) ? SvRV(sv) : sv, NULL, PERL_MAGIC_ext, &null_mg_vtbl, (void *) ptr, 0);
	mg -> mg_flags |= MGf_DUP;
}

void gr_obj_magic_add(SV *sv, SV *owner) {
	gr_obj_data *data = gr_obj_data_alloc(1);
	data -> owner = owner;

	gr_obj_magic_set(sv, data);
}

void gr_obj_magic_remove(SV *sv) {
	sv_unmagicext(sv, PERL_MAGIC_ext, &null_mg_vtbl);
}

gr_obj_data *gr_obj_magic_get(SV *sv) {
	MAGIC *mg = NULL;

	if (SvROK(sv))
		sv = SvRV(sv);

	if (SvTYPE(sv) >= SVt_PVMG) {
		MAGIC *tmp;

		for (tmp = SvMAGIC(sv); tmp;
			tmp = tmp -> mg_moremagic) {
			if ((tmp -> mg_type == PERL_MAGIC_ext) &&
				(tmp -> mg_virtual == &null_mg_vtbl))
				mg = tmp;
		}
	}

	return (mg) ? (gr_obj_data *) mg -> mg_ptr : NULL;
}

/* object management */
git_object *git_sv_to_obj(SV *sv) {
	if (sv_isobject(sv) && (
		sv_derived_from(sv, "Git::Raw::Blob") ||
		sv_derived_from(sv, "Git::Raw::Commit") ||
		sv_derived_from(sv, "Git::Raw::Tag") ||
		sv_derived_from(sv, "Git::Raw::Tree")
	))
		return INT2PTR(git_object *, SvIV((SV *) SvRV(sv)));

	return NULL;
}

void *git_sv_to_ptr(const char *type, SV *sv) {
	SV *full_type = sv_2mortal(newSVpvf("Git::Raw::%s", type));

	if (sv_isobject(sv) && sv_derived_from(sv, SvPV_nolen(full_type)))
		return INT2PTR(void *, SvIV((SV *) SvRV(sv)));

	Perl_croak(aTHX_ "Argument is not of type %s", SvPV_nolen(full_type));

	return NULL;
}

SV *git_obj_to_sv(git_object *o, SV *repo) {
	SV *res;

	switch (git_object_type(o)) {
		case GIT_OBJ_BLOB:
			GIT_NEW_OBJ_WITH_MAGIC(
				res, "Git::Raw::Blob", o, repo
			);
			break;

		case GIT_OBJ_COMMIT:
			GIT_NEW_OBJ_WITH_MAGIC(
				res, "Git::Raw::Commit", o, repo
			);
			break;

		case GIT_OBJ_TAG:
			GIT_NEW_OBJ_WITH_MAGIC(
				res, "Git::Raw::Tag", o, repo
			);
			break;

		case GIT_OBJ_TREE:
			GIT_NEW_OBJ_WITH_MAGIC(
				res, "Git::Raw::Tree", o, repo
			);
			break;

		default:
			Perl_croak(aTHX_ "Invalid object type");
			break;
	}

	return res;
}

SV *git_oid_to_sv(const git_oid *oid) {
	char out[41];

	git_oid_fmt(out, oid);
	out[40] = '\0';

	return newSVpv(out, 0);
}

void git_check_error(int err) {
	const git_error *error;

	if (err == GIT_OK || err == GIT_ITEROVER)
		return;

	error = giterr_last();

	if (error)
		Perl_croak(aTHX_ "%d: %s", error -> klass, error -> message);

	if (SvTRUE(ERRSV))
		Perl_croak (aTHX_ "%s", SvPVbyte_nolen(ERRSV));

	Perl_croak(aTHX_ "%s", "Unknown error!");
}

/* vim: set syntax=xs ts=4 sw=4: */
