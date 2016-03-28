
/* remap object enum's to defines */

#define ANY         GIT_OBJ_ANY
#define BAD         GIT_OBJ_BAD
#define COMMIT      GIT_OBJ_COMMIT
#define TREE        GIT_OBJ_TREE
#define BLOB        GIT_OBJ_BLOB
#define TAG         GIT_OBJ_TAG
#define OFS_DELTA   GIT_OBJ_OFS_DELTA
#define REF_DELTA   GIT_OBJ_REF_DELTA

#include "const-c-object.inc"

#undef ANY
#undef BAD
#undef COMMIT
#undef TREE
#undef BLOB
#undef TAG
#undef OFS_DELTA
#undef REF_DELTA

