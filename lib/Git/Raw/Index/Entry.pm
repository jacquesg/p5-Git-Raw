package Git::Raw::Index::Entry;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Index::Entry - Git index entry class

=head1 DESCRIPTION

A L<Git::Raw::Index::Entry> represents an index entry in a Git repository index.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 id( )

Retrieve the id of the index entry as a string.

=head2 path( )

Retrieve the path of the index entry.

=head2 size( )

Retrieve the size of the index entry.

=head2 stage( )

Retrieve the stage number for the index entry.

=head2 blob( )

Retrieve the blob for the the index entry. Returns a L<Git::Raw::Blob> object.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Index::Entry
