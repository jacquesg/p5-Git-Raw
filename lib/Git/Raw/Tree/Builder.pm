package Git::Raw::Tree::Builder;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Tree::Builder - Git tree builder class

=head1 DESCRIPTION

A L<Git::Raw::Tree::Builder> allows you to build Git tree objects.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 new( $repo, [$tree] )

Creates a new tree builder that will build trees in C<$repo>.  If C<$tree> is
passed, the contents of the tree builder are initialized from the contents of
C<$tree>.

=head2 clear( )

Clears the tree builder of all entries.

=head2 entry_count( )

Returns the number of entries contained in this tree builder.

=head2 get( $filename )

Return a L<Git::Raw::TreeEntry> corresponding to C<$filename>.
Returns C<undef> if no such entry exists.

=head2 insert( $filename, $object, $mode )

Adds (or updates) an entry in this tree builder.  C<$object>
can be either a L<Git::Raw::Tree> or L<Git::Raw::Blob> object.
Returns a L<Git::Raw::Tree::Entry> object on success.

=head2 remove( $filename )

Removes the entry associated with the filename C<$filename> from this tree
builder.

=head2 write( )

Writes the tree object we've been building into the repository.
Returns a L<Git::Raw::Tree> object on success.

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Tree::Builder
