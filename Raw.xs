#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pv_flags
#define NEED_sv_2pvbyte_GLOBAL
#define NEED_newRV_noinc_GLOBAL

#include "ppport.h"

#ifdef GIT_SSH
#include <libssh2.h>
#else
#include "libssh2-compat.h"
#endif

#include <git2.h>
#include <git2/sys/filter.h>
#include <git2/sys/repository.h>

/* internally generated errors */
#define ASSERT            -10000
#define USAGE             -10001
#define RESOLVE           -10002

/* internally generated classes */
#define INTERNAL          -20000

#if defined(_MSC_VER) || defined(__MINGW32__)
#undef ERROR
#undef PASSTHROUGH
#undef CALLBACK
#endif

/* remap libgit2 error enum's to defines */
#ifdef EAUTH
#undef EAUTH
#endif

#define OK                GIT_OK
#define ERROR             GIT_ERROR
#define ENOTFOUND         GIT_ENOTFOUND
#define EEXISTS           GIT_EEXISTS
#define EAMBIGUOUS        GIT_EAMBIGUOUS
#define EBUFS             GIT_EBUFS
#define EUSER             GIT_EUSER
#define EBAREREPO         GIT_EBAREREPO
#define EUNBORNBRANCH     GIT_EUNBORNBRANCH
#define EUNMERGED         GIT_EUNMERGED
#define ENONFASTFORWARD   GIT_ENONFASTFORWARD
#define EINVALIDSPEC      GIT_EINVALIDSPEC
#define EMERGECONFLICT    GIT_EMERGECONFLICT
#define ELOCKED           GIT_ELOCKED
#define EMODIFIED         GIT_EMODIFIED
#define EAUTH             GIT_EAUTH
#define ECERTIFICATE      GIT_ECERTIFICATE
#define EAPPLIED          GIT_EAPPLIED
#define EPEEL             GIT_EPEEL
#define PASSTHROUGH       GIT_PASSTHROUGH
#define ITEROVER          GIT_ITEROVER

/* remap libgit2 class enum's to defines */
#define NONE          GITERR_NONE
#define NOMEMORY      GITERR_NOMEMORY
#define OS            GITERR_OS
#define INVALID       GITERR_INVALID
#define REFERENCE     GITERR_REFERENCE
#define ZLIB          GITERR_ZLIB
#define REPOSITORY    GITERR_REPOSITORY
#define CONFIG        GITERR_CONFIG
#define REGEX         GITERR_REGEX
#define ODB           GITERR_ODB
#define INDEX         GITERR_INDEX
#define OBJECT        GITERR_OBJECT
#define NET           GITERR_NET
#define TAG           GITERR_TAG
#define TREE          GITERR_TREE
#define INDEXER       GITERR_INDEXER
#define SSL           GITERR_SSL
#define SUBMODULE     GITERR_SUBMODULE
#define THREAD        GITERR_THREAD
#define STASH         GITERR_STASH
#define CHECKOUT      GITERR_CHECKOUT
#define FETCHHEAD     GITERR_FETCHHEAD
#define MERGE         GITERR_MERGE
#define SSH           GITERR_SSH
#define FILTER        GITERR_FILTER
#define REVERT        GITERR_REVERT
#define CALLBACK      GITERR_CALLBACK
#define CHERRYPICK    GITERR_CHERRYPICK

#include "const-c-error.inc"
#include "const-c-category.inc"

#ifdef _MSC_VER
#pragma warning (disable : 4244 4267 )
#endif

#undef assert
#define assert(expr) ((expr) ? (void)0 : croak("Assertion %s failed (%s:%d)", #expr, __FILE__, __LINE__))

typedef struct {
	SV *progress;
	SV *credentials;
	SV *certificate_check;
	SV *transfer_progress;
	SV *update_tips;
	SV *pack_progress;
	SV *push_transfer_progress;
	SV *push_update_reference;
	int push_success;
} git_raw_remote_callbacks;

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
typedef git_cert * Cert;
typedef git_cert_hostkey * Cert_HostKey;
typedef git_cert_x509 * Cert_X509;
typedef git_commit * Commit;
typedef git_config * Config;
typedef git_diff * Diff;
typedef git_diff_delta * Diff_Delta;
typedef git_diff_file * Diff_File;
typedef git_diff_hunk * Diff_Hunk;
typedef git_diff_stats * Diff_Stats;
typedef git_index * Index;
typedef git_index_entry * Index_Entry;
typedef git_merge_file_result * Merge_File_Result;
typedef git_note * Note;
typedef git_patch * Patch;
typedef git_pathspec * PathSpec;
typedef git_pathspec_match_list * PathSpec_MatchList;
typedef git_reference * Reference;
typedef git_reflog * Reflog;
typedef git_reflog_entry * Reflog_Entry;
typedef git_refspec * RefSpec;
typedef git_signature * Signature;
typedef git_tag * Tag;
typedef git_tree * Tree;
typedef git_treebuilder * Tree_Builder;
typedef git_tree_entry * Tree_Entry;
typedef git_revwalk * Walker;

typedef struct {
	git_index_entry *ours;
	git_index_entry *ancestor;
	git_index_entry *theirs;
} git_raw_index_conflict;

typedef git_raw_index_conflict * Index_Conflict;

typedef struct {
	int code;
	int category;
	SV *message;
} git_raw_error;

typedef git_raw_error * Error;

typedef struct {
	git_filter filter;
	git_filter_callbacks callbacks;
	char *name;
	char *attributes;
} git_raw_filter;

typedef git_raw_filter * Filter;
typedef git_filter_source * Filter_Source;
typedef git_filter_list * Filter_List;

typedef struct {
	git_remote *remote;
	git_raw_remote_callbacks callbacks;
	int owned;
} git_raw_remote;

typedef git_raw_remote * Remote;

typedef struct {
	git_repository *repository;
	int owned;
} git_raw_repository;

typedef git_raw_repository * Repository;

typedef struct {
	git_cred *cred;
	SV *callback;
} git_raw_cred;

typedef git_raw_cred * Cred;

/* printf format specifier for size_t */
#if defined(_MSC_VER) || defined(__MINGW32__)
#  define PRIuZ "Iu"
#  define PRIxZ "Ix"
#else
# define PRIuZ "zu"
# define PRIxZ "zx"
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

STATIC Error create_error_obj(int code, int category, SV *message) {
	Error e;

	Newxz(e, 1, git_raw_error);
	e -> code = code;
	e -> category = category;

	if (message)
		e -> message = message;

	return e;
}

STATIC Error create_error_obj_fmt(int code, int category, const char *prefix, const char *pat, va_list *list) {
	Error e;

	e = create_error_obj(code, category, newSVpv(prefix, 0));
	sv_vcatpvf(e -> message, pat, list);

	return e;
}

STATIC void croak_error_obj(Error e) {
	SV *res = NULL;
	GIT_NEW_OBJ(res, "Git::Raw::Error", e);
	croak_sv(res);
}

STATIC void git_check_error(int err) {
	if (err != GIT_OK && err != GIT_ITEROVER) {
		const git_error *error;
		Error e;

		e = create_error_obj(err, NONE, NULL);

		if ((error = giterr_last()) != NULL) {
			e -> category = error -> klass;
			e -> message = newSVpv(error -> message, 0);
		} else if (SvTRUE(ERRSV)) {
			e -> message = newSVpv(SvPVbyte_nolen(ERRSV), 0);
		} else {
			e -> message = newSVpv("Unknown error!", 0);
		}

		croak_error_obj(e);
	}
}

STATIC void croak_assert(const char *pat, ...) {
	Error e;
	va_list list;

	va_start(list, pat);
	e = create_error_obj_fmt(ASSERT, INTERNAL, "Assertion failed. Please file a bug report: ", pat, &list);
	va_end(list);

	croak_error_obj(e);
}

STATIC void croak_usage(const char *pat, ...) {
	Error e;
	va_list list;

	va_start(list, pat);
	e = create_error_obj_fmt(USAGE, INTERNAL, "", pat, &list);
	va_end(list);

	croak_error_obj(e);
}

STATIC void croak_resolve(const char *pat, ...) {
	Error e;
	va_list list;

	va_start(list, pat);
	e = create_error_obj_fmt(RESOLVE, INTERNAL, "", pat, &list);
	va_end(list);

	croak_error_obj(e);
}

STATIC git_index_entry *git_index_entry_dup(const git_index_entry *entry,
	const char *new_path)
{
	git_index_entry *new_entry = NULL;

	if (entry) {
		Newxz(new_entry, 1, git_index_entry);
		StructCopy(entry, new_entry, git_index_entry);

		if (new_path)
			new_entry -> path = savepv(new_path);
		else
			new_entry -> path = savepv(entry -> path);
	}

	return new_entry;
}

STATIC void git_index_entry_free(git_index_entry *entry)
{
	if (entry) {
		Safefree(entry -> path);
		Safefree(entry);
	}
}

STATIC SV *git_index_entry_to_sv(const git_index_entry *index_entry, const char *path, SV *repo) {
	SV *ie = &PL_sv_undef;

	if (index_entry) {
		git_index_entry *entry = NULL;

		if ((entry = git_index_entry_dup(index_entry, path))) {
			GIT_NEW_OBJ_WITH_MAGIC(
				ie, "Git::Raw::Index::Entry",
				entry, repo
			);
		}
	}

	return ie;
}

STATIC SV *git_obj_to_sv(git_object *o, SV *repo) {
	SV *res = NULL;

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
			croak_usage("Invalid object type");
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

STATIC void *git_sv_to_ptr(const char *type, SV *sv, const char *file, int line) {
	SV *full_type = sv_2mortal(newSVpvf("Git::Raw::%s", type));

	if (sv_isobject(sv) && sv_derived_from(sv, SvPV_nolen(full_type)))
		return INT2PTR(void *, SvIV((SV *) SvRV(sv)));

	croak_usage("Argument is not of type %s @ (%s:%d)",
		SvPV_nolen(full_type), file, line);

	return NULL;
}

#define GIT_SV_TO_PTR(type, sv) \
	git_sv_to_ptr(#type, sv, __FILE__, __LINE__)

STATIC SV *git_oid_to_sv(const git_oid *oid) {
	char out[41];

	git_oid_fmt(out, oid);
	out[40] = '\0';

	return newSVpv(out, 0);
}

STATIC git_oid *git_sv_to_commitish(git_repository *repo, SV *sv, git_oid *oid) {
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

		/* substr() may return a SVt_PVLV, need to perform some force majeur */
		if (SvPOK(sv) || SvGAMAGIC(sv)) {
			commitish_name = SvPVbyte(sv, len);
		} else if (SvTYPE(sv) == SVt_PVLV) {
			commitish_name = SvPVbyte_force(sv, len);
		}

		if (commitish_name) {
			/* first try and see if its a commit id, or if its a reference */
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
	cbs -> certificate_check = NULL;
	cbs -> progress = NULL;
	cbs -> transfer_progress = NULL;
	cbs -> update_tips = NULL;
	cbs -> pack_progress = NULL;
	cbs -> push_transfer_progress = NULL;
	cbs -> push_update_reference = NULL;
}

STATIC void git_clean_remote_callbacks(git_raw_remote_callbacks *cbs) {
	if (cbs -> credentials) {
		SvREFCNT_dec(cbs -> credentials);
		cbs -> credentials = NULL;
	}

	if (cbs -> certificate_check) {
		SvREFCNT_dec(cbs -> certificate_check);
		cbs -> certificate_check = NULL;
	}

	if (cbs -> progress) {
		SvREFCNT_dec(cbs -> progress);
		cbs -> progress = NULL;
	}

	if (cbs -> transfer_progress) {
		SvREFCNT_dec(cbs -> transfer_progress);
		cbs -> transfer_progress = NULL;
	}

	if (cbs -> update_tips) {
		SvREFCNT_dec(cbs -> update_tips);
		cbs -> update_tips = NULL;
	}

	if (cbs -> pack_progress) {
		SvREFCNT_dec(cbs -> pack_progress);
		cbs -> pack_progress = NULL;
	}

	if (cbs -> push_transfer_progress) {
		SvREFCNT_dec(cbs -> push_transfer_progress);
		cbs -> push_transfer_progress = NULL;
	}

	if (cbs -> push_update_reference) {
		SvREFCNT_dec(cbs -> push_update_reference);
		cbs -> push_update_reference = NULL;
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
			croak_usage("Expected an integer for '%s'", name);

		return *opt;
	}

	return NULL;
}

STATIC SV *git_hv_string_entry(HV *hv, const char *name) {
	SV **opt;

	if ((opt = hv_fetch(hv, name, strlen(name), 0))) {
		if (!SvPOK(*opt))
			croak_usage("Expected a string for '%s'", name);

		return *opt;
	}

	return NULL;
}

STATIC AV *git_ensure_av(SV *sv, const char *identifier) {
	if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV)
		croak_usage("Invalid type for '%s', expected a list", identifier);

	return (AV *) SvRV(sv);
}

STATIC HV *git_ensure_hv(SV *sv, const char *identifier) {
	if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV)
		croak_usage("Invalid type for '%s', expected a hash", identifier);

	return (HV *) SvRV(sv);
}

STATIC SV *git_ensure_cv(SV *sv, const char *identifier) {
	if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVCV)
		croak_usage("Invalid type for '%s', expected a code reference", identifier);

	return sv;
}

STATIC I32 git_ensure_iv(SV *sv, const char *identifier) {
	if (!SvIOK(sv))
		croak_usage("Invalid type for '%s', expected an integer", identifier);

	return SvIV(sv);
}

STATIC const char *git_ensure_pv_with_len(SV *sv, const char *identifier, STRLEN *len) {
	const char *pv = NULL;
	STRLEN real_len;

	if (SvPOK(sv) || SvGAMAGIC(sv)) {
		pv = SvPVbyte(sv, real_len);
	} else if (SvTYPE(sv) == SVt_PVLV) {
		pv = SvPVbyte_force(sv, real_len);
	}

	if (pv == NULL)
		croak_usage("Invalid type for '%s', expected a string", identifier);

	if (len)
		*len = real_len;

	return pv;
}

STATIC const char *git_ensure_pv(SV *sv, const char *identifier) {
	return git_ensure_pv_with_len(sv, identifier, NULL);
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

	git_flag_opt(flags, "show_binary", GIT_DIFF_SHOW_BINARY, &out);

	git_flag_opt(flags, "force_text", GIT_DIFF_FORCE_TEXT, &out);

	git_flag_opt(flags, "force_binary", GIT_DIFF_FORCE_BINARY, &out);

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

STATIC unsigned git_hv_to_status_flag(HV *flags) {
	unsigned out = 0;

	git_flag_opt(flags, "include_untracked", GIT_STATUS_OPT_INCLUDE_UNTRACKED, &out);
	git_flag_opt(flags, "include_ignored", GIT_STATUS_OPT_INCLUDE_IGNORED, &out);
	git_flag_opt(flags, "include_unmodified", GIT_STATUS_OPT_INCLUDE_UNMODIFIED, &out);
	git_flag_opt(flags, "exclude_submodules", GIT_STATUS_OPT_EXCLUDE_SUBMODULES, &out);
	git_flag_opt(flags, "recurse_untracked_dirs", GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS, &out);
	git_flag_opt(flags, "disable_pathspec_match", GIT_STATUS_OPT_DISABLE_PATHSPEC_MATCH, &out);
	git_flag_opt(flags, "recurse_ignored_dirs", GIT_STATUS_OPT_RECURSE_IGNORED_DIRS, &out);
	git_flag_opt(flags, "renames_head_to_index", GIT_STATUS_OPT_RENAMES_HEAD_TO_INDEX, &out);
	git_flag_opt(flags, "renames_index_to_workdir", GIT_STATUS_OPT_RENAMES_INDEX_TO_WORKDIR, &out);
	git_flag_opt(flags, "sort_case_sensitively", GIT_STATUS_OPT_SORT_CASE_SENSITIVELY, &out);
	git_flag_opt(flags, "sort_case_insensitively", GIT_STATUS_OPT_SORT_CASE_INSENSITIVELY, &out);
	git_flag_opt(flags, "renames_from_rewrites", GIT_STATUS_OPT_RENAMES_FROM_REWRITES, &out);
	git_flag_opt(flags, "no_refresh", GIT_STATUS_OPT_NO_REFRESH, &out);
	git_flag_opt(flags, "update_index", GIT_STATUS_OPT_UPDATE_INDEX, &out);
	git_flag_opt(flags, "include_unreadable", GIT_STATUS_OPT_INCLUDE_UNREADABLE, &out);
	git_flag_opt(flags, "include_unreadable_as_untracked", GIT_STATUS_OPT_INCLUDE_UNREADABLE_AS_UNTRACKED, &out);

	return out;
}

STATIC unsigned git_hv_to_checkout_strategy(HV *strategy) {
	unsigned out = 0;

	git_flag_opt(strategy, "none", GIT_CHECKOUT_NONE, &out);

	git_flag_opt(strategy, "force", GIT_CHECKOUT_FORCE, &out);

	git_flag_opt(strategy, "safe", GIT_CHECKOUT_SAFE, &out);

	git_flag_opt(
		strategy,
		"recreate_missing",
		GIT_CHECKOUT_RECREATE_MISSING, &out
	);

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
		strategy, "disable_pathspec_match",
		GIT_CHECKOUT_DISABLE_PATHSPEC_MATCH, &out);

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
		strategy, "dont_remove_existing",
		GIT_CHECKOUT_DONT_REMOVE_EXISTING, &out);

	git_flag_opt(
		strategy, "dont_write_index",
		GIT_CHECKOUT_DONT_WRITE_INDEX, &out);

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

		case GIT_DIFF_LINE_CONTEXT_EOFNL:
			XPUSHs(sv_2mortal(newSVpv("noeol", 0)));
			break;

		case GIT_DIFF_LINE_BINARY:
			XPUSHs(sv_2mortal(newSVpv("bin", 0)));
			break;

		default:
			croak_assert("Unexpected diff origin: %d", line -> origin);
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
	int annotated;
	int lightweight;
} git_foreach_payload;

STATIC int git_config_foreach_cbb(const git_config_entry *entry, void *payload) {
	dSP;
	int rv = 0;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(newSVpv(entry -> name, 0));
	mXPUSHs(newSVpv(entry -> value, 0));
	mXPUSHs(newSVuv(entry -> level));
	PUTBACK;

	call_sv(((git_foreach_payload *) payload) -> cb, G_SCALAR);

	SPAGAIN;

	rv = POPi;

	FREETMPS;
	LEAVE;

	if (rv != 0)
		rv = GIT_EUSER;

	return rv;
}

STATIC int git_stash_foreach_cb(size_t i, const char *msg, const git_oid *oid, void *p) {
	dSP;
	int rc, rv = 0;
	Commit c = NULL;
	SV *commit = NULL;
	git_foreach_payload *payload = (git_foreach_payload *) p;

	rc = git_commit_lookup(&c,
		payload -> repo_ptr -> repository, oid
	);
	git_check_error(rc);

	GIT_NEW_OBJ_WITH_MAGIC(
		commit, "Git::Raw::Commit", c, SvRV(payload -> repo)
	);

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(newSVuv(i));
	mXPUSHs(newSVpv(msg, 0));
	mXPUSHs(commit);
	PUTBACK;

	call_sv(payload -> cb, G_EVAL|G_SCALAR);

	SPAGAIN;

	if (SvTRUE(ERRSV)) {
		rv = -1;
		(void) POPs;
	} else {
		rv = POPi;
		if (rv != 0)
			rv = GIT_EUSER;
	}

	FREETMPS;
	LEAVE;

	return rv;
}

STATIC int git_tag_foreach_cbb(const char *name, git_oid *oid, void *payload) {
	dSP;
	int rv = 0;
	git_otype type = GIT_OBJ_ANY;
	git_object *tag;

	SV *cb_arg = NULL;
	git_foreach_payload *pl = payload;

	int rc = git_object_lookup(
		&tag, pl -> repo_ptr -> repository, oid, type
	);
	git_check_error(rc);

	type = git_object_type(tag);

	if (type == GIT_OBJ_TAG) {
		if (pl -> annotated) {
			GIT_NEW_OBJ_WITH_MAGIC(
				cb_arg, "Git::Raw::Tag", (void *) tag, SvRV(pl -> repo)
			);
		} else
			return 0;
	} else if (type == GIT_OBJ_COMMIT) {
		git_object_free(tag);

		if (pl -> lightweight) {
			Reference ref = NULL;
			rc = git_reference_lookup(&ref,
				pl -> repo_ptr -> repository, name
			);
			git_check_error(rc);

			GIT_NEW_OBJ_WITH_MAGIC(
				cb_arg, "Git::Raw::Reference", (void *) ref, SvRV(pl -> repo)
			);
		} else
			return 0;
	} else
		croak_assert("Unexpected tag, object type of %s", git_object_type2string(type));

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(cb_arg);
	PUTBACK;

	call_sv(pl -> cb, G_SCALAR);

	SPAGAIN;

	rv = POPi;

	FREETMPS;
	LEAVE;

	if (rv != 0)
		rv = GIT_EUSER;

	return rv;
}

STATIC int git_checkout_notify_cbb(git_checkout_notify_t why, const char *path, const git_diff_file *baseline,
	const git_diff_file *target, const git_diff_file *workdir, void *payload) {
	dSP;

	int rv = 0;
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
	mXPUSHs(newSVpv(path, 0));
	mXPUSHs(newRV_noinc((SV *) w));
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
	mXPUSHs(path ? newSVpv(path, 0) : &PL_sv_undef);
	mXPUSHs(newSViv(completed_steps));
	mXPUSHs(newSViv(total_steps));
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
	mXPUSHs(newSVpv(str, len));
	PUTBACK;

	call_sv(((git_raw_remote_callbacks *) cbs) -> progress, G_DISCARD);

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
	mXPUSHs(newSViv(stats -> total_objects));
	mXPUSHs(newSViv(stats -> received_objects));
	mXPUSHs(newSViv(stats -> local_objects));
	mXPUSHs(newSViv(stats -> total_deltas));
	mXPUSHs(newSViv(stats -> indexed_deltas));
	mXPUSHs(newSVuv(stats -> received_bytes));
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
	mXPUSHs(newSVuv(current));
	mXPUSHs(newSVuv(total));
	mXPUSHs(newSVuv(bytes));
	PUTBACK;

	call_sv(((git_raw_remote_callbacks *) cbs) -> push_transfer_progress, G_DISCARD);

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
	mXPUSHs(newSViv(stage));
	mXPUSHs(newSVuv(current));
	mXPUSHs(newSVuv(total));
	PUTBACK;

	call_sv(((git_raw_remote_callbacks *) cbs) -> pack_progress, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;

	return 0;
}

STATIC int git_push_update_reference_cbb(const char *ref, const char *msg, void *p) {
	dSP;
	int rv = 0;
	git_raw_remote_callbacks *callbacks = (git_raw_remote_callbacks *) p;
	SV *cb = callbacks -> push_update_reference;

	if (msg != NULL) {
		rv = GIT_EUSER;
		callbacks -> push_success = 0;
	}

	if (!cb)
		return 0;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(newSVpv(ref, 0));
	mXPUSHs(newSVpv(msg, 0));
	PUTBACK;

	call_sv(cb, G_VOID);

	SPAGAIN;

	FREETMPS;
	LEAVE;

	return rv;
}

STATIC int git_update_tips_cbb(const char *name, const git_oid *a,
	const git_oid *b, void *cbs) {
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(newSVpv(name, 0));
	XPUSHs((a != NULL && !git_oid_iszero(a)) ? sv_2mortal(git_oid_to_sv(a)) : &PL_sv_undef);
	XPUSHs((b != NULL && !git_oid_iszero(b)) ? sv_2mortal(git_oid_to_sv(b)) : &PL_sv_undef);
	PUTBACK;

	call_sv(((git_raw_remote_callbacks *) cbs) -> update_tips, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;

	return 0;
}

STATIC int git_remote_create_cbb(git_remote **out, git_repository *r,
	const char *name, const char *url, void *cb) {
	dSP;
	int rv = 0;
	SV *repo_sv = NULL;
	Repository repo = NULL;

	Newxz(repo, 1, git_raw_repository);
	repo -> repository = r;
	repo -> owned = 0;

	GIT_NEW_OBJ(repo_sv,
		"Git::Raw::Repository",
		(void * ) repo
	);

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(repo_sv);
	mXPUSHs(newSVpv(name, 0));
	mXPUSHs(newSVpv(url, 0));
	PUTBACK;

	call_sv((SV *) cb, G_EVAL|G_SCALAR);

	SPAGAIN;

	if (SvTRUE(ERRSV)) {
		rv = -1;
		(void) POPs;

		*out = NULL;
	} else {
		SV *r = POPs;
		if (SvOK(r)) {
			Remote remote = GIT_SV_TO_PTR(Remote, r);
			*out = remote -> remote;

			/* The remote created in the callback is owned by libgit2 */
			remote -> owned = 0;
		} else {
			*out = NULL;
			rv = -1;
		}
	}

	FREETMPS;
	LEAVE;

	return rv;
}

STATIC int git_credentials_cbb(git_cred **cred, const char *url,
		const char *usr_from_url, unsigned int allow, void *cbs) {
	dSP;
	int rv = 0;
	AV *types = newAV();
	Cred creds;

	if (allow & GIT_CREDTYPE_USERPASS_PLAINTEXT)
		av_push(types, newSVpv("userpass_plaintext", 0));
	if (allow & GIT_CREDTYPE_SSH_KEY)
		av_push(types, newSVpv("ssh_key", 0));
	if (allow & GIT_CREDTYPE_SSH_CUSTOM)
		av_push(types, newSVpv("ssh_custom", 0));
	if (allow & GIT_CREDTYPE_DEFAULT)
		av_push(types, newSVpv("default", 0));
	if (allow & GIT_CREDTYPE_SSH_INTERACTIVE)
		av_push(types, newSVpv("ssh_interactive", 0));
	if (allow & GIT_CREDTYPE_USERNAME)
		av_push(types, newSVpv("username", 0));

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(newSVpv(url, 0));
	mXPUSHs(newSVpv(usr_from_url, 0));
	mXPUSHs(newRV_noinc((SV *)types));
	PUTBACK;

	call_sv(((git_raw_remote_callbacks *) cbs) -> credentials, G_EVAL|G_SCALAR);

	SPAGAIN;

	if (SvTRUE(ERRSV)) {
		rv = GIT_PASSTHROUGH;
		(void) POPs;
	} else {
		SV *c = POPs;
		if (SvOK(c)) {
			creds = GIT_SV_TO_PTR(Cred, c);
			*cred = creds -> cred;
		} else
			rv = GIT_PASSTHROUGH;
	}

	FREETMPS;
	LEAVE;

	return rv;
}

STATIC int git_certificate_check_cbb(git_cert *cert, int valid, const char *host, void *cbs) {
	dSP;
	int rv = 0;
	SV *obj = NULL;

	if (cert -> cert_type == GIT_CERT_X509) {
		git_cert_x509 *x509 = (git_cert_x509 *) cert;

		GIT_NEW_OBJ(
			obj, "Git::Raw::Cert::X509", (void *) x509
		);
	} else if (cert -> cert_type == GIT_CERT_HOSTKEY_LIBSSH2) {
		git_cert_hostkey *ssh = (git_cert_hostkey *) cert;

		GIT_NEW_OBJ(
			obj, "Git::Raw::Cert::HostKey", (void *) ssh
		);
	}

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(obj);
	mXPUSHs(newSViv(valid));
	mXPUSHs(newSVpv(host, 0));
	PUTBACK;

	call_sv(((git_raw_remote_callbacks *) cbs) -> certificate_check, G_EVAL|G_SCALAR);

	SPAGAIN;

	if (SvTRUE(ERRSV)) {
		rv = -1;
		(void) POPs;
	} else
		rv = POPi;

	FREETMPS;
	LEAVE;

	return rv;
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
	mXPUSHs(newSVpv(name, name_len));
	mXPUSHs(newSVpv(instruction, instruction_len));
	for (i = 0; i < num_prompts; ++i) {
		HV *prompt = newHV();
		hv_stores(prompt, "text", newSVpvn(prompts[i].text, prompts[i].length));
		hv_stores(prompt, "echo", newSViv(prompts[i].echo));
		mXPUSHs(newRV_noinc((SV*)prompt));
	}
	PUTBACK;

	count = call_sv(cb, G_ARRAY);

	SPAGAIN;

	if (count != num_prompts)
		croak_usage("Expected %d response(s) got %d", num_prompts, count);

	for (i = 1; i <= count; ++i) {
		STRLEN len;
		SV *r = POPs;
		const char *response = SvPV(r, len);
		int index = num_prompts - i;

		Newxz(responses[index].text, len, char);
		Copy(response, responses[index].text, len, char);
		responses[index].length = len;
	}

	FREETMPS;
	LEAVE;
}

STATIC int git_filter_init_cbb(git_filter *filter) {
	dSP;

	int rv = 0;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUTBACK;

	call_sv(((git_raw_filter *) filter) -> callbacks.initialize, G_EVAL|G_SCALAR);

	SPAGAIN;

	if (SvTRUE(ERRSV)) {
		rv = GIT_EUSER;
		(void) POPs;
	} else {
		rv = POPi;
	}

	FREETMPS;
	LEAVE;

	return rv;
}

STATIC void git_filter_shutdown_cbb(git_filter *filter) {
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
	const git_filter_source *src, const char **attr_values) {
	dSP;

	int rv = 0;
	SV *filter_source = NULL;

	GIT_NEW_OBJ(
		filter_source, "Git::Raw::Filter::Source", (void *) src
	);

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(filter_source);
	PUTBACK;

	call_sv(((git_raw_filter *) filter) -> callbacks.check, G_EVAL|G_SCALAR);

	SPAGAIN;

	if (SvTRUE(ERRSV)) {
		rv = GIT_EUSER;
		(void) POPs;
	} else {
		rv = POPi;
	}

	FREETMPS;
	LEAVE;

	return rv;
}

STATIC int git_filter_apply_cbb(git_filter *filter, void **payload,
	git_buf *to, const git_buf *from, const git_filter_source *src) {
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
	mXPUSHs(filter_source);
	mXPUSHs(newSVpv(from -> ptr, from -> size));
	mXPUSHs(newRV_noinc(result));
	PUTBACK;

	call_sv(((git_raw_filter *) filter) -> callbacks.apply, G_EVAL|G_SCALAR);

	SPAGAIN;

	if (SvTRUE(ERRSV)) {
		rv = GIT_EUSER;
		(void) POPs;
	} else {
		rv = POPi;
	}

	if (rv == GIT_OK) {
		STRLEN len;
		const char *ptr = SvPV(result, len);

		git_buf_set(to, ptr, len);
	}

	FREETMPS;
	LEAVE;

	return rv;
}

STATIC void git_filter_cleanup_cbb(git_filter *filter, void *payload) {
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

STATIC int git_index_matched_path_cbb(const char *path, const char *pathspec, void *payload) {
	dSP;

	int rv = 0;
	SV *callback = (SV *) payload;

	if (callback == NULL)
		return rv;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHs(newSVpv(path, 0));
	mXPUSHs(pathspec ? newSVpv(pathspec, 0) : &PL_sv_undef);
	PUTBACK;

	call_sv(callback, G_SCALAR|G_EVAL);

	SPAGAIN;

	if (SvTRUE(ERRSV)) {
		rv = -1;
		(void) POPs;
	} else
		rv = POPi;

	FREETMPS;
	LEAVE;

	return rv;
}

STATIC void git_list_to_paths(AV *list, git_strarray *paths) {
	size_t i = 0, count = 0;
	SV **path;

	while ((path = av_fetch(list, i++, 0))) {
		if (!path || !SvOK(*path))
			continue;

		Renew(paths->strings, count + 1, char *);
		paths->strings[count++] = SvPVbyte_nolen(*path);
	}

	paths->count = count;
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
		size_t i = 0, count = 0;

		while ((path = av_fetch(lopt, i++, 0))) {
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
						croak_usage("Invalid type for 'notify' value");
				}
			}
		}
	}
}

STATIC void git_hv_to_diff_opts(HV *opts, git_diff_options *diff_options, git_tree **tree) {
	SV *opt;
	HV *hopt;
	AV *lopt;

	if (tree) {
		*tree = NULL;

		if ((opt = git_hv_sv_entry(opts, "tree")) && SvOK(opt))
			*tree = GIT_SV_TO_PTR(Tree, opt);
	}

	if ((hopt = git_hv_hash_entry(opts, "flags")))
		diff_options->flags |= git_hv_to_diff_flag(hopt);

	if ((hopt = git_hv_hash_entry(opts, "prefix"))) {
		SV *ab;

		if ((ab = git_hv_string_entry(hopt, "a")))
			diff_options->old_prefix = SvPVbyte_nolen(ab);

		if ((ab = git_hv_string_entry(hopt, "b")))
			diff_options->new_prefix = SvPVbyte_nolen(ab);
	}

	if ((opt = git_hv_int_entry(opts, "context_lines")))
		diff_options->context_lines = (uint16_t) SvIV(opt);

	if ((opt = git_hv_int_entry(opts, "interhunk_lines")))
		diff_options->interhunk_lines = (uint16_t) SvIV(opt);

	if ((lopt = git_hv_list_entry(opts, "paths"))) {
		SV **path;
		char **paths = NULL;
		size_t i = 0, count = 0;

		while ((path = av_fetch(lopt, i++, 0))) {
			if (!SvOK(*path))
				continue;

			Renew(paths, count + 1, char *);
			paths[count++] = SvPVbyte_nolen(*path);
		}

		if (count > 0) {
			diff_options->flags |= GIT_DIFF_DISABLE_PATHSPEC_MATCH;
			diff_options->pathspec.strings = paths;
			diff_options->pathspec.count   = count;
		}
	}
}

STATIC unsigned git_hv_to_merge_tree_flag(HV *flags) {
	unsigned out = 0;

	git_flag_opt(flags, "find_renames", GIT_MERGE_TREE_FIND_RENAMES, &out);

	return out;
}

STATIC unsigned git_hv_to_merge_file_flag(HV *flags) {
	unsigned out = 0;

	git_flag_opt(flags, "merge", GIT_MERGE_FILE_STYLE_MERGE, &out);
	git_flag_opt(flags, "diff3", GIT_MERGE_FILE_STYLE_DIFF3, &out);
	git_flag_opt(flags, "simplify_alnum", GIT_MERGE_FILE_SIMPLIFY_ALNUM, &out);

	git_flag_opt(flags, "ignore_whitespace", GIT_MERGE_FILE_IGNORE_WHITESPACE, &out);
	git_flag_opt(flags, "ignore_whitespace_change", GIT_MERGE_FILE_IGNORE_WHITESPACE_CHANGE, &out);
	git_flag_opt(flags, "ignore_whitespace_eol", GIT_MERGE_FILE_IGNORE_WHITESPACE_EOL, &out);

	git_flag_opt(flags, "patience", GIT_MERGE_FILE_DIFF_PATIENCE, &out);
	git_flag_opt(flags, "minimal", GIT_MERGE_FILE_DIFF_MINIMAL, &out);

	return out;
}

STATIC void git_hv_to_merge_opts(HV *opts, git_merge_options *merge_options) {
	HV *hopt;
	SV *opt;

	if ((hopt = git_hv_hash_entry(opts, "tree_flags")))
		merge_options -> tree_flags |= git_hv_to_merge_tree_flag(hopt);

	if ((hopt = git_hv_hash_entry(opts, "file_flags")))
		merge_options -> file_flags |= git_hv_to_merge_file_flag(hopt);

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
			croak_usage("Invalid 'favor' value");
	}

	if ((opt = git_hv_int_entry(opts, "rename_threshold")))
		merge_options -> rename_threshold = SvIV(opt);

	if ((opt = git_hv_int_entry(opts, "target_limit")))
		merge_options -> target_limit = SvIV(opt);
}

STATIC void git_hv_to_merge_file_opts(HV *opts, git_merge_file_options *merge_options) {
	AV *lopt;
	HV *hopt;
	SV *opt;

	if ((hopt = git_hv_hash_entry(opts, "flags")))
		merge_options -> flags |= git_hv_to_merge_file_flag(hopt);

	if ((opt = git_hv_string_entry(opts, "favor"))) {
		const char *favor = SvPVbyte_nolen(opt);
		if (strcmp(favor, "ours") == 0)
			merge_options -> favor =
				GIT_MERGE_FILE_FAVOR_OURS;
		else if (strcmp(favor, "theirs") == 0)
			merge_options -> favor =
				GIT_MERGE_FILE_FAVOR_THEIRS;
		else if (strcmp(favor, "union") == 0)
			merge_options -> favor =
				GIT_MERGE_FILE_FAVOR_UNION;
		else
			croak_usage("Invalid 'favor' value");
	}

	if ((opt = git_hv_string_entry(opts, "ancestor_label")))
		merge_options -> ancestor_label = SvPVbyte_nolen(opt);

	if ((opt = git_hv_string_entry(opts, "our_label")))
		merge_options -> our_label = SvPVbyte_nolen(opt);

	if ((opt = git_hv_string_entry(opts, "their_label")))
		merge_options -> their_label = SvPVbyte_nolen(opt);
}

MODULE = Git::Raw			PACKAGE = Git::Raw

BOOT:
	git_libgit2_init();

SV *
message_prettify(class, msg, ...)
	SV *class
	SV *msg

	PROTOTYPE: $;$$
	PREINIT:
		int rc, strip_comments = 1;
		char comment_char = '#';

		git_buf buf = GIT_BUF_INIT_CONST(NULL, 0);
		const char *message;

	CODE:
		message = git_ensure_pv(msg, "msg");

		if (items >= 3)
			strip_comments = (int) git_ensure_iv(ST(2), "strip_comments");
		if (items >= 4) {
			STRLEN len;
			const char *comment = git_ensure_pv_with_len(ST(3), "comment_char", &len);

			if (len != 1)
				croak_usage("Expected a single character for 'comment_char'");

			comment_char = comment[0];
		}

		rc = git_message_prettify(
			&buf, message, strip_comments, comment_char
		);

		RETVAL = &PL_sv_undef;
		if (rc == GIT_OK) {
			RETVAL = newSVpv(buf.ptr, buf.size);
			git_buf_free(&buf);
		}

		git_check_error(rc);

	OUTPUT: RETVAL

void
features(class)
	SV *class

	PREINIT:
		int ctx = GIMME_V;

	PPCODE:
		if (ctx != G_VOID) {
			if (ctx == G_ARRAY) {
				int features = git_libgit2_features();

				mXPUSHs(newSVpv("threads", 0));
				mXPUSHs(newSViv((features & GIT_FEATURE_THREADS) ? 1 : 0));
				mXPUSHs(newSVpv("https", 0));
				mXPUSHs(newSViv((features & GIT_FEATURE_HTTPS) ? 1 : 0));
				mXPUSHs(newSVpv("ssh", 0));
				mXPUSHs(newSViv((features & GIT_FEATURE_SSH) ? 1 : 0));

				XSRETURN(6);
			} else {
				mXPUSHs(newSViv(3));
				XSRETURN(1);
			}
		} else
			XSRETURN_EMPTY;

INCLUDE: xs/Blame.xs
INCLUDE: xs/Blame/Hunk.xs
INCLUDE: xs/Blob.xs
INCLUDE: xs/Branch.xs
INCLUDE: xs/Cert.xs
INCLUDE: xs/Cert/HostKey.xs
INCLUDE: xs/Cert/X509.xs
INCLUDE: xs/Commit.xs
INCLUDE: xs/Config.xs
INCLUDE: xs/Cred.xs
INCLUDE: xs/Diff.xs
INCLUDE: xs/Diff/Delta.xs
INCLUDE: xs/Diff/File.xs
INCLUDE: xs/Diff/Hunk.xs
INCLUDE: xs/Diff/Stats.xs
INCLUDE: xs/Error.xs
INCLUDE: xs/Error/Category.xs
INCLUDE: xs/Filter.xs
INCLUDE: xs/Filter/List.xs
INCLUDE: xs/Filter/Source.xs
INCLUDE: xs/Graph.xs
INCLUDE: xs/Index.xs
INCLUDE: xs/Index/Conflict.xs
INCLUDE: xs/Index/Entry.xs
INCLUDE: xs/Merge/File/Result.xs
INCLUDE: xs/Note.xs
INCLUDE: xs/Patch.xs
INCLUDE: xs/PathSpec.xs
INCLUDE: xs/PathSpec/MatchList.xs
INCLUDE: xs/Reference.xs
INCLUDE: xs/Reflog.xs
INCLUDE: xs/Reflog/Entry.xs
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
