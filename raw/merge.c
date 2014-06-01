#include <raw/index.h>
#include <raw/util/validation.h>

void git_hv_to_merge_opts(HV *opts, git_merge_options *merge_options) {
	AV *lopt;
	SV *opt;

	if ((lopt = git_hv_list_entry(opts, "flags"))) {
		size_t i = 0, count = 0;
		SV **flag;

		while ((flag = av_fetch(lopt, i++, 0))) {
			const char *value = NULL;

			if (!SvOK(*flag))
				continue;

			value = git_ensure_pv(*flag, "flag");

			if (strcmp(value, "find_renames") == 0)
				merge_options -> flags |= GIT_MERGE_TREE_FIND_RENAMES;
			else
				Perl_croak(aTHX_ "Invalid 'flags' value");
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

/* vim: set syntax=xs ts=4 sw=4: */
