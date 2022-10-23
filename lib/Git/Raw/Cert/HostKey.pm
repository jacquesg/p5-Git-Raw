package Git::Raw::Cert::HostKey;

use strict;
use warnings;

=head1 NAME

Git::Raw::Cert::HostKey - Git hostkey class

=head1 DESCRIPTION

A L<Git::Raw::Cert::HostKey> object represents a hostkey.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 ssh_types( )

List of hostkey types, valid values include C<"md5"> and/or C<"sha1">.

=head2 sha1( )

SHA-1 hostkey hash or C<undef> if not available.

=head2 md5( )

MD5 hostkey hash or C<undef> if not available.

=head1 AUTHOR

Jacques Germishuys <jacquesg@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Cert::HostKey
