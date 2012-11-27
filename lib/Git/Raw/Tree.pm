package Git::Raw::Tree;

use strict;
use warnings;
use Git::Raw;

=head1 NAME

Git::Raw::Tree - Git tree class

=head1 DESCRIPTION

A C<Git::Raw::Tree> represents a Git tree.

=head1 METHODS

=head2 lookup( $repo, $id )

Retrieve the tree corresponding to the given id. This function is pretty much
the same as C<$repo-E<gt>lookup($id)> except that it only returns trees.

=head2 id( )

Retrieve the id of the tree, as string.

=head2 entries( )

Retrieve a list of L<Git::Raw::TreeEntry> objects.

=head2 diff( $repo [, $tree] )

Retrieve the L<Git::Raw::Diff> between two trees. If no C<$tree> is passed,
the diff will be computed against the working directory.

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
