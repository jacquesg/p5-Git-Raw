#include <raw/checkout.h>
#include <raw/util/general.h>
#include <raw/util/validation.h>

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

void git_hv_to_checkout_opts(HV *opts, git_checkout_options *checkout_opts) {
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
						Perl_croak(aTHX_ "Invalid type for 'notify' value");
				}
			}
		}
	}
}

int git_checkout_notify_cbb(git_checkout_notify_t why, const char *path, const git_diff_file *baseline,
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

void git_checkout_progress_cbb(const char *path, size_t completed_steps,
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

/* vim: set syntax=xs ts=4 sw=4: */
