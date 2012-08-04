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
	switch (err) {
		case GIT_OK: return;
		case GIT_ERROR: Perl_croak(aTHX_ "error");
		case GIT_ENOTFOUND: Perl_croak(aTHX_ "not found");
		case GIT_EEXISTS: Perl_croak(aTHX_ "already exists");
		case GIT_EAMBIGUOUS: Perl_croak(aTHX_ "ambiguous");
		case GIT_EBUFS: Perl_croak(aTHX_ "bufs");
	}
}

MODULE = Git::Raw			PACKAGE = Git::Raw

INCLUDE: xs/Commit.xs
INCLUDE: xs/Config.xs
INCLUDE: xs/Index.xs
INCLUDE: xs/Repository.xs
INCLUDE: xs/Signature.xs
INCLUDE: xs/Tree.xs
