#ifndef GIT_RAW_REMOTE_H
#define GIT_RAW_REMOTE_H

#include "raw.h"

typedef struct {
	SV *progress;
	SV *credentials;
	SV *transfer_progress;
	SV *update_tips;
} git_raw_remote_callbacks;

typedef struct {
	git_remote *remote;
	git_raw_remote_callbacks callbacks;
} git_raw_remote;

void git_init_remote_callbacks(git_raw_remote_callbacks *cbs);
void git_clean_remote_callbacks(git_raw_remote_callbacks *cbs);

int git_progress_cbb(const char *str, int len, void *cbs);
int git_transfer_progress_cbb(const git_transfer_progress *stats, void *cbs);
int git_update_tips_cbb(const char *name, const git_oid *a,
	const git_oid *b, void *cbs);
int git_credentials_cbb(git_cred **cred, const char *url,
	const char *usr_from_url, unsigned int allow, void *cbs);

void git_raw_remote_free(git_raw_remote *remote);

#endif

/* vim: set syntax=xs ts=4 sw=4: */
