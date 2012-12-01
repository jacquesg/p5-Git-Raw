package Git::Raw::Index;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Index - Git index class

=head1 DESCRIPTION

A C<Git::Raw::Index> represents an index in a Git repository.

=head1 METHODS

=head2 add( $file )

Add C<$file> to the index.

=head2 clear( )

Clear the index.

=head2 read( )

Update the index reading it from disk.

=head2 write( )

Write the index to disk.

=head2 read_tree( $tree )

Replace the index contente with C<$tree>.

=head2 write_tree( )

Create a new tree from the index and write it to disk.

=head2 remove( $path )

Remove C<$path> from the index.

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
