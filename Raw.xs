#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <inttypes.h>

#include <git2.h>

typedef git_commit * Commit;
typedef git_config * Config;
typedef git_index * Index;
typedef git_repository * Repository;
typedef git_signature * Signature;
typedef git_tree * Tree;

void git_check_error(int err) {
	const git_error *error;

	if (err == GIT_OK)
		return;

	error = giterr_last();

	Perl_croak(aTHX_ "%s", error -> message);
}

MODULE = Git::Raw			PACKAGE = Git::Raw

INCLUDE: xs/Commit.xs
INCLUDE: xs/Config.xs
INCLUDE: xs/Index.xs
INCLUDE: xs/Repository.xs
INCLUDE: xs/Signature.xs
INCLUDE: xs/Tree.xs
