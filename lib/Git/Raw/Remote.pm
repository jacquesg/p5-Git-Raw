package Git::Raw::Remote;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Remote - Git remote class

=head1 SYNOPSIS

    use Git::Raw;

    # open the Git repository at $path
    my $repo = Git::Raw::Repository -> open($path);

    # add a new remote
    my $remote = Git::Raw::Remote -> create($repo, 'origin', $url);

    # set the acquire credentials callback
    $remote -> callbacks({
      credentials => sub { Git::Raw::Cred -> userpass($usr, $pwd) }
    });

    # connect the remote
    $remote -> connect('fetch');

    # fetch from the remote and update the local tips
    $remote -> download;
    $remote -> update_tips;

    # disconnect
    $remote -> disconnect;

=head1 DESCRIPTION

A C<Git::Raw::Remote> represents a Git remote.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 create( $repo, $name, $url )

Create a remote with the default fetch refspec and add it to the repository's
configuration.

=head2 load( $repo, $name )

Load an existing remote.

=head2 name( [ $name ] )

Retrieve the name of the remote. If C<$name> is passed, the remote's name will
be updated and returned.

=head2 url( [ $url ] )

Retrieve the URL of the remote. If C<$url> is passed, the remote's URL will be
updated and returned.

=head2 add_fetch( $spec )

Add a fetch spec to the remote.

=head2 add_push( $spec )

Add a push spec to the remote.

=head2 callbacks( \%callbacks )

=over 4

=item * "credentials"

The callback to be called any time authentication is required to connect to the
remote repository. The callback receives a string containing the URL of the
remote, and it must return a L<Git::Raw::Cred> object.

=back

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
