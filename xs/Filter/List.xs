MODULE = Git::Raw			PACKAGE = Git::Raw::Filter::List

SV *
load(class, repo, path, mode)
	const char *class
	SV *repo
	SV *path
	SV *mode

	PREINIT:
		int rc;

		Repository repo_ptr;
		Filter_List list = NULL;
		git_filter_mode_t m = GIT_FILTER_TO_WORKTREE;

	CODE:
		repo_ptr = GIT_SV_TO_PTR(Repository, repo);

		if (SvPOK(mode)) {
			const char *mode_str = git_ensure_pv(mode, "mode");

			if (strcmp(mode_str, "to_odb") == 0)
				m = GIT_FILTER_TO_ODB;
			else if (strcmp(mode_str, "to_worktree") == 0)
				m = GIT_FILTER_TO_WORKTREE;
			else
				croak_usage("Invalid value for 'mode', expected 'to_odb' or 'to_worktree'");

			rc = git_filter_list_load(&list,
				repo_ptr -> repository, NULL,
				git_ensure_pv(path, "path"),
				m,
				GIT_FILTER_DEFAULT
			);
			git_check_error(rc);
		} else
			croak_usage("Invalid type for 'mode' value");

		RETVAL = &PL_sv_undef;
		if (list != NULL) {
			GIT_NEW_OBJ_WITH_MAGIC(
				RETVAL, class,
				list, SvRV(repo)
			);
		}

	OUTPUT: RETVAL

SV *
apply_to_blob(self, blob)
	Filter_List self
	Blob blob

	PREINIT:
		int rc;

		git_buf buf = GIT_BUF_INIT_CONST(NULL, 0);

	CODE:
		rc = git_filter_list_apply_to_blob(
			&buf, self, blob
		);
		if (rc != GIT_OK)
			git_buf_free(&buf);

		git_check_error(rc);
		RETVAL = newSVpv(buf.ptr, buf.size);
		git_buf_free(&buf);

	OUTPUT: RETVAL

SV *
apply_to_data(self, data)
	Filter_List self
	SV *data

	PREINIT:
		int rc;

		const char *data_str;
		STRLEN len;

		git_buf in = GIT_BUF_INIT_CONST(NULL, 0);
		git_buf buf = GIT_BUF_INIT_CONST(NULL, 0);

	CODE:
		data_str = git_ensure_pv_with_len(data, "data", &len);

		rc = git_buf_set(&in, data_str, (size_t) len);
		git_check_error(rc);

		rc = git_filter_list_apply_to_data(
			&buf, self, &in
		);
		if (rc != GIT_OK) {
			git_buf_free(&in);
			git_buf_free(&buf);
		}

		git_check_error(rc);

		RETVAL = newSVpv(buf.ptr, buf.size);

		git_buf_free(&in);
		git_buf_free(&buf);

	OUTPUT: RETVAL

SV *
apply_to_file(self, path)
	SV *self
	const char *path

	PREINIT:
		int rc;

		SV *repo;
		Repository repo_ptr;
		Filter_List list;

		git_buf buf = GIT_BUF_INIT_CONST(NULL, 0);

	CODE:
		list = GIT_SV_TO_PTR(Filter::List, self);

		repo = GIT_SV_TO_MAGIC(self);
		repo_ptr = INT2PTR(Repository, SvIV((SV *) repo));

		rc = git_filter_list_apply_to_file(
			&buf, list, repo_ptr -> repository, path
		);
		if (rc != GIT_OK)
			git_buf_free(&buf);

		git_check_error(rc);
		RETVAL = newSVpv(buf.ptr, buf.size);
		git_buf_free(&buf);

	OUTPUT: RETVAL


void
DESTROY(self)
	SV* self

	PREINIT:
		Filter_List list;

	CODE:
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));

		list = GIT_SV_TO_PTR(Filter::List, self);
		git_filter_list_free(list);
