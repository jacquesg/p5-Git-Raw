#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <inttypes.h>

#include <git2.h>

typedef git_blob * Blob;
typedef git_reference * Branch;
typedef git_commit * Commit;
typedef git_config * Config;
typedef git_diff_list * Diff;
typedef git_index * Index;
typedef git_reference * Reference;
typedef git_remote * Remote;
typedef git_repository * Repository;
typedef git_signature * Signature;
typedef git_tag * Tag;
typedef git_tree * Tree;
typedef git_tree_entry * TreeEntry;
typedef git_revwalk * Walker;

void git_check_error(int err) {
	const git_error *error;

	if (err == GIT_OK)
		return;

	error = giterr_last();

	Perl_croak(aTHX_ "%s", error -> message);
}

SV *git_obj_to_sv(git_object *o) {
	switch (git_object_type(o)) {
		case GIT_OBJ_BLOB:
			return sv_setref_pv(newSV(0), "Git::Raw::Blob", o);
		case GIT_OBJ_COMMIT:
			return sv_setref_pv(newSV(0), "Git::Raw::Commit", o);
		case GIT_OBJ_TAG:
			return sv_setref_pv(newSV(0), "Git::Raw::Tag", o);
		case GIT_OBJ_TREE:
			return sv_setref_pv(newSV(0), "Git::Raw::Tree", o);
		default: Perl_croak(aTHX_ "Invalid object type");
	}
}

git_object *git_sv_to_obj(SV *sv) {
	if (sv_isobject(sv) &&
		(sv_derived_from(sv, "Git::Raw::Blob") ||
		sv_derived_from(sv, "Git::Raw::Commit") ||
		sv_derived_from(sv, "Git::Raw::Tag") ||
		sv_derived_from(sv, "Git::Raw::Tree"))
	)
		return INT2PTR(git_object *, SvIV((SV *) SvRV(sv)));

	return NULL;
}

SV *git_oid_to_sv(git_oid *oid) {
	char out[41];

	git_oid_fmt(out, oid);
	out[40] = '\0';

	return newSVpv(out, 0);
}

int git_diff_wrapper(void *data, git_diff_delta *delta, git_diff_range *range,
				char usage, const char *line, size_t line_len) {
	dSP;

	SV *coderef = data;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	switch (usage) {
		case GIT_DIFF_LINE_CONTEXT:
			XPUSHs(sv_2mortal(newSVpv("ctx", 0))); break;

		case GIT_DIFF_LINE_ADDITION:
		case GIT_DIFF_LINE_ADD_EOFNL:
			XPUSHs(sv_2mortal(newSVpv("add", 0))); break;

		case GIT_DIFF_LINE_DELETION:
		case GIT_DIFF_LINE_DEL_EOFNL:
			XPUSHs(sv_2mortal(newSVpv("del", 0))); break;

		case GIT_DIFF_LINE_FILE_HDR:
			XPUSHs(sv_2mortal(newSVpv("file", 0))); break;

		case GIT_DIFF_LINE_HUNK_HDR:
			XPUSHs(sv_2mortal(newSVpv("hunk", 0))); break;

		case GIT_DIFF_LINE_BINARY:
			XPUSHs(sv_2mortal(newSVpv("bin", 0))); break;

		default: Perl_croak(aTHX_ "Unexpected diff usage");
	}

	XPUSHs(sv_2mortal(newSVpv(line, line_len)));
	PUTBACK;

	call_sv(coderef, G_DISCARD);

	FREETMPS;
	LEAVE;

	return 0;
}

typedef struct {
	Repository repo;
	SV* cb;
} git_foreach_payload;

int git_branch_foreach_cb(const char *name, git_branch_t type, void *payload) {
	dSP;
	int rv;
	Branch branch;
	SV *cb_arg;

	int rc = git_branch_lookup(
		&branch, ((git_foreach_payload *) payload) -> repo,
		name, type
	);
	git_check_error(rc);

	ENTER;
	SAVETMPS;

	cb_arg = sv_newmortal();
	sv_setref_pv(cb_arg, "Git::Raw::Branch", (void *) branch);

	PUSHMARK(SP);
	PUSHs(cb_arg);
	PUTBACK;

	call_sv(((git_foreach_payload *) payload) -> cb, G_SCALAR);

	SPAGAIN;

	rv = POPi;

	FREETMPS;
	LEAVE;

	return rv;
}

int git_stash_foreach_cb(size_t i, const char *msg, const git_oid *oid, void *payload) {
	dSP;
	int rv;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUSHs(newSVuv(i));
	PUSHs(newSVpv(msg, 0));
	PUSHs(git_oid_to_sv(oid));
	PUTBACK;

	call_sv(((git_foreach_payload *) payload) -> cb, G_SCALAR);

	SPAGAIN;

	rv = POPi;

	FREETMPS;
	LEAVE;

	return rv;
}

MODULE = Git::Raw			PACKAGE = Git::Raw

INCLUDE: xs/Blob.xs
INCLUDE: xs/Branch.xs
INCLUDE: xs/Commit.xs
INCLUDE: xs/Config.xs
INCLUDE: xs/Diff.xs
INCLUDE: xs/Index.xs
INCLUDE: xs/Reference.xs
INCLUDE: xs/Remote.xs
INCLUDE: xs/Repository.xs
INCLUDE: xs/Signature.xs
INCLUDE: xs/Stash.xs
INCLUDE: xs/Tag.xs
INCLUDE: xs/Tree.xs
INCLUDE: xs/TreeEntry.xs
INCLUDE: xs/Walker.xs
