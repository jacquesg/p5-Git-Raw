package Git::Raw::Branch;

use strict;
use warnings;

=head1 NAME

Git::Raw::Branch - Git branch class

C<Git::Raw::Branch> is an helper class to lookup branches (which are just
L<Git::Raw::Reference>) by name.

=head1 METHODS

=head2 lookup( $repo, $name, $is_local )

Retrieve the L<Git::Raw::Reference> corresponding to the given branch name.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Branch
