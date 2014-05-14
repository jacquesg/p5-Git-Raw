MODULE = Git::Raw			PACKAGE = Git::Raw::Filter

SV *
OK(class)
	CODE:
		RETVAL = newSViv(GIT_OK);

	OUTPUT: RETVAL

SV *
ERROR(class)
	CODE:
		RETVAL = newSViv(GIT_ERROR);

	OUTPUT: RETVAL

SV *
PASSTHROUGH(class)
	CODE:
		RETVAL = newSViv(GIT_PASSTHROUGH);

	OUTPUT: RETVAL



SV *
create(class, name, attributes)
	SV *class
	const char *name
	const char *attributes

	PREINIT:
		Filter filter;

	CODE:
		Newx(filter, 1, git_raw_filter);
		memset(filter, 0, sizeof(git_raw_filter));

		Newx(filter -> name, strlen(name) + 1, char);
		strcpy(filter -> name, name);

		Newx(filter -> attributes, strlen(attributes) + 1, char);
		strcpy(filter -> attributes, attributes);

		filter -> filter.version = GIT_FILTER_VERSION;
		filter -> filter.attributes = filter -> attributes;

		GIT_NEW_OBJ(RETVAL, SvPVbyte_nolen(class), filter);

	OUTPUT: RETVAL

void
callbacks(self, callbacks)
	Filter self
	HV *callbacks

	PREINIT:
		git_filter_callbacks *cbs = NULL;

	CODE:
		cbs = &self -> callbacks;

		git_clean_filter_callbacks(cbs);

		self -> filter.initialize = NULL;
		self -> filter.shutdown = NULL;
		self -> filter.check = NULL;
		self -> filter.apply = NULL;
		self -> filter.cleanup = NULL;

		if ((cbs -> initialize = get_callback_option(
			callbacks, "initialize")))
			self -> filter.initialize = git_filter_init_cbb;

		if ((cbs -> shutdown = get_callback_option(
			callbacks,"shutdown")))
			self -> filter.shutdown = git_filter_shutdown_cbb;

		if ((cbs -> check = get_callback_option(
			callbacks, "check")))
			self -> filter.check = git_filter_check_cbb;

		if ((cbs -> apply = get_callback_option(
			callbacks, "apply")))
			self -> filter.apply = git_filter_apply_cbb;

		if ((cbs -> cleanup = get_callback_option(
			callbacks, "cleanup")))
			self -> filter.cleanup = git_filter_cleanup_cbb;

void
register(self, priority)
	Filter self
	int priority

	PREINIT:
		int rc;

	CODE:
		if (!self -> filter.initialize &&
			!self -> filter.shutdown &&
			!self -> filter.check &&
			!self -> filter.apply &&
			!self -> filter.cleanup)
			croak_usage("No callbacks registered for filter '%s'", self -> name);

		rc = git_filter_register(
			self -> name, (git_filter *) self, priority
		);
		git_check_error(rc);

void
unregister(self)
	Filter self

	PREINIT:
		int rc;

	CODE:
		rc = git_filter_unregister(self -> name);
		git_check_error(rc);

void
DESTROY(self)
	Filter self

	PREINIT:
		int rc = 0;

		git_filter_callbacks *cbs = NULL;

	CODE:
		cbs = &self -> callbacks;

		if (git_filter_lookup(self -> name))
			rc = git_filter_unregister(self -> name);

		git_clean_filter_callbacks(cbs);

		Safefree(self -> attributes);
		Safefree(self -> name);
		Safefree(self);

		git_check_error(rc);
