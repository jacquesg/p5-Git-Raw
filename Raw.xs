#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <inttypes.h>

#include <git2.h>

typedef git_blob * Blob;
typedef git_reference * Branch;
typedef git_commit * Commit;
typedef git_config * Config;
typedef git_cred * Cred;
typedef git_diff_list * Diff;
typedef git_index * Index;
typedef git_push * Push;
typedef git_reference * Reference;
typedef git_refspec * RefSpec;
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

#define GIT_SV_TO_PTR(type, sv) ({					\
	void *ptr;							\
									\
	if (sv_isobject(sv) && sv_derived_from(sv, "Git::Raw::" #type))	\
		ptr = INT2PTR(void *, SvIV((SV *) SvRV(sv)));		\
	else								\
		Perl_croak(aTHX_ "Argument is not of type Git::Raw::" #type); \
									\
	ptr;								\
})

SV *git_oid_to_sv(git_oid *oid) {
	char out[41];

	git_oid_fmt(out, oid);
	out[40] = '\0';

	return newSVpv(out, 0);
}

#define GIT_CHECKOUT_OPT(HV, NAME, MASK) ({				\
	SV **opt;							\
									\
	if ((opt = hv_fetchs(HV, NAME, 0)) && (SvIV(*opt) != 0)) {	\
		out |= MASK;						\
	}								\
})

unsigned git_hv_to_checkout_strategy(HV *strategy) {
	unsigned out = 0;

	GIT_CHECKOUT_OPT(
		strategy, "update_unmodifed", GIT_CHECKOUT_UPDATE_UNMODIFIED
	);

	GIT_CHECKOUT_OPT(
		strategy, "update_missing",   GIT_CHECKOUT_UPDATE_MISSING
	);

	GIT_CHECKOUT_OPT(
		strategy, "update_modified",  GIT_CHECKOUT_UPDATE_MODIFIED
	);

	GIT_CHECKOUT_OPT(
		strategy, "update_untracked", GIT_CHECKOUT_UPDATE_UNTRACKED
	);

	GIT_CHECKOUT_OPT(
		strategy, "allow_conflicts",  GIT_CHECKOUT_ALLOW_CONFLICTS
	);

	GIT_CHECKOUT_OPT(
		strategy, "skip_unmerged",    GIT_CHECKOUT_SKIP_UNMERGED
	);

	GIT_CHECKOUT_OPT(
		strategy, "update_only",      GIT_CHECKOUT_UPDATE_ONLY
	);

	return out;
}

int git_diff_cb(const git_diff_delta *delta, const git_diff_range *range,
		char usage, const char *line, size_t line_len, void *data) {
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
	SV *cb_arg;
	Branch branch;

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

int git_config_foreach_cbb(const git_config_entry *entry, void *payload) {
	dSP;
	int rv;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUSHs(newSVpv(entry -> name, 0));
	PUSHs(newSVpv(entry -> value, 0));
	PUSHs(newSVuv(entry -> level));
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
	PUSHs(git_oid_to_sv((git_oid *) oid));
	PUTBACK;

	call_sv(((git_foreach_payload *) payload) -> cb, G_SCALAR);

	SPAGAIN;

	rv = POPi;

	FREETMPS;
	LEAVE;

	return rv;
}

int git_tag_foreach_cbb(const char *name, git_oid *oid, void *payload) {
	dSP;
	int rv;
	Tag tag;
	SV *cb_arg;

	int rc = git_tag_lookup(
		&tag, ((git_foreach_payload *) payload) -> repo, oid
	);
	git_check_error(rc);

	ENTER;
	SAVETMPS;

	cb_arg = sv_newmortal();
	sv_setref_pv(cb_arg, "Git::Raw::Tag", (void *) tag);

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

int git_cred_acquire_cbb(git_cred **cred, const char *url,
						unsigned int allow, void *cb) {
	dSP;
	SV *creds;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUSHs(newSVpv(url, 0));
	PUTBACK;

	call_sv(cb, G_SCALAR);

	SPAGAIN;

	creds = POPs;

	*cred = GIT_SV_TO_PTR(Cred, creds);

	FREETMPS;
	LEAVE;

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
	NULL, /* dup */
#endif /* MGf_DUP */
#if MGf_LOCAL
	NULL, /* local */
#endif /* MGf_LOCAL */
};

void xs_object_magic_attach_struct(pTHX_ SV *sv, void *ptr) {
	sv_magicext(sv, NULL, PERL_MAGIC_ext, &null_mg_vtbl, ptr, 0);
}

STATIC MAGIC *xs_object_magic_get_mg(pTHX_ SV *sv) {
	MAGIC *mg;

	if (SvTYPE(sv) >= SVt_PVMG) {
		for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
			if ((mg->mg_type == PERL_MAGIC_ext) &&
			    (mg->mg_virtual == &null_mg_vtbl))
				return mg;
		}
	}

	return NULL;
}

void *xs_object_magic_get_struct(pTHX_ SV *sv) {
	MAGIC *mg = xs_object_magic_get_mg(aTHX_ sv);

	return (mg) ? mg -> mg_ptr : NULL;
}

#define GIT_NEW_OBJ_DOUBLE(rv, class, primary, secondary)	\
	STMT_START {						\
		(rv) = sv_setref_pv(newSV(0), SvPVbyte_nolen(class), primary); \
		xs_object_magic_attach_struct(			\
			aTHX_ SvRV(rv),				\
			SvREFCNT_inc_NN(SvRV(secondary))	\
		);						\
	} STMT_END

MODULE = Git::Raw			PACKAGE = Git::Raw

INCLUDE: xs/Blob.xs
INCLUDE: xs/Branch.xs
INCLUDE: xs/Commit.xs
INCLUDE: xs/Config.xs
INCLUDE: xs/Cred.xs
INCLUDE: xs/Diff.xs
INCLUDE: xs/Index.xs
INCLUDE: xs/Push.xs
INCLUDE: xs/Reference.xs
INCLUDE: xs/RefSpec.xs
INCLUDE: xs/Remote.xs
INCLUDE: xs/Repository.xs
INCLUDE: xs/Signature.xs
INCLUDE: xs/Stash.xs
INCLUDE: xs/Tag.xs
INCLUDE: xs/Tree.xs
INCLUDE: xs/TreeEntry.xs
INCLUDE: xs/Walker.xs
