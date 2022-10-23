package Git::Raw::TransferProgress;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::TransferProgress - Git transfer progress class

=head1 DESCRIPTION

A L<Git::Raw::TransferProgress> represents it indexer object.

=head1 METHODS

=head2 new( )

Create a new transfer progress object.

=head2 total_objects( )

Number of objects in the packfile being downloaded.

=head2 indexed_objects( )

Received objects that have been hashed.

=head2 received_objects( )

Objects which have been downloaded

=head2 local_objects( )

Locally-available objects that have been injected in order to fix a thin pack.

=head2 total_deltas( )

=head2 indexed_deltas( )

=head2 received_bytes( )

Size of the packfile received up to now.

=head1 AUTHOR

Jacques Germishuys <jacquesg@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::TransferProgress
