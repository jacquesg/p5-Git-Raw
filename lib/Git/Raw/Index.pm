package Git::Raw::Index;

use strict;
use warnings;

=head1 NAME

Git::Raw::Index - libgit2 index class

=head1 DESCRIPTION

A C<Git::Raw::Index> represents an index in a Git repository.

=head1 METHODS

=head2 add( $file )

Add the given file to the index.

=head2 append( $file )

Append the given file to the index even if duplicate.

=head2 clear( )

Clear completely the index.

=head2 read( )

Update the index reading it from disk.

=head2 uniq( )

Remove all duplicate entries (i.e. with the same path) except the last.

=head2 write( )

Write the index to disk.

=head2 write_tree( )

Create a new tree from the index and write it to disk.

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
