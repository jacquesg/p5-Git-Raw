MODULE = Git::Raw			PACKAGE = Git::Raw::Remote

Remote
add(class, repo, name, url)
	SV *class
	Repository repo
	SV *name
	SV *url

	CODE:
		Remote r;

		int rc = git_remote_add(
			&r, repo, SvPVbyte_nolen(name), SvPVbyte_nolen(url)
		);
		git_check_error(rc);

		RETVAL = r;

	OUTPUT: RETVAL

SV *
name(self)
	Remote self

	CODE:
		const char *name = git_remote_name(self);
		RETVAL = newSVpv(name, 0);

	OUTPUT: RETVAL

SV *
url(self)
	Remote self

	CODE:
		const char *url = git_remote_url(self);
		RETVAL = newSVpv(url, 0);

	OUTPUT: RETVAL

void
connect(self, direction)
	Remote self
	SV *direction

	CODE:
		int dir_int;
		const char *dir = SvPVbyte_nolen(direction);

		if (strcmp(dir, ":fetch") == 0)
			dir_int = GIT_DIR_FETCH;
		else if (strcmp(dir, ":push") == 0)
			dir_int = GIT_DIR_PUSH;
		else
			Perl_croak(aTHX_ "Invalid direction");

		int rc = git_remote_connect(self, dir_int);
		git_check_error(rc);

void
disconnect(self)
	Remote self

	CODE:
		git_remote_disconnect(self);

void
download(self)
	Remote self

	CODE:
		git_off_t bytes = 0;
		git_indexer_stats stats;

		int rc = git_remote_download(self, &bytes, &stats);
		git_check_error(rc);

void
save(self)
	Remote self

	CODE:
		int rc = git_remote_save(self);
		git_check_error(rc);

void
update_tips(self)
	Remote self

	CODE:
		int rc = git_remote_update_tips(self, NULL);
		git_check_error(rc);

bool
is_connected(self)
	Remote self

	CODE:
		RETVAL = git_remote_connected(self);

	OUTPUT: RETVAL

void
DESTROY(self)
	Remote self

	CODE:
		git_remote_free(self);
