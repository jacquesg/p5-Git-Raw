package Git::Raw::Worktree;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Worktree - Git worktree class

=head1 DESCRIPTION

A L<Git::Raw::Worktree> represents a git worktree.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 add( $repo, $name, $path )

Add a new worktree.

=head2 lookup( $repo, $name )

Lookup a worktree.

=head2 name( )

Retrieve the name of the worktree.

=head2 path( )

Retrieve the filesystem path for the worktree.

=head2 repository( )

Open the worktree as a repository. Returns a L<Git::Raw::Repository> object.

=head2 list( $repo )

List all worktress for C<$repo>.

=head2 is_locked( )

Check if the worktree is locked. Returns the reason for locking or a falsy value.

=head2 is_prunable( \%prune_opts )

Check if the worktree can be pruned. Valid fields for th C<%prune_opts> hash
are:

=over 4

=item * "flags"

Prune flags. Valid values include:

=over 8

=item * "valid"

Prune the working tree even if working tree is valid.

=item * "locked"

Prune the working tree even if it is locked.

=item * "working_tree"

Prune checked out working tree.

=back

=back

=head2 lock( $reason )

Lock the worktree with C<$reason>.

=head2 unlock( )

Unlock the worktree.

=head2 validate( )

Check if the worktree is valid. A valid worktree requirest both the git data
structures inside the linked parent repository and the linked working copy to
be present.

=head2 prune( \%prune_opts )

Prune the working tree. Pruning the working tree removes the git data structures
on disk. See C<is_prunable> for valid values of C<%prune_opts>.

=head1 AUTHOR

Jacques Germishuys <jacquesg@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Worktree
