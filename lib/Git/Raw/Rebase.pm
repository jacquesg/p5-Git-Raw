package Git::Raw::Rebase;

use strict;
use warnings;

use Git::Raw;
use Git::Raw::Rebase::Operation;

=head1 NAME

Git::Raw::Rebase - Git rebase class

=head1 DESCRIPTION

A L<Git::Raw::Rebase> represents a git rebase.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 abort( )

Abort the current rebase, resetting the repository and working directory to
their state before rebase began.

=head2 commit( $author, $committer )

Commit the current patch. All conflicts that may have been introduced by the
last call to C<next> must have been resolved. Returns a L<Git::Raw::Commit>
object. Both C<$author> and C<$committer> should be L<Git::Raw::Signature>
objects.

=head2 current_operation( )

Get the current operation. Returns a L<Git::Raw::Rebase::Operation> object or
C<undef> is there is no operation.

=head2 finish( $signature )

Finish the current rebase.

=head2 inmemory_index( )

Get the index produced by the last operation which will be committed by the
next call to C<commit>. This is useful for resolving conflicts before committing
them. Returns a L<Git::Raw::Index> object.

=head2 new( $repo, $branch, $upstream, $onto, [\%rebase_opts])

Initialise a new rebase operation, to rebase the changs in C<$branch> relative
to C<$upstream> onto C<$onto>. C<$branch>, C<$upstream> and C<$onto> must be
L<Git::Raw::AnnotatedCommit> objects. Valid fields for the C<%rebase_opts> hash
include:

=over 4

=item * "quiet"

Instruct other clients working on this rebase that a quiet rebase experienced
is required. This is provided for interoperability with other Git tools.

=item * "inmemory"

Perform an in-memory rebase. This allows for stepping through each operation
and committing the rebased changes without rewinding HEAD or putting the
repository in a rebase state. This will not interfere with the working directory.

=item * "rewrite_notes_ref"

Name of the notes reference used to rewrite notes for rebased commits when
finishing the rebase. If not provided, the contents of the configuration option
C<notes.rewriteRef> is examined unless the configuration option C<notes.rewrite.rebase>
is set to a false value. If C<notes.rewriteRef> is also not set, no notes
will be rewritten.

=item * "merge_opts"

See C<Git::Raw::Repository-E<gt>merge()> for valid C<%merge_opts> values.

=item * "checkout_opts"

See C<Git::Raw::Repository-E<gt>checkout()> for valid C<%checkout_opts> values.

=back

=head2 next( )

Perform the next rebase operation. If the operation is one that applies a patch
then the patch will be applied and the index and working directory will be
updated with the changes. If there are conflicts, these need to be resolved
before calling C<commit>. Returns a L<Git::Raw::Rebase::Operation> object, or
C<undef> if there aren't any rebase operations left.

=head2 open( )

Open an existing rebase.

=head2 operation_count( )

Get the number of operations that are to be applied.

=head2 operations( )

Get all operations that are to be applied. Returns a list of
L<Git::Raw::Rebase::Operation> objects.

=head2 orig_head_name( )

Get the original HEAD ref name.

=head2 orig_head_id( )

Get the original HEAD id.

=head2 onto_name( )

Get the onto ref name.

=head2 onto_id( )

Get the onto id.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Rebase
