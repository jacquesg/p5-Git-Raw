MODULE = Git::Raw			PACKAGE = Git::Raw::TransferProgress

TransferProgress
new(class)

	PREINIT:
		git_transfer_progress *tp;

	CODE:
		Newxz(tp, 1, git_transfer_progress);
		RETVAL = tp;

	OUTPUT: RETVAL

SV *
total_objects(self)
	TransferProgress self

	CODE:
		RETVAL = newSVuv(self -> total_objects);

	OUTPUT: RETVAL

SV *
indexed_objects(self)
	TransferProgress self

	CODE:
		RETVAL = newSVuv(self -> indexed_objects);

	OUTPUT: RETVAL

SV *
received_objects(self)
	TransferProgress self

	CODE:
		RETVAL = newSVuv(self -> received_objects);

	OUTPUT: RETVAL

SV *
local_objects(self)
	TransferProgress self

	CODE:
		RETVAL = newSVuv(self -> local_objects);

	OUTPUT: RETVAL

SV *
total_deltas(self)
	TransferProgress self

	CODE:
		RETVAL = newSVuv(self -> total_deltas);

	OUTPUT: RETVAL

SV *
indexed_deltas(self)
	TransferProgress self

	CODE:
		RETVAL = newSVuv(self -> indexed_deltas);

	OUTPUT: RETVAL

SV *
received_bytes(self)
	TransferProgress self

	CODE:
		RETVAL = newSVuv(self -> received_bytes);

	OUTPUT: RETVAL

void
DESTROY(self)
	TransferProgress self

	CODE:
		Safefree(self);

