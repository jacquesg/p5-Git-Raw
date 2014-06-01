#include <raw/raw.h>
#include <raw/util/general.h>
#include <raw/util/validation.h>
#include <raw/checkout.h>
#include <raw/config.h>
#include <raw/cred.h>
#include <raw/diff.h>
#include <raw/filter.h>
#include <raw/index.h>
#include <raw/merge.h>
#include <raw/push.h>
#include <raw/remote.h>
#include <raw/stash.h>
#include <raw/tag.h>

#define MY_CXT_KEY "Git::Raw::_guts" XS_VERSION
typedef struct {
	HV *objs;
} my_cxt_t;

START_MY_CXT

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
typedef git_raw_filter * Filter;
typedef git_filter_source * Filter_Source;
typedef git_index * Index;
typedef git_index_entry * Index_Entry;
typedef git_patch * Patch;
typedef git_pathspec * PathSpec;
typedef git_raw_push * Push;
typedef git_pathspec_match_list * PathSpec_MatchList;
typedef git_reference * Reference;
typedef git_reflog * Reflog;
typedef git_refspec * RefSpec;
typedef git_raw_remote * Remote;
typedef git_repository * Repository;
typedef git_signature * Signature;
typedef git_tag * Tag;
typedef git_tree * Tree;
typedef git_treebuilder * Tree_Builder;
typedef git_tree_entry * Tree_Entry;
typedef git_revwalk * Walker;


SV *gr_bless_into_obj_inplace(const char *class, void *data, SV *owner, SV *obj) {
	dMY_CXT;

	/* bless into class */
	(void) sv_setref_pv(obj, class, data);

	/* register in our object registry */
	(void) hv_store_ent(MY_CXT.objs,
		sv_2mortal(newSVuv((UV) SvRV(obj))),
			&PL_sv_undef, 0);

	SvREFCNT_inc(owner);

	gr_obj_magic_add(obj, owner);

	return obj;
}

SV *gr_bless_into_obj(const char *class, void *data, SV *owner) {
	return gr_bless_into_obj_inplace(class, data, owner, newSV(0));
}

SV *gr_obj_owner(SV *obj) {
	gr_obj_data *data = gr_obj_magic_get(obj);

	if (data != NULL)
	{
		return data -> owner;
	}

	return NULL;
}

void gr_free_obj(const char *class, SV *obj, gr_free_function free_function) {
	gr_obj_data *data = NULL;

	fprintf(stderr, "%s: Trying to free\n", class);
	if ((data = gr_obj_magic_get(obj))) {
		if (gr_obj_data_dec_refcount(data)) {
			fprintf(stderr, "%s: Freeing\n", class);
			free_function(git_sv_to_ptr(class, obj));
		}
		if (data -> owner)
			SvREFCNT_dec(data -> owner);
		gr_obj_data_free(data);
	}
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

		/* substr() may return a SVt_PVLV, need to perform some force majeur */
		if (SvPOK(sv)) {
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

MODULE = Git::Raw			PACKAGE = Git::Raw

BOOT:
{
	MY_CXT_INIT;
	MY_CXT.objs = newHV();
	git_threads_init();
}

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

void
CLONE(...)
	PREINIT:
		HE *entry = NULL;
		HV *new_objs = NULL;

	CODE:
		MY_CXT_CLONE;

		SvLOCK((SV *) MY_CXT.objs);

		new_objs = newHV();

		hv_iterinit(MY_CXT.objs);
		while ((entry = hv_iternext(MY_CXT.objs))) {
			SV *old_sv = NULL, *new_sv = NULL;
			SV *old_owner = NULL, *new_owner = NULL;
			gr_obj_data *old_magic = NULL;

			/* create an entry in our registry */
			old_sv = (SV *) SvUV(hv_iterkeysv(entry));
			if ((new_sv = Perl_ptr_table_fetch(aTHX_ PL_ptr_table, old_sv))) {
				SV *new_key = NULL;

				new_key = sv_2mortal(newSVuv((UV) new_sv));
				hv_store_ent(new_objs, new_key, &PL_sv_undef, 0);
			}

			/* if we have data associated with the object, clone it */
			if ((old_magic = gr_obj_magic_get(old_sv)) != NULL) {
				gr_obj_data *data = gr_obj_data_dup(old_magic);

				/* if the object has an owner, we need to find the new owner */
				if ((old_owner = data -> owner)) {
					if ((new_owner = Perl_ptr_table_fetch(aTHX_ PL_ptr_table, old_owner)) != NULL) {
						SvREFCNT_inc((SV *) new_owner);
						data -> owner = new_owner;
					} else {
						/* we didn't find the owner in the table, this is bad */
					}
				}

				/* some objects define their own helper functions i.e. clone */
				if (data -> opts) {
					if (data -> opts -> clone) {
						/* should probably only pass the user data to the function, not the sv */
						data -> opts -> clone(old_sv, new_sv);
					}
				}

				/* remove previously associated magic, and set the new magic */
				gr_obj_magic_remove(new_sv);
				gr_obj_magic_set(new_sv, data);
			}
		}

		SvUNLOCK((SV *) MY_CXT.objs);

		MY_CXT.objs = new_objs;

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
