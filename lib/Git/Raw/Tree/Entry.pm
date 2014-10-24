package Git::Raw::Tree::Entry;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Tree::Entry - Git tree entry class

=head1 DESCRIPTION

A L<Git::Raw::Tree::Entry> represents an entry in a L<Git::Raw::Tree>.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 id( )

Retrieve the id of the tree entry, as string.

=head2 name( )

Retrieve the filename of the tree entry.

=head2 file_mode( )

Retrieve the file mode of the tree entry, as an integer. For example,
a normal file has mode 0100644 = 33188.

=head2 object( )

Retrieve the object pointed by the tree entry.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Tree::Entry
