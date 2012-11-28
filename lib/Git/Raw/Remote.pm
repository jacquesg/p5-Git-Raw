package Git::Raw::Remote;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Remote - Git remote class

=head1 DESCRIPTION

A C<Git::Raw::Remote> represents a Git remote.

=head1 METHODS

=head2 add( $repo, $name, $url )

Add a new remote to the given L<Git::Raw::Repository> with name C<$name> and
URL C<$url>.

=head2 name( )

Retrieve the name of the remote.

=head2 url( )

Retrieve the URL of the remote.

=head2 connect( $direction )

Connect to the remote. The direction can be either C<"fetch"> or C<"push">.

=head2 disconnect( )

Disconnect the remote.

=head2 download( )

Download the remote packfile.

=head2 save( )

Save the remote to its repository's config.

=head2 update_tips( )

Update the tips to the new status.

=head2 is_connected( )

Check if the remote is connected.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Remote
