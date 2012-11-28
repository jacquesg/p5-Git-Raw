package Git::Raw::Signature;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Signature - Git signature class

=head1 DESCRIPTION

A C<Git::Raw::Signature> represents the signature of an action.

=head1 METHODS

=head2 new( $name, $email, $time, $offset )

Create a new signature.

=head2 now( $name, $email )

Create a new signature with a timestamp of 'now'.

=head2 name( )

Retrieve the name associated with the signature.

=head2 email( )

Retrieve the email associated with the signature.

=head2 time( )

Retrieve the time of the signature.

=head2 offset( )

Retrieve the time offset (in minutes) of the signature.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Signature
