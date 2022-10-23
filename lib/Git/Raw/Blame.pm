package Git::Raw::Blame;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Blame - Git blame class

=head1 DESCRIPTION

A L<Git::Raw::Blame> represents the blame information for a file.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 hunk_count( )

Retrieve the number of hunks that exist in the blame structure.

=head2 hunks( [$index] )

Returns a list of L<Git::Raw::Blame::Hunk> objects. If C<$index> is specified
only the hunk at the specified index will be returned.

=head2 buffer( $buffer )

Retrieve a new L<Git::Raw::Blame> object, created from this reference
L<Git:Raw::Blame> object and C<$buffer>, a file that has been modified in
memory.

=head2 line( $line_no )

Retrieve the L<Git::Raw::Blame::Hunk> that relates to the given line number in
the newest commit.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

Jacques Germishuys <jacquesg@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Blame
