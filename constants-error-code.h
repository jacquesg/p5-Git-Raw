
#undef ERROR
#undef PASSTHROUGH
#undef CALLBACK
#undef EAUTH

/* remap libgit2 error enum's to defines */

#define OK                GIT_OK
#define ERROR             GIT_ERROR
#define ENOTFOUND         GIT_ENOTFOUND
#define EEXISTS           GIT_EEXISTS
#define EAMBIGUOUS        GIT_EAMBIGUOUS
#define EBUFS             GIT_EBUFS
#define EBAREREPO         GIT_EBAREREPO
#define EUNBORNBRANCH     GIT_EUNBORNBRANCH
#define EUNMERGED         GIT_EUNMERGED
#define ENONFASTFORWARD   GIT_ENONFASTFORWARD
#define EINVALIDSPEC      GIT_EINVALIDSPEC
#define ECONFLICT         GIT_ECONFLICT
#define ELOCKED           GIT_ELOCKED
#define EMODIFIED         GIT_EMODIFIED
#define EAUTH             GIT_EAUTH
#define ECERTIFICATE      GIT_ECERTIFICATE
#define EAPPLIED          GIT_EAPPLIED
#define EPEEL             GIT_EPEEL
#define EEOF              GIT_EEOF
#define EINVALID          GIT_EINVALID
#define EUNCOMMITTED      GIT_EUNCOMMITTED
#define EDIRECTORY        GIT_EDIRECTORY
#define EMERGECONFLICT    GIT_EMERGECONFLICT
#define PASSTHROUGH       GIT_PASSTHROUGH

#include "const-c-error.inc"

#undef OK
#undef ERROR
#undef ENOTFOUND
#undef EEXISTS
#undef EAMBIGUOUS
#undef EBUFS
#undef EBAREREPO
#undef EUNBORNBRANCH
#undef EUNMERGED
#undef ENONFASTFORWARD
#undef EINVALIDSPEC
#undef ECONFLICT
#undef ELOCKED
#undef EMODIFIED
#undef EAUTH
#undef ECERTIFICATE
#undef EAPPLIED
#undef EPEEL
#undef EEOF
#undef EINVALID
#undef EUNCOMMITTED
#undef EDIRECTORY
#undef EMERGECONFLICT
#undef PASSTHROUGH

