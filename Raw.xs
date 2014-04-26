#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pv_flags
#define NEED_sv_2pvbyte_GLOBAL
#define NEED_newRV_noinc_GLOBAL

#include "ppport.h"

#include <git2.h>
#include <git2/sys/filter.h>
#include <git2/sys/repository.h>

typedef struct {
	SV *progress;
	SV *completion;
	SV *credentials;
	SV *transfer_progress;
	SV *update_tips;
} git_raw_remote_callbacks;

typedef struct {
	SV *packbuilder_progress;
	SV *transfer_progress;
	SV *status;
} git_raw_push_callbacks;

typedef struct {
	SV *initialize;
	SV *shutdown;
	SV *check;
	SV *apply;
	SV *cleanup;
} git_filter_callbacks;

typedef git_blame * Blame;
typedef git_blame_hunk * Blame_Hunk;
typedef git_blob * Blob;
typedef git_reference * Branch;
typedef git_commit * Commit;
typedef git_config * Config;
typedef git_diff * Diff;
typedef git_diff_delta * Diff_Delta;
typedef git_diff_file * Diff_File;
typedef git_diff_hunk * Diff_Hunk;
typedef git_diff_stats * Diff_Stats;
typedef git_index * Index;
typedef git_index_entry * Index_Entry;
typedef git_patch * Patch;
typedef git_pathspec * PathSpec;
typedef git_pathspec_match_list * PathSpec_MatchList;
typedef git_reference * Reference;
typedef git_reflog * Reflog;
typedef git_refspec * RefSpec;
typedef git_repository * Repository;
typedef git_signature * Signature;
typedef git_tag * Tag;
typedef git_tree * Tree;
typedef git_treebuilder * Tree_Builder;
typedef git_tree_entry * Tree_Entry;
typedef git_revwalk * Walker;

typedef struct {
	git_filter filter;
	git_filter_callbacks callbacks;
	char *name;
	char *attributes;
} git_raw_filter;

typedef git_raw_filter * Filter;
typedef git_filter_source * Filter_Source;

typedef struct {
	git_remote *remote;
	git_raw_remote_callbacks callbacks;
} git_raw_remote;

typedef git_raw_remote * Remote;

/* This will get fixed upstream */
typedef int (*git_push_status_cb)(const char *ref, const char *msg, void *data);

typedef struct {
	git_push *push;
	git_raw_push_callbacks callbacks;
} git_raw_push;

typedef git_raw_push * Push;

typedef struct {
	git_cred *cred;
	SV *callback;
} git_raw_cred;

typedef git_raw_cred * Cred;

#ifndef GIT_SSH
/* Reduces further conditional compile problems */
typedef struct _LIBSSH2_USERAUTH_KBDINT_PROMPT
{
	char* text;
	unsigned int length;
	unsigned char echo;
} LIBSSH2_USERAUTH_KBDINT_PROMPT;

typedef struct _LIBSSH2_USERAUTH_KBDINT_RESPONSE
{
	char* text;
	unsigned int length;
} LIBSSH2_USERAUTH_KBDINT_RESPONSE;
#endif

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

STATIC void xs_object_magic_attach_struct(pTHX_ SV *sv, void *ptr) {
	sv_magicext(sv, NULL, PERL_MAGIC_ext, &null_mg_vtbl, ptr, 0);
}

STATIC void *xs_object_magic_get_struct(pTHX_ SV *sv) {
	MAGIC *mg = NULL;

	if (SvTYPE(sv) >= SVt_PVMG) {
		MAGIC *tmp;

		for (tmp = SvMAGIC(sv); tmp;
		     tmp = tmp -> mg_moremagic) {
			if ((tmp -> mg_type == PERL_MAGIC_ext) &&
			    (tmp -> mg_virtual == &null_mg_vtbl))
				mg = tmp;
		}
	}

	return (mg) ? mg -> mg_ptr : NULL;
}

#define GIT_SV_TO_MAGIC(SV) \
	xs_object_magic_get_struct(aTHX_ SvRV(SV))

#define GIT_NEW_OBJ(rv, class, sv)				\
	STMT_START {						\
		(rv) = sv_setref_pv(newSV(0), class, sv);	\
	} STMT_END

#define GIT_NEW_OBJ_WITH_MAGIC(rv, class, sv, magic)		\
	STMT_START {						\
		(rv) = sv_setref_pv(newSV(0), class, sv);	\
								\
		xs_object_magic_attach_struct(			\
			aTHX_ SvRV(rv), SvREFCNT_inc_NN(magic)	\
		);						\
	} STMT_END

STATIC void git_check_error(int err) {
	const git_error *error;

	if (err == GIT_OK)
		return;

	error = giterr_last();

	if (error)
		Perl_croak(aTHX_ "%s", error -> message);

	if (SvTRUE(ERRSV))
		Perl_croak (aTHX_ "%s", SvPVbyte_nolen(ERRSV));

	Perl_croak(aTHX_ "%s", "Unknown error!");
}

STATIC SV *git_obj_to_sv(git_object *o, SV *repo) {
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

STATIC git_object *git_sv_to_obj(SV *sv) {
	if (sv_isobject(sv) && (
		sv_derived_from(sv, "Git::Raw::Blob") ||
		sv_derived_from(sv, "Git::Raw::Commit") ||
		sv_derived_from(sv, "Git::Raw::Tag") ||
		sv_derived_from(sv, "Git::Raw::Tree")
	))
		return INT2PTR(git_object *, SvIV((SV *) SvRV(sv)));

	return NULL;
}

STATIC void *git_sv_to_ptr(const char *type, SV *sv) {
	SV *full_type = sv_2mortal(newSVpvf("Git::Raw::%s", type));

	if (sv_isobject(sv) && sv_derived_from(sv, SvPV_nolen(full_type)))
		return INT2PTR(void *, SvIV((SV *) SvRV(sv)));

	Perl_croak(aTHX_ "Argument is not of type %s", SvPV_nolen(full_type));

	return NULL;
}

#define GIT_SV_TO_PTR(type, sv) \
	git_sv_to_ptr(#type, sv)

STATIC SV *git_oid_to_sv(const git_oid *oid) {
	char out[41];

	git_oid_fmt(out, oid);
	out[40] = '\0';

	return newSVpv(out, 0);
}

STATIC git_oid *git_sv_to_commitish(Repository repo, SV *sv, git_oid *oid) {
	git_oid *result = NULL;
	git_reference *ref = NULL;
	git_object *obj = NULL;

	if (sv_isobject(sv)) {
		if (sv_derived_from(sv, "Git::Raw::Reference")) {
			int rc = git_reference_peel(&obj,
				GIT_SV_TO_PTR(Reference, sv),
				GIT_OBJ_COMMIT
			);
			git_check_error(rc);

			git_oid_cpy(oid, git_object_id(obj));
		} else if (sv_derived_from(sv, "Git::Raw::Commit")) {
			git_oid_cpy(oid, git_commit_id(GIT_SV_TO_PTR(Commit, sv)));
		} else
			goto on_error;
	} else {
		STRLEN len;
		const char *commitish_name = NULL;

		/* substr() may return a SVt_PVLV, need to perform some
		 * force majeur */
		if (SvPOK(sv)) {
			commitish_name = SvPVbyte(sv, len);
		} else if (SvTYPE(sv) == SVt_PVLV) {
			commitish_name = SvPVbyte_force(sv, len);
		}

		if (commitish_name) {
			/* first try and see if its a commit id, otherwise see if its
			 * a reference */
			if (git_oid_fromstrn(oid, commitish_name, len) >= 0) {
				if (len < GIT_OID_MINPREFIXLEN)
					goto on_error;

				if (len != GIT_OID_HEXSZ) {
					if (git_object_lookup_prefix(&obj, repo, oid,
						len, GIT_OBJ_COMMIT) < 0)
						goto on_error;

					git_oid_cpy(oid, git_object_id(obj));
				}
			} else {
				if (git_reference_lookup(&ref, repo, commitish_name) < 0 &&
					git_reference_dwim(&ref, repo, commitish_name) < 0)
						goto on_error;

				if (git_reference_peel(&obj, ref, GIT_OBJ_COMMIT) < 0)
					goto on_error;

				git_oid_cpy(oid, git_object_id(obj));
			}
		} else
			goto on_error;
	}

	result = oid;

on_error:
	git_object_free(obj);
	git_reference_free(ref);
	return result;
}

STATIC void git_init_remote_callbacks(git_raw_remote_callbacks *cbs) {
	cbs -> credentials = NULL;
	cbs -> progress = NULL;
	cbs -> completion = NULL;
	cbs -> transfer_progress = NULL;
	cbs -> update_tips = NULL;
}

STATIC void git_clean_remote_callbacks(git_raw_remote_callbacks *cbs) {
	if (cbs -> credentials) {
		SvREFCNT_dec(cbs -> credentials);
		cbs -> credentials = NULL;
	}

	if (cbs -> progress) {
		SvREFCNT_dec(cbs -> progress);
		cbs -> progress = NULL;
	}

	if (cbs -> completion) {
		SvREFCNT_dec(cbs -> completion);
		cbs -> completion = NULL;
	}

	if (cbs -> transfer_progress) {
		SvREFCNT_dec(cbs -> transfer_progress);
		cbs -> transfer_progress = NULL;
	}

	if (cbs -> update_tips) {
		SvREFCNT_dec(cbs -> update_tips);
		cbs -> update_tips = NULL;
	}
}

STATIC void git_init_push_callbacks(git_raw_push_callbacks *cbs) {
	cbs -> packbuilder_progress = NULL;
	cbs -> transfer_progress = NULL;
	cbs -> status = NULL;
}

STATIC void git_clean_push_callbacks(git_raw_push_callbacks *cbs) {
	if (cbs -> packbuilder_progress) {
		SvREFCNT_dec(cbs -> packbuilder_progress);
		cbs -> packbuilder_progress = NULL;
	}

	if (cbs -> transfer_progress) {
		SvREFCNT_dec(cbs -> transfer_progress);
		cbs -> transfer_progress = NULL;
	}

	if (cbs -> status) {
		SvREFCNT_dec(cbs -> status);
		cbs -> status = NULL;
	}
}

STATIC void git_clean_filter_callbacks(git_filter_callbacks *cbs) {
	if (cbs -> initialize) {
		SvREFCNT_dec(cbs -> initialize);
		cbs -> initialize = NULL;
	}

	if (cbs -> shutdown) {
		SvREFCNT_dec(cbs -> shutdown);
		cbs -> shutdown = NULL;
	}

	if (cbs -> check) {
		SvREFCNT_dec(cbs -> check);
		cbs -> check = NULL;
	}

	if (cbs -> apply) {
		SvREFCNT_dec(cbs -> apply);
		cbs -> apply = NULL;
	}

	if (cbs -> cleanup) {
		SvREFCNT_dec(cbs -> cleanup);
		cbs -> cleanup = NULL;
	}
}

STATIC SV *git_hv_sv_entry(HV *hv, const char *name) {
	SV **opt;

	if ((opt = hv_fetch(hv, name, strlen(name), 0)))
		return *opt;

	return NULL;
}

STATIC SV *git_hv_int_entry(HV *hv, const char *name) {
	SV **opt;

	if ((opt = hv_fetch(hv, name, strlen(name), 0))) {
		if (!SvIOK(*opt))
			Perl_croak(aTHX_ "Expected an integer for '%s'", name);

		return *opt;
	}

	return NULL;
}

STATIC SV *git_hv_string_entry(HV *hv, const char *name) {
	SV **opt;

	if ((opt = hv_fetch(hv, name, strlen(name), 0))) {
		if (!SvPOK(*opt))
			Perl_croak(aTHX_ "Expected a string for '%s'", name);

		return *opt;
	}

	return NULL;
}

STATIC AV *git_ensure_av(SV *sv, const char *identifier) {
	if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV)
		Perl_croak(aTHX_ "Invalid type for '%s', expected a list", identifier);

	return (AV *) SvRV(sv);
}

STATIC HV *git_ensure_hv(SV *sv, const char *identifier) {
	if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV)
		Perl_croak(aTHX_ "Invalid type for '%s', expected a hash", identifier);

	return (HV *) SvRV(sv);
}

STATIC SV *git_ensure_cv(SV *sv, const char *identifier) {
	if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVCV)
		Perl_croak(aTHX_ "Invalid type for '%s', expected a code reference", identifier);

	return sv;
}

STATIC SV *git_hv_code_entry(HV *hv, const char *name) {
	SV **opt;

	if ((opt = hv_fetch(hv, name, strlen(name), 0)))
		return git_ensure_cv(*opt, name);

	return NULL;
}

STATIC HV *git_hv_hash_entry(HV *hv, const char *name) {
	SV **opt;

	if ((opt = hv_fetch(hv, name, strlen(name), 0)))
		return git_ensure_hv(*opt, name);

	return NULL;
}

STATIC AV *git_hv_list_entry(HV *hv, const char *name) {
	SV **opt;

	if ((opt = hv_fetch(hv, name, strlen(name), 0)))
		return git_ensure_av(*opt, name);

	return NULL;
}

STATIC void git_flag_opt(HV *value, const char *name, int mask, unsigned *out) {
	SV *opt;

	if ((opt = git_hv_int_entry(value, name)) && SvIV(opt))
		*out |= mask;
}

STATIC SV *get_callback_option(HV *callbacks, const char *name) {
	SV *cb = NULL;

	if ((cb = git_hv_code_entry(callbacks, name)))
		SvREFCNT_inc(cb);

	return cb;
}

STATIC unsigned git_hv_to_diff_flag(HV *flags) {
	unsigned out = 0;

	git_flag_opt(flags, "reverse", GIT_DIFF_REVERSE, &out);

	git_flag_opt(flags, "include_ignored", GIT_DIFF_INCLUDE_IGNORED, &out);

	git_flag_opt(flags, "include_typechange", GIT_DIFF_INCLUDE_TYPECHANGE, &out);

	git_flag_opt(
		flags, "include_typechange_trees",
		GIT_DIFF_INCLUDE_TYPECHANGE_TREES, &out);

	git_flag_opt(
		flags, "recurse_ignored_dirs",
		GIT_DIFF_RECURSE_IGNORED_DIRS, &out
	);

	git_flag_opt(
		flags, "include_untracked",
		GIT_DIFF_INCLUDE_UNTRACKED, &out
	);

	git_flag_opt(
		flags, "recurse_untracked_dirs",
		GIT_DIFF_RECURSE_UNTRACKED_DIRS, &out
	);

	git_flag_opt(flags, "ignore_filemode", GIT_DIFF_IGNORE_FILEMODE, &out);

	git_flag_opt(flags, "ignore_case", GIT_DIFF_IGNORE_CASE, &out);

	git_flag_opt(
		flags, "ignore_submodules",
		GIT_DIFF_IGNORE_SUBMODULES, &out
	);

	git_flag_opt(
		flags, "ignore_whitespace",
		GIT_DIFF_IGNORE_WHITESPACE, &out
	);

	git_flag_opt(
		flags, "ignore_whitespace_change",
		GIT_DIFF_IGNORE_WHITESPACE_CHANGE, &out
	);

	git_flag_opt(
		flags, "ignore_whitespace_eol",
		GIT_DIFF_IGNORE_WHITESPACE_EOL, &out
	);

	git_flag_opt(
		flags, "skip_binary_check",
		GIT_DIFF_SKIP_BINARY_CHECK, &out
	);

	git_flag_opt(
		flags, "enable_fast_untracked_dirs",
		GIT_DIFF_ENABLE_FAST_UNTRACKED_DIRS, &out
	);

	git_flag_opt(
		flags, "show_untracked_content",
		GIT_DIFF_SHOW_UNTRACKED_CONTENT, &out
	);

	git_flag_opt(
		flags, "show_unmodified",
		GIT_DIFF_SHOW_UNMODIFIED, &out
	);

	git_flag_opt(flags, "patience", GIT_DIFF_PATIENCE, &out);

	git_flag_opt(flags, "minimal", GIT_DIFF_MINIMAL, &out);

	return out;
}

STATIC unsigned git_hv_to_diff_find_flag(HV *flags) {
	unsigned out = 0;

	git_flag_opt(flags, "renames", GIT_DIFF_FIND_RENAMES, &out);

	git_flag_opt(
		flags,
		"renames_from_rewrites",
		GIT_DIFF_FIND_RENAMES_FROM_REWRITES, &out
	);

	git_flag_opt(flags, "copies", GIT_DIFF_FIND_COPIES, &out);

	git_flag_opt(
		flags,
		"copies_from_unmodified",
		GIT_DIFF_FIND_COPIES_FROM_UNMODIFIED, &out
	);

	git_flag_opt(flags, "rewrites", GIT_DIFF_FIND_REWRITES, &out);

	git_flag_opt(flags, "break_rewrites", GIT_DIFF_BREAK_REWRITES, &out);

	git_flag_opt(flags, "untracked", GIT_DIFF_FIND_FOR_UNTRACKED, &out);

	git_flag_opt(flags, "all", GIT_DIFF_FIND_ALL, &out);

	git_flag_opt(
		flags,
		"ignore_leading_whitespace",
		GIT_DIFF_FIND_IGNORE_LEADING_WHITESPACE, &out
	);

	git_flag_opt(
		flags,
		"ignore_whitespace",
		GIT_DIFF_FIND_IGNORE_WHITESPACE, &out
	);

	git_flag_opt(
		flags,
		"dont_ignore_whitespace", GIT_DIFF_FIND_DONT_IGNORE_WHITESPACE, &out
	);

	git_flag_opt(
		flags,
		"exact_match_only", GIT_DIFF_FIND_EXACT_MATCH_ONLY, &out
	);

	git_flag_opt(
		flags,
		"break_rewrites_for_renames_only", GIT_DIFF_BREAK_REWRITES_FOR_RENAMES_ONLY,
		&out
	);

	git_flag_opt(flags,
		"remove_unmodified", GIT_DIFF_FIND_REMOVE_UNMODIFIED,
		&out
	);

	return out;
}

STATIC unsigned git_hv_to_checkout_strategy(HV *strategy) {
	unsigned out = 0;

	git_flag_opt(strategy, "none", GIT_CHECKOUT_NONE, &out);

	git_flag_opt(strategy, "force", GIT_CHECKOUT_FORCE, &out);

	git_flag_opt(strategy, "safe", GIT_CHECKOUT_SAFE, &out);

	git_flag_opt(strategy, "safe_create", GIT_CHECKOUT_SAFE_CREATE, &out);

	git_flag_opt(
		strategy, "allow_conflicts",
		GIT_CHECKOUT_ALLOW_CONFLICTS, &out
	);

	git_flag_opt(
		strategy, "remove_untracked",
		GIT_CHECKOUT_REMOVE_UNTRACKED, &out
	);

	git_flag_opt(
		strategy, "remove_ignored",
		GIT_CHECKOUT_REMOVE_IGNORED, &out
	);

	git_flag_opt(strategy, "update_only", GIT_CHECKOUT_UPDATE_ONLY, &out);

	git_flag_opt(
		strategy, "dont_update_index",
		GIT_CHECKOUT_DONT_UPDATE_INDEX, &out
	);

	git_flag_opt(strategy, "no_refresh", GIT_CHECKOUT_NO_REFRESH, &out);

	git_flag_opt(
		strategy, "skip_unmerged",
		GIT_CHECKOUT_SKIP_UNMERGED, &out
	);

	git_flag_opt(strategy, "use_ours", GIT_CHECKOUT_USE_OURS, &out);

	git_flag_opt(strategy, "use_theirs", GIT_CHECKOUT_USE_THEIRS, &out);

	git_flag_opt(
		strategy, "skip_locked_directories",
		GIT_CHECKOUT_SKIP_LOCKED_DIRECTORIES, &out);

	git_flag_opt(
		strategy, "dont_overwrite_ignored",
		GIT_CHECKOUT_DONT_OVERWRITE_IGNORED, &out);

	git_flag_opt(
		strategy, "conflict_style_merge",
		GIT_CHECKOUT_CONFLICT_STYLE_MERGE, &out);

	git_flag_opt(
		strategy, "conflict_style_diff3",
		GIT_CHECKOUT_CONFLICT_STYLE_DIFF3, &out);

	git_flag_opt(
		strategy, "disable_pathspec_match",
		GIT_CHECKOUT_DISABLE_PATHSPEC_MATCH, &out);

	return out;
}

STATIC int git_diff_cb(const git_diff_delta *delta, const git_diff_hunk *hunk,
		const git_diff_line *line, void *data) {
	dSP;

	SV *coderef = data;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	switch (line -> origin) {
		case GIT_DIFF_LINE_CONTEXT:
			XPUSHs(sv_2mortal(newSVpv("ctx", 0)));
			break;

		case GIT_DIFF_LINE_ADDITION:
		case GIT_DIFF_LINE_ADD_EOFNL:
			XPUSHs(sv_2mortal(newSVpv("add", 0)));
			break;

		case GIT_DIFF_LINE_DELETION:
		case GIT_DIFF_LINE_DEL_EOFNL:
			XPUSHs(sv_2mortal(newSVpv("del", 0)));
			break;

		case GIT_DIFF_LINE_FILE_HDR:
			XPUSHs(sv_2mortal(newSVpv("file", 0)));
			break;

		case GIT_DIFF_LINE_HUNK_HDR:
			XPUSHs(sv_2mortal(newSVpv("hunk", 0)));
			break;

		case GIT_DIFF_LINE_BINARY:
			XPUSHs(sv_2mortal(newSVpv("bin", 0)));
			break;

		default:
			Perl_croak(aTHX_ "Unexpected diff usage");
			break;
	}

	XPUSHs(sv_2mortal(newSVpv(line -> content, line -> content_len)));
	PUTBACK;

	call_sv(coderef, G_DISCARD);

	FREETMPS;
	LEAVE;

	return 0;
}

typedef struct {
	Repository repo_ptr;
	SV *repo;
	SV *cb;
	const char *class;
} git_foreach_payload;

STATIC int git_config_foreach_cbb(const git_config_entry *entry, void *payload) {
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

STATIC int git_stash_foreach_cb(size_t i, const char *msg, const git_oid *oid, void *payload) {
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

STATIC int git_tag_foreach_cbb(const char *name, git_oid *oid, void *payload) {
	dSP;
	int rv;
	git_object *tag;

	SV *repo, *cb_arg;
	git_foreach_payload *pl = payload;

	int rc = git_object_lookup(&tag, pl -> repo_ptr, oid, GIT_OBJ_ANY);
	git_check_error(rc);

	if (git_object_type(tag) != GIT_OBJ_TAG) {
		git_object_free(tag);

		return 0;
	}

	ENTER;
	SAVETMPS;

	repo = SvRV(pl -> repo);

	cb_arg = sv_newmortal();
	sv_setref_pv(cb_arg, pl -> class, (void *) tag);
	xs_object_magic_attach_struct(aTHX_ SvRV(cb_arg), SvREFCNT_inc_NN(repo));

	PUSHMARK(SP);
	PUSHs(cb_arg);
	PUTBACK;

	call_sv(pl -> cb, G_SCALAR);

	SPAGAIN;

	rv = POPi;

	FREETMPS;
	LEAVE;

	return rv;
}

STATIC int git_checkout_notify_cbb(git_checkout_notify_t why, const char *path, const git_diff_file *baseline,
	const git_diff_file *target, const git_diff_file *workdir, void *payload) {
	dSP;

	int rv;
	AV *w = newAV();

	if (why & GIT_CHECKOUT_NOTIFY_NONE)
		av_push(w, newSVpv("none", 0));

	if (why & GIT_CHECKOUT_NOTIFY_CONFLICT)
		av_push(w, newSVpv("conflict", 0));

	if (why & GIT_CHECKOUT_NOTIFY_DIRTY)
		av_push(w, newSVpv("dirty", 0));

	if (why & GIT_CHECKOUT_NOTIFY_UPDATED)
		av_push(w, newSVpv("updated", 0));

	if (why & GIT_CHECKOUT_NOTIFY_UNTRACKED)
		av_push(w, newSVpv("untracked", 0));

	if (why & GIT_CHECKOUT_NOTIFY_IGNORED)
		av_push(w, newSVpv("ignored", 0));

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUSHs(newSVpv(path, 0));
	PUSHs(sv_2mortal(newRV_noinc((SV *) w)));
	PUTBACK;

	call_sv(payload, G_SCALAR);

	SPAGAIN;

	rv = POPi;

	FREETMPS;
	LEAVE;

	return rv;
}

STATIC void git_checkout_progress_cbb(const char *path, size_t completed_steps,
                                      size_t total_steps, void *payload) {
	dSP;

	SV *coderef = payload;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUSHs(newSVpv(path, 0));
	PUSHs(newSViv(completed_steps));
	PUSHs(newSViv(total_steps));
	PUTBACK;

	call_sv(coderef, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;
}

STATIC int git_progress_cbb(const char *str, int len, void *cbs) {
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUSHs(newSVpv(str, len));
	PUTBACK;

	call_sv(((git_raw_remote_callbacks *) cbs) -> progress, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;

	return 0;
}

STATIC int git_completion_cbb(git_remote_completion_type type, void *cbs) {
	dSP;
	SV* ct;

	switch (type) {
		case GIT_REMOTE_COMPLETION_DOWNLOAD:
			ct = newSVpv("download", 0);
			break;

		case GIT_REMOTE_COMPLETION_INDEXING:
			ct = newSVpv("indexing", 0);
			break;

		case GIT_REMOTE_COMPLETION_ERROR:
			ct = newSVpv("error", 0);
			break;

		default:
			Perl_croak(aTHX_ "Unhandled completion type");
			break;
	}

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUSHs(ct);
	PUTBACK;

	call_sv(((git_raw_remote_callbacks *) cbs) -> completion, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;

	return 0;
}

STATIC int git_transfer_progress_cbb(const git_transfer_progress *stats, void *cbs) {
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUSHs(newSViv(stats -> total_objects));
	PUSHs(newSViv(stats -> received_objects));
	PUSHs(newSViv(stats -> local_objects));
	PUSHs(newSViv(stats -> total_deltas));
	PUSHs(newSViv(stats -> indexed_deltas));
	PUSHs(newSVuv(stats -> received_bytes));
	PUTBACK;

	call_sv(((git_raw_remote_callbacks *) cbs) -> transfer_progress, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;

	return 0;
}

STATIC int git_push_transfer_progress_cbb(unsigned int current, unsigned int total, size_t bytes, void *cbs) {
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUSHs(newSVuv(current));
	PUSHs(newSVuv(total));
	PUSHs(newSVuv(bytes));
	PUTBACK;

	call_sv(((git_raw_push_callbacks *) cbs) -> transfer_progress, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;

	return 0;
}

STATIC int git_packbuilder_progress_cbb(int stage, unsigned int current, unsigned int total, void *cbs) {
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUSHs(newSViv(stage));
	PUSHs(newSVuv(current));
	PUSHs(newSVuv(total));
	PUTBACK;

	call_sv(((git_raw_push_callbacks *) cbs) -> packbuilder_progress, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;

	return 0;
}

STATIC int git_push_status_cbb(const char *ref, const char *msg, void *cbs) {
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUSHs(newSVpv(ref, 0));
	PUSHs(newSVpv(msg, 0));
	PUTBACK;

	call_sv(((git_raw_push_callbacks *) cbs) -> status, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;

	return 0;
}

STATIC int git_update_tips_cbb(const char *name, const git_oid *a,
	const git_oid *b, void *cbs) {
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUSHs(newSVpv(name, 0));
	PUSHs(a != NULL ? git_oid_to_sv(a) : &PL_sv_undef);
	PUSHs(b != NULL ? git_oid_to_sv(b) : &PL_sv_undef);
	PUTBACK;

	call_sv(((git_raw_remote_callbacks *) cbs) -> update_tips, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;

	return 0;
}

STATIC int git_credentials_cbb(git_cred **cred, const char *url,
		const char *usr_from_url, unsigned int allow, void *cbs) {
	dSP;
	Cred creds;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUSHs(newSVpv(url, 0));
	PUSHs(newSVpv(usr_from_url, 0));
	PUTBACK;

	call_sv(((git_raw_remote_callbacks *) cbs) -> credentials, G_SCALAR);

	SPAGAIN;

	creds = GIT_SV_TO_PTR(Cred, POPs);
	*cred = creds -> cred;

	FREETMPS;
	LEAVE;

	return 0;
}

STATIC void git_ssh_interactive_cbb(const char *name, int name_len, const char *instruction, int instruction_len,
			int num_prompts, const LIBSSH2_USERAUTH_KBDINT_PROMPT *prompts, LIBSSH2_USERAUTH_KBDINT_RESPONSE *responses, void **abstract) {
	dSP;

	int i, count;
	SV *cb = *abstract;

	if (num_prompts == 0)
		return;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUSHs(newSVpv(name, name_len));
	PUSHs(newSVpv(instruction, instruction_len));
	for (i = 0; i < num_prompts; ++i) {
		HV *prompt = newHV();
		hv_stores(prompt, "text", newSVpvn(prompts[i].text, prompts[i].length));
		hv_stores(prompt, "echo", newSViv(prompts[i].echo));
		PUSHs(sv_2mortal(newRV_noinc((SV*)prompt)));
	}
	PUTBACK;

	count = call_sv(cb, G_ARRAY);

	SPAGAIN;

	if (count != num_prompts)
		Perl_croak(aTHX_ "Expected %d response(s) got %d", num_prompts, count);

	for (i = 1; i <= count; ++i) {
		STRLEN len;
		SV *r = POPs;
		const char *response = SvPV(r, len);
		int index = num_prompts - i;

		New(0, responses[index].text, len, char);
		Copy(response, responses[index].text, len, char);
		responses[index].length = len;
	}

	FREETMPS;
	LEAVE;
}

STATIC int git_filter_init_cbb(git_filter *filter)
{
	dSP;

	int rv;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUTBACK;

	call_sv(((git_raw_filter *) filter) -> callbacks.initialize, G_EVAL|G_SCALAR);

	SPAGAIN;

	if (SvTRUE(ERRSV)) {
		rv = -1;
		(void) POPs;
	} else {
		rv = POPi;
	}

	FREETMPS;
	LEAVE;

	return rv;
}

STATIC void git_filter_shutdown_cbb(git_filter *filter)
{
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUTBACK;

	call_sv(((git_raw_filter *) filter) -> callbacks.shutdown, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;
}

STATIC int git_filter_check_cbb(git_filter *filter, void **payload,
	const git_filter_source *src, const char **attr_values)
{
	dSP;

	int rv;
	SV *filter_source = NULL;

	GIT_NEW_OBJ(
		filter_source, "Git::Raw::Filter::Source", (void *) src
	);

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUSHs(filter_source);
	PUTBACK;

	call_sv(((git_raw_filter *) filter) -> callbacks.check, G_EVAL|G_SCALAR);

	SPAGAIN;

	if (SvTRUE(ERRSV)) {
		rv = -1;
		(void) POPs;
	} else {
		rv = POPi;
	}

	FREETMPS;
	LEAVE;

	SvREFCNT_dec(filter_source);

	return rv;
}

STATIC int git_filter_apply_cbb(git_filter *filter, void **payload,
	git_buf *to, const git_buf *from, const git_filter_source *src)
{
	dSP;

	int rv;
	SV *filter_source = NULL;
	SV *result = newSV(from -> size);

	GIT_NEW_OBJ(
		filter_source, "Git::Raw::Filter::Source", (void *) src
	);

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUSHs(filter_source);
	PUSHs(newSVpv(from -> ptr, from -> size));
	PUSHs(newRV_noinc(result));
	PUTBACK;

	call_sv(((git_raw_filter *) filter) -> callbacks.apply, G_EVAL|G_SCALAR);

	SPAGAIN;

	if (SvTRUE(ERRSV)) {
		rv = -1;
		(void) POPs;
	} else {
		rv = POPi;
	}

	FREETMPS;
	LEAVE;

	if (rv == GIT_OK) {
		STRLEN len;
		const char *ptr = SvPV(result, len);

		git_buf_set(to, ptr, len);
	}

	SvREFCNT_dec(result);
	SvREFCNT_dec(filter_source);

	return rv;
}

STATIC void git_filter_cleanup_cbb(git_filter *filter, void *payload)
{
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUTBACK;

	call_sv(((git_raw_filter *) filter) -> callbacks.cleanup, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;
}


STATIC void git_hv_to_checkout_opts(HV *opts, git_checkout_options *checkout_opts) {
	char **paths = NULL;
	SV *opt;
	HV *hopt;
	AV *lopt;

	if ((hopt = git_hv_hash_entry(opts, "checkout_strategy")))
		checkout_opts -> checkout_strategy =
			git_hv_to_checkout_strategy(hopt);

	if ((lopt = git_hv_list_entry(opts, "paths"))) {
		SV **path;
		size_t count = 0;

		while ((path = av_fetch(lopt, count, 0))) {
			if (!SvOK(*path))
				continue;

			Renew(paths, count+1, char *);
			paths[count++] = SvPVbyte_nolen(*path);
		}

		if (count > 0) {
			checkout_opts -> paths.strings = paths;
			checkout_opts -> paths.count   = count;
		}
	}

	if ((opt = git_hv_string_entry(opts, "target_directory")))
		checkout_opts -> target_directory = SvPVbyte_nolen(opt);

	if ((opt = git_hv_string_entry(opts, "ancestor_label")))
		checkout_opts -> ancestor_label = SvPVbyte_nolen(opt);

	if ((opt = git_hv_string_entry(opts, "our_label")))
		checkout_opts -> our_label = SvPVbyte_nolen(opt);

	if ((opt = git_hv_string_entry(opts, "their_label")))
		checkout_opts -> their_label = SvPVbyte_nolen(opt);

	if ((hopt = git_hv_hash_entry(opts, "callbacks"))) {
		if ((checkout_opts -> progress_payload =
				get_callback_option(hopt, "progress")))
			checkout_opts -> progress_cb = git_checkout_progress_cbb;

		if ((checkout_opts -> notify_payload =
				get_callback_option(hopt, "notify"))) {
			checkout_opts -> notify_cb      = git_checkout_notify_cbb;

			if ((lopt = git_hv_list_entry(opts, "notify"))) {
				size_t count = 0;
				SV **flag;

				while ((flag = av_fetch(lopt, count++, 0))) {
					if (SvPOK(*flag)) {
						const char *f = SvPVbyte_nolen(*flag);

						if (strcmp(f, "conflict") == 0)
							checkout_opts -> notify_flags |= GIT_CHECKOUT_NOTIFY_CONFLICT;

						if (strcmp(f, "dirty") == 0)
							checkout_opts -> notify_flags |= GIT_CHECKOUT_NOTIFY_DIRTY;

						if (strcmp(f, "updated") == 0)
							checkout_opts -> notify_flags |= GIT_CHECKOUT_NOTIFY_UPDATED;

						if (strcmp(f, "untracked") == 0)
							checkout_opts -> notify_flags |= GIT_CHECKOUT_NOTIFY_UNTRACKED;

						if (strcmp(f, "ignored") == 0)
							checkout_opts -> notify_flags |= GIT_CHECKOUT_NOTIFY_IGNORED;

						if (strcmp(f, "all") == 0)
							checkout_opts -> notify_flags |= GIT_CHECKOUT_NOTIFY_ALL;
					} else
						Perl_croak(aTHX_ "Invalid type for 'notify' value");
				}
			}
		}
	}
}

STATIC void git_hv_to_merge_opts(HV *opts, git_merge_options *merge_options) {
	AV *lopt;
	SV *opt;

	if ((lopt = git_hv_list_entry(opts, "flags"))) {
		size_t count = 0;
		SV **flag;

		while ((flag = av_fetch(lopt, count++, 0))) {
			if (SvPOK(*flag)) {
				const char *f = SvPVbyte_nolen(*flag);

				if (strcmp(f, "find_renames") == 0)
					merge_options -> flags |= GIT_MERGE_TREE_FIND_RENAMES;
				else
					Perl_croak(aTHX_ "Invalid 'flags' value");
			} else
				Perl_croak(aTHX_ "Invalid type for 'flag'");
		}
	}

	if ((opt = git_hv_string_entry(opts, "favor"))) {
		const char *favor = SvPVbyte_nolen(opt);
		if (strcmp(favor, "ours") == 0)
			merge_options -> file_favor =
				GIT_MERGE_FILE_FAVOR_OURS;
		else if (strcmp(favor, "theirs") == 0)
			merge_options -> file_favor =
				GIT_MERGE_FILE_FAVOR_THEIRS;
		else if (strcmp(favor, "union") == 0)
			merge_options -> file_favor =
				GIT_MERGE_FILE_FAVOR_UNION;
		else
			Perl_croak(aTHX_ "Invalid 'favor' value");
	}

	if ((opt = git_hv_int_entry(opts, "rename_threshold")))
		merge_options -> rename_threshold = SvIV(opt);

	if ((opt = git_hv_int_entry(opts, "target_limit")))
		merge_options -> target_limit = SvIV(opt);
}

MODULE = Git::Raw			PACKAGE = Git::Raw

BOOT:
	git_threads_init();

INCLUDE: xs/Blame.xs
INCLUDE: xs/Blame/Hunk.xs
INCLUDE: xs/Blob.xs
INCLUDE: xs/Branch.xs
INCLUDE: xs/Commit.xs
INCLUDE: xs/Config.xs
INCLUDE: xs/Cred.xs
INCLUDE: xs/Diff.xs
INCLUDE: xs/Diff/Delta.xs
INCLUDE: xs/Diff/File.xs
INCLUDE: xs/Diff/Hunk.xs
INCLUDE: xs/Diff/Stats.xs
INCLUDE: xs/Filter.xs
INCLUDE: xs/Filter/Source.xs
INCLUDE: xs/Graph.xs
INCLUDE: xs/Index.xs
INCLUDE: xs/Index/Entry.xs
INCLUDE: xs/Patch.xs
INCLUDE: xs/PathSpec.xs
INCLUDE: xs/PathSpec/MatchList.xs
INCLUDE: xs/Push.xs
INCLUDE: xs/Reference.xs
INCLUDE: xs/Reflog.xs
INCLUDE: xs/RefSpec.xs
INCLUDE: xs/Remote.xs
INCLUDE: xs/Repository.xs
INCLUDE: xs/Signature.xs
INCLUDE: xs/Stash.xs
INCLUDE: xs/Tag.xs
INCLUDE: xs/Tree.xs
INCLUDE: xs/Tree/Builder.xs
INCLUDE: xs/Tree/Entry.xs
INCLUDE: xs/Walker.xs
