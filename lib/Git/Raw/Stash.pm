package Git::Raw::Stash;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Stash - Git stash class

=head1 DESCRIPTION

Helper class to manage stashes.

=head1 METHODS

=head2 save( $repo, $stasher, $msg )

Save the local modifications to a new stash.

=head2 foreach( $repo, $callback )

Run C<$callback> for every stash in the repo. The callback receives three
arguments: the stash index, the stash message and the stash object id. Non-zero
return value stops the loop.

=head2 drop( $repo, $index )

Remove a single stashed state from the stash list.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Stash
