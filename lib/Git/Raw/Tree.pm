package Git::Raw::Tree;

use strict;
use warnings;

=head1 NAME

Git::Raw::Tree - Git tree class

=head1 DESCRIPTION

A C<Git::Raw::Tree> represents a Git tree.

=head1 METHODS

=head2 id( )

Retrieve the id of the tree, as string.

=head2 entries( )

Retrieve a list of L<Git::Raw::TreeEntry> objects.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Tree
