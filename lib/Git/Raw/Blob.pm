package Git::Raw::Blob;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Blob - Git blob class

=head1 DESCRIPTION

A C<Git::Raw::Blob> represents a Git blob.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 create( $repo, $buffer )

Create a new blob from the given buffer.

=head2 lookup( $repo, $id )

Retrieve the blob corresponding to C<$id>. This function is pretty much the
same as C<$repo-E<gt>lookup($id)> except that it only returns blobs.

=head2 content( )

Retrieve the raw content of a blob.

=head2 size( )

Retrieve the size of the raw content of a blob.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Blob
