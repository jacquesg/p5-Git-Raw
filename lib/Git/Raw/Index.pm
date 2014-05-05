package Git::Raw::Index;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Index - Git index class

=head1 DESCRIPTION

A C<Git::Raw::Index> represents an index in a Git repository.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 add( $entry )

Add C<$entry> to the index. C<$entry> should either be the path of a file
or alternatively a C<Git::Raw::Index::Entry>.

=head2 remove( $path )

Remove C<$path> from the index.

=head2 clear( )

Clear the index.

=head2 read( [$force] )

Update the index reading it from disk.

=head2 write( )

Write the index to disk.

=head2 read_tree( $tree )

Replace the index contente with C<$tree>.

=head2 write_tree( [$repo] )

Create a new tree from the index and write it to disk. C<$repo> optionally
indicates which C<Git::Raw::Repository> the tree should be written to.

=head2 checkout( [\%checkout_opts] )

Update files in the working tree to match the contents of the index.
See C<Git::Raw::Repository-E<gt>checkout()> for valid
C<%checkout_opts> values.

=head2 entries( )

Retrieve index entries. Returns a list of C<Git::Raw::Index::Entry> objects.

=head2 remove_conflict( $file )

Remove C<$file> from the index.

=head2 has_conflicts( )

Determine if the index contains entries representing file conflicts.

=head2 conflict_cleanup( )

Remove all conflicts in the index (entries with a stage greater than 0).

=head2 conflicts( )

Retrieve index entries that represent a conflict. Returns a list of
C<Git::Raw::Index::Entry> objects.

=head2 update_all( \%opts )

Update all index entries to match the working directory. Valid fields for the
C<%opts> hash are:

=over 4

=item * "paths"

List of path patterns to add.

=item * "notification"

The callback to be called for each updated item. Receives the C<$path> and
matching C<$pathspec>. This callback should return L<0> if the file should be
added to the index, L<E<gt>0> if it should be skipped or L<E<lt>0> to abort.

=back

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Index
