package Git::Raw::Indexer;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Indexer - Git indexer class

=head1 DESCRIPTION

A L<Git::Raw::Indexer> represents a git indexer object.

=head1 METHODS

=head2 new( $directory, $odb )

Create a new indexer. C<$directory> is the directory where the packfile and
index should be stored.

=head2 append( $data, $progress )

Add C<$data> to the indexer. C<$progress> should be a L<Git::Raw::TransferProgress>
object.

=head2 commit( $progress )

Finalize the pack and index. This will resolve any pending deltas and write out
the index file. C<$progress> should be a L<Git::Raw::TransferProgress> object.

=head2 hash( )

Retrieve the packfile's hash. A packfile's name is derived from the sorted
hashing of all object names. This is only correct after the index has been
finalized.

=head1 AUTHOR

Jacques Germishuys <jacquesg@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Indexer
