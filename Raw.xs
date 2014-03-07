#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pv_flags
#define NEED_sv_2pvbyte_GLOBAL
#define NEED_newRV_noinc_GLOBAL

#include "ppport.h"

#include <inttypes.h>

#include <git2.h>
#include <git2/sys/repository.h>

typedef git_blob * Blob;
typedef git_reference * Branch;
typedef git_commit * Commit;
typedef git_config * Config;
typedef git_cred * Cred;
typedef git_diff * Diff;
typedef git_diff_delta * Diff_Delta;
typedef git_diff_file * Diff_File;
typedef git_diff_hunk * Diff_Hunk;
typedef git_index * Index;
typedef git_index_entry * Index_Entry;
typedef git_patch * Patch;
typedef git_push * Push;
typedef git_reference * Reference;
typedef git_reflog * Reflog;
typedef git_refspec * RefSpec;
typedef git_remote * Remote;
typedef git_repository * Repository;
typedef git_signature * Signature;
typedef git_tag * Tag;
typedef git_tree * Tree;
typedef git_treebuilder * Tree_Builder;
typedef git_tree_entry * Tree_Entry;
typedef git_revwalk * Walker;

typedef struct xs_git_remote_callbacks {
	SV *progress;
	SV *completion;
	SV *credentials;
	SV *transfer_progress;
	SV *update_tips;
} xs_git_remote_callbacks;

void xs_object_magic_attach_struct(pTHX_ SV *sv, void *ptr);
void *xs_object_magic_get_struct(pTHX_ SV *sv);

void git_check_error(int err) {
	const git_error *error;

	if (err == GIT_OK)
		return;

	error = giterr_last();

	Perl_croak(aTHX_ "%s", error -> message);
}

SV *git_obj_to_sv(git_object *o, SV *repo_src) {
	SV *res;
	SV *repo;

	switch (git_object_type(o)) {
		case GIT_OBJ_BLOB:
			res = sv_setref_pv(newSV(0), "Git::Raw::Blob", o);
			break;

		case GIT_OBJ_COMMIT:
			res = sv_setref_pv(newSV(0), "Git::Raw::Commit", o);
			break;

		case GIT_OBJ_TAG:
			res = sv_setref_pv(newSV(0), "Git::Raw::Tag", o);
			break;

		case GIT_OBJ_TREE:
			res = sv_setref_pv(newSV(0), "Git::Raw::Tree", o);
			break;

		default:
			Perl_croak(aTHX_ "Invalid object type");
			break;
	}

	if (sv_isobject(repo_src) &&
	    sv_derived_from(repo_src, "Git::Raw::Repository"))
		repo = SvRV(repo_src);
	else if (sv_isobject(repo_src))
		repo = xs_object_magic_get_struct(aTHX_ SvRV(repo_src));
	else
		Perl_croak(aTHX_ "Invalid repository source");

	if (!repo)
		Perl_croak(aTHX_ "Invalid repository source");

	xs_object_magic_attach_struct(aTHX_ SvRV(res), SvREFCNT_inc_NN(repo));

	return res;
}

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
}

#define GIT_SV_TO_PTR(type, sv) \
	git_sv_to_ptr(#type, sv)

SV *git_oid_to_sv(const git_oid *oid) {
	char out[41];

	git_oid_fmt(out, oid);
	out[40] = '\0';

	return newSVpv(out, 0);
}

SV *get_callback_option(HV *callbacks, const char *name) {
	SV **opt;

	if ((opt = hv_fetch(callbacks, name, strlen(name), 0))) {
		SV *cb = *opt;

		if (SvTYPE(SvRV(cb)) != SVt_PVCV)
			Perl_croak(aTHX_ "Expected a subroutine for '%s' callback", name);

		SvREFCNT_inc(cb);

		return cb;
	}

	return NULL;
}

void cleanup_xs_git_remote_callbacks (xs_git_remote_callbacks *cbs) {
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

void git_flag_opt(HV *value, const char *name, int mask, unsigned *out) {
	SV **opt;

	if ((opt = hv_fetch(value, name, strlen(name), 0)) && SvIV(*opt))
		*out |= mask;
}

unsigned git_hv_to_diff_flag(HV *flags) {
	unsigned out = 0;

	git_flag_opt(flags, "reverse", GIT_DIFF_REVERSE, &out);

	git_flag_opt(flags, "include_ignored", GIT_DIFF_INCLUDE_IGNORED, &out);

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

	git_flag_opt(flags, "patience", GIT_DIFF_PATIENCE, &out);

	git_flag_opt(flags, "minimal", GIT_DIFF_MINIMAL, &out);

	return out;
}

unsigned git_hv_to_checkout_strategy(HV *strategy) {
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

	return out;
}

int git_diff_cb(const git_diff_delta *delta, const git_diff_hunk *hunk,
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
	SV *repo, *cb_arg;
	git_foreach_payload *pl = payload;

	int rc = git_tag_lookup(&tag, pl -> repo_ptr, oid);
	git_check_error(rc);

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

int git_checkout_notify_cbb(git_checkout_notify_t why, const char *path, const git_diff_file *baseline,
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

void git_checkout_progress_cbb(const char *path, size_t completed_steps, size_t total_steps,
	void *payload) {
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

int git_progress_cbb(const char *str, int len, void *cbs) {
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUSHs(newSVpv(str, len));
	PUTBACK;

	call_sv(((xs_git_remote_callbacks *) cbs) -> progress, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;

	return 0;
}

int git_completion_cbb(git_remote_completion_type type, void *cbs) {
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

	call_sv(((xs_git_remote_callbacks *) cbs) -> completion, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;

	return 0;
}

int git_transfer_progress_cbb(const git_transfer_progress *stats, void *cbs) {
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

	call_sv(((xs_git_remote_callbacks *) cbs) -> transfer_progress, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;

	return 0;
}

int git_update_tips_cbb(const char *name, const git_oid *a,
	const git_oid *b, void *cbs) {
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUSHs(newSVpv(name, 0));
	PUSHs(a != NULL ? git_oid_to_sv(a) : &PL_sv_undef);
	PUSHs(b != NULL ? git_oid_to_sv(b) : &PL_sv_undef);
	PUTBACK;

	call_sv(((xs_git_remote_callbacks *) cbs) -> update_tips, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;

	return 0;
}

int git_credentials_cbb(git_cred **cred, const char *url,
		const char *usr_from_url, unsigned int allow, void *cbs) {
	dSP;
	SV *creds;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	PUSHs(newSVpv(url, 0));
	PUTBACK;

	call_sv(((xs_git_remote_callbacks *) cbs) -> credentials, G_SCALAR);

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

void *xs_object_magic_get_struct(pTHX_ SV *sv) {
	MAGIC *mg = NULL;

	if (SvTYPE(sv) >= SVt_PVMG) {
		MAGIC *tmp;

		for (tmp = SvMAGIC(sv); tmp; tmp = tmp -> mg_moremagic) {
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

void git_hv_to_checkout_opts(HV *opts, git_checkout_opts *checkout_opts) {
	char **paths = NULL;
	SV **opt;

	if ((opt = hv_fetchs(opts, "checkout_strategy", 0)))
		checkout_opts -> checkout_strategy =
			git_hv_to_checkout_strategy(
				(HV *) SvRV(*opt)
			);

	if ((opt = hv_fetchs(opts, "paths", 0))) {
		SV **path;
		size_t count = 0;

		if (!SvROK(*opt) || SvTYPE(SvRV(*opt)) != SVt_PVAV)
			Perl_croak(aTHX_ "Invalid type");

		while ((path = av_fetch((AV *) SvRV(*opt), count, 0))) {
			if (SvOK(*path)) {
				Renew(paths, count+1, char *);
				paths[count++] = SvPVbyte_nolen(*path);
			}
		}

		if (count > 0) {
			checkout_opts -> paths.strings = paths;
			checkout_opts -> paths.count   = count;
		}
	}

	if ((opt = hv_fetchs(opts, "callbacks", 0))) {
		SV **cb;
		HV *callbacks;

		if (!SvROK(*opt) || SvTYPE(SvRV(*opt)) != SVt_PVHV)
			Perl_croak(aTHX_ "Invalid type");

		callbacks = (HV *) SvRV(*opt);

		if ((checkout_opts -> progress_payload =
				get_callback_option(callbacks, "progress")))
			checkout_opts -> progress_cb = git_checkout_progress_cbb;

		if ((checkout_opts -> notify_payload =
				get_callback_option(callbacks, "notify"))) {
			checkout_opts -> notify_cb      = git_checkout_notify_cbb;

			if ((opt = hv_fetchs(opts, "notify", 0))) {
				size_t count = 0;
				SV **flag;

				if (!SvROK(*opt) || SvTYPE(SvRV(*opt)) != SVt_PVAV)
					Perl_croak(aTHX_ "Invalid type for 'notify'");

				while ((flag = av_fetch((AV *) SvRV(*opt), count++, 0))) {
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

void git_hv_to_merge_tree_opts(HV *opts, git_merge_tree_opts *merge_tree_opts) {
	SV **opt;

	if ((opt = hv_fetchs(opts, "flags", 0))) {
		size_t count = 0;
		SV **flag;

		if (!SvROK(*opt) || SvTYPE(SvRV(*opt)) != SVt_PVAV)
			Perl_croak(aTHX_ "Invalid type for 'flags'");

		while ((flag = av_fetch((AV *) SvRV(*opt), count++, 0))) {
			if (SvPOK(*flag)) {
				const char *f = SvPVbyte_nolen(*flag);

				if (strcmp(f, "find_renames") == 0)
					merge_tree_opts -> flags |= GIT_MERGE_TREE_FIND_RENAMES;
				else
					Perl_croak(aTHX_ "Invalid 'flags' value");
			} else
				Perl_croak(aTHX_ "Invalid type for 'flag'");
		}
	}

	if ((opt = hv_fetchs(opts, "automerge", 0))) {
		if (SvPOK(*opt)) {
			const char *auto_merge = SvPVbyte_nolen(*opt);
			if (strcmp(auto_merge, "favor_ours") == 0)
				merge_tree_opts -> file_favor =
					GIT_MERGE_FILE_FAVOR_OURS;
			else if (strcmp(auto_merge, "favor_theirs") == 0)
				merge_tree_opts -> file_favor =
					GIT_MERGE_FILE_FAVOR_THEIRS;
			else
				Perl_croak(aTHX_ "Invalid 'automerge' value");
		} else
			Perl_croak(aTHX_ "Invalid type for 'automerge' value");
	}

	if ((opt = hv_fetchs(opts, "rename_threshold", 0))) {
		if (!SvIOK(*opt) || SvIV(*opt) < 0)
			Perl_croak(aTHX_ "Invalid type");

		merge_tree_opts -> rename_threshold = SvIV(*opt);
	}

	if ((opt = hv_fetchs(opts, "target_limit", 0))) {
		if (!SvIOK(*opt) || SvIV(*opt) < 0)
			Perl_croak(aTHX_ "Invalid type");

		merge_tree_opts -> target_limit = SvIV(*opt);
	}
}

MODULE = Git::Raw			PACKAGE = Git::Raw

INCLUDE: xs/Blob.xs
INCLUDE: xs/Branch.xs
INCLUDE: xs/Commit.xs
INCLUDE: xs/Config.xs
INCLUDE: xs/Cred.xs
INCLUDE: xs/Diff.xs
INCLUDE: xs/Diff/Delta.xs
INCLUDE: xs/Diff/File.xs
INCLUDE: xs/Diff/Hunk.xs
INCLUDE: xs/Index.xs
INCLUDE: xs/Index/Entry.xs
INCLUDE: xs/Patch.xs
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
