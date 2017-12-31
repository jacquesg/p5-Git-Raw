
/* remap rebase operation enum's to defines */
#define PICK        GIT_REBASE_OPERATION_PICK
#define REWORD      GIT_REBASE_OPERATION_REWORD
#define EDIT        GIT_REBASE_OPERATION_EDIT
#define SQUASH      GIT_REBASE_OPERATION_SQUASH
#define FIXUP       GIT_REBASE_OPERATION_FIXUP
#define EXEC        GIT_REBASE_OPERATION_EXEC

#include "const-c-rebase-operation.inc"

#undef PICK
#undef REWORD
#undef EDIT
#undef SQUASH
#undef FIXUP
#undef EXEC
