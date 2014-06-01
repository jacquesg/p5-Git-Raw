#ifndef GIT_RAW_RAW_H
#define GIT_RAW_RAW_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pv_flags
#define NEED_sv_2pvbyte
#define NEED_newRV_noinc
#define NEED_sv_unmagicext

#include "ppport.h"

#include <git2.h>
#include <git2/sys/filter.h>
#include <git2/sys/repository.h>

#ifdef _MSC_VER
#pragma warning (disable : 4244 4267 )
#endif

/* printf format specifier for size_t */
#if defined(_MSC_VER) || defined(__MINGW32__)
# define PRIuZ "Iu"
# define PRIxZ "Ix"
#else
# define PRIuZ "zu"
# define PRIxZ "zx"
#endif

/* reference counting */
typedef struct {
    int (*clone)(SV *old, SV *new);
} gr_obj_data_opts;

typedef struct {
	SV *owner;
	int *refcount;
	void *data;
	gr_obj_data_opts *opts;
} gr_obj_data;

gr_obj_data *gr_obj_data_alloc(int initial_ref_count);
gr_obj_data *gr_obj_data_dup(const gr_obj_data *src);
void gr_obj_data_free(gr_obj_data *data);

void gr_obj_data_set_options(gr_obj_data* data, gr_obj_data_opts *opts);
void gr_obj_data_inc_refcount(gr_obj_data *data);
int gr_obj_data_dec_refcount(gr_obj_data *data);

/* magic */
void gr_obj_magic_set(SV *sv, gr_obj_data *data);
void gr_obj_magic_add(SV *sv, SV *owner);
void gr_obj_magic_remove(SV *sv);
gr_obj_data *gr_obj_magic_get(SV *sv);

/* object management */
typedef void (*gr_free_function)(void *);

SV *gr_bless_into_obj_inplace(const char *class, void *data, SV *magic, SV *obj);
SV *gr_bless_into_obj(const char *class, void *data, SV *magic);
SV *gr_obj_owner(SV *obj);
void gr_free_obj(const char *class, SV *obj, gr_free_function free_function);

git_object *git_sv_to_obj(SV *sv);
void *git_sv_to_ptr(const char *type, SV *sv);
SV *git_obj_to_sv(git_object *o, SV *repo);
SV *git_oid_to_sv(const git_oid *oid);

/* error handling */
void git_check_error(int err);

/* macros */
#define GIT_SV_TO_PTR(type, sv) git_sv_to_ptr(#type, sv)

#define GIT_SV_TO_MAGIC(SV) gr_obj_owner(SV)

#define GIT_NEW_OBJ(rv, class, sv)				\
	STMT_START {						\
		(rv) = gr_bless_into_obj(class, sv, NULL);		\
	} STMT_END

#define GIT_NEW_OBJ_WITH_MAGIC(rv, class, sv, magic)		\
	STMT_START {						\
		(rv) = gr_bless_into_obj(class, sv, magic);		\
	} STMT_END

#define GIT_FREE_OBJ(class, sv, free_function) gr_free_obj(#class, sv, (gr_free_function) free_function)

#endif

/* vim: set syntax=xs ts=4 sw=4: */
