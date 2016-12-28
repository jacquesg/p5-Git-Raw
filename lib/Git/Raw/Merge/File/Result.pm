package Git::Raw::Merge::File::Result;

use strict;
use warnings;

=head1 NAME

Git::Raw::Merge::File::Result - Git merge result class

=head1 DESCRIPTION

A L<Git::Raw::Merge::File::Results> represents the result of a file merge.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 automergeable( )

Return a truthy value if the file was automerged, or a false value if the
content contains conflict markers.

=head2 content( )

The contents of the merge.

=head2 path( )

The path that the resultant merge file should use, or C<undef> if a filename
conflict would occur.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Merge::File::Result
