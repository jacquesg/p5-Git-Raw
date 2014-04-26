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

=head2 sshkey( $user, $public, $private [, $pass ] )

Create a new credential object given a SSH public and private key files, and
optionall the password of the private key. If the SSH support has not been
enabled at build-time, this method will always return C<undef>.

=head2 sshagent( $user )

Create a new credential object used for querying an ssh-agent. If the SSH
support has not been enabled at build-time, this method will always return
C<undef>.

=head2 sshinteractive( $user, $callback )

Create a new credential object based on interactive authentication. The
callback C<$callback> will be invoked when the remote-side issues a challenge.
It receives the following parameters: C<$name>, C<$instruction> and
C<@prompts>. Any of the parameters passed to the callback may be undefined.
Each C<$prompt> entry in C<@prompts> is a hash reference that may contain:

=over 4

=item * "text"

Text for the prompt.

=item * "echo"

Parameter indicating whether the response of the challenge is safe
to be echoed.

=back

The callback should return a list of responses, one for each prompt.
If the SSH support has not been enabled at build-time, this method will always
return C<undef>.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Cred
