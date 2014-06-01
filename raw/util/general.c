#include <raw/util/general.h>
#include <raw/util/validation.h>

void dummy_free(void *ptr) {
	(void) ptr;
}

void git_flag_opt(HV *value, const char *name, int mask, unsigned *out) {
	SV *opt;

	if ((opt = git_hv_int_entry(value, name)) && SvIV(opt))
		*out |= mask;
}

SV *get_callback_option(HV *callbacks, const char *name) {
	SV *cb = NULL;

	if ((cb = git_hv_code_entry(callbacks, name)))
		SvREFCNT_inc(cb);

	return cb;
}

void git_list_to_paths(AV *list, git_strarray *paths) {
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

/* vim: set syntax=xs ts=4 sw=4: */
