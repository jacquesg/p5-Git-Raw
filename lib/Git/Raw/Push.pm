package Git::Raw::Push;

use strict;
use warnings;

=head1 NAME

Git::Raw::Push - Git push class

=head1 DESCRIPTION

Helper class for pushing.

=head1 METHODS

=head2 new( $remote )

Create a new push object.

=head2 add_refspec( $spec )

Add the C<$spec> refspec to the push object. Note that C<$spec> is a string.

=head2 finish( )

Actually push.

=head2 unpack_ok( )

Check if the remote successfully unpacked.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Push
