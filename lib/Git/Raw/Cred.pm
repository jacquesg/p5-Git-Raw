package Git::Raw::Cred;

use strict;
use warnings;

=head1 NAME

Git::Raw::Cred - Git credentials class

=head1 DESCRIPTION

A C<Git::Raw::Cred> object is used to store credentials.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 userpass( $user, $pass )

Create a new credential object with the given username and password.

=head2 sshkey( $user, $public, $private, $pass )

Create a new credential object given a SSH public and private key files, and
the password of the private key. If the SSH support has not been enabled at
build-time, this method will always return C<undef>.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Cred
