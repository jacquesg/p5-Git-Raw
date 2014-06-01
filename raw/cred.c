#include <raw/cred.h>

void git_ssh_interactive_cbb(const char *name, int name_len,
	const char *instruction, int instruction_len, int num_prompts,
	const LIBSSH2_USERAUTH_KBDINT_PROMPT *prompts, LIBSSH2_USERAUTH_KBDINT_RESPONSE *responses,
	void **abstract) {
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

/* vim: set syntax=xs ts=4 sw=4: */
