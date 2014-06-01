#include <raw/tag.h>

int git_tag_foreach_cbb(const char *name, git_oid *oid, void *payload) {
	dSP;
	int rc;
	int rv = 0;
	git_object *tag;
	SV *repo;

	git_tag_foreach_payload *pl = payload;
	repo = pl -> repo;

	rc = git_object_lookup(&tag, GIT_SV_TO_PTR(Repository, repo), oid, GIT_OBJ_ANY);
	git_check_error(rc);

	if (git_object_type(tag) != GIT_OBJ_TAG) {
		git_object_free(tag);

		return 0;
	}

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(gr_bless_into_obj(pl -> class, (void *) tag, SvRV(repo)));
	PUTBACK;

	call_sv(pl -> cb, G_SCALAR);

	SPAGAIN;

	rv = POPi;

	FREETMPS;
	LEAVE;

	return rv;
}

/* vim: set syntax=xs ts=4 sw=4: */
