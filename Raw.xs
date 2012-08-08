#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <inttypes.h>

#include <git2.h>

typedef git_blob * Blob;
typedef git_commit * Commit;
typedef git_config * Config;
typedef git_index * Index;
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

MODULE = Git::Raw			PACKAGE = Git::Raw

INCLUDE: xs/Blob.xs
INCLUDE: xs/Commit.xs
INCLUDE: xs/Config.xs
INCLUDE: xs/Index.xs
INCLUDE: xs/Repository.xs
INCLUDE: xs/Signature.xs
INCLUDE: xs/Tag.xs
INCLUDE: xs/Tree.xs
INCLUDE: xs/TreeEntry.xs
INCLUDE: xs/Walker.xs
