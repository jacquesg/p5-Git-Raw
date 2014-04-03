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

=head2 read( )

Update the index reading it from disk.

=head2 write( )

Write the index to disk.

=head2 read_tree( $tree )

Replace the index contente with C<$tree>.

=head2 write_tree( [$repo] )

Create a new tree from the index and write it to disk. C<$repo> is an optional,
alternative C<Git::Raw::Repository>, or the repository the index should we
written to if its an in-memory index.

=head2 remove( $path )

Remove C<$path> from the index.

=head2 has_conflicts( )

Determine if the index contains entries representing file conflicts.

=head2 conflict_cleanup( )

Remove all conflicts in the index (entries with a stage greater than 0).

=head2 conflicts( )

Retrieve index entries that represent a conflict. Returns a list of
C<Git::Raw::Index::Entry> objects.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Index
