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
    my $remote = Git::Raw::Remote -> add($repo, 'origin', $url);

    # set the acquire credentials callback
    $remote -> cred_acquire(sub { Git::Raw::Cred -> plaintext($usr, $pwd) });

    # connect the remote
    $remote -> connect('fetch');

    # fetch from the remote and update the local tips
    $remote -> download;
    $remote -> update_tips;

    # disconnect
    $remote -> disconnect;

=head1 DESCRIPTION

A C<Git::Raw::Remote> represents a Git remote.

=head1 METHODS

=head2 add( $repo, $name, $url )

Add a new remote to the given L<Git::Raw::Repository> with name C<$name> and
URL C<$url>.

=head2 name( [ $name ] )

Retrieve the name of the remote. If C<$name> is passed, the remote's name will
be updated and returned.

=head2 url( [ $url ] )

Retrieve the URL of the remote. If C<$url> is passed, the remote's URL will be
updated and returned.

=head2 fetchspec( [ $spec ] )

Retrieve the fetchspec of the remote. If C<$spec> is passed, the remote's
fetchspec will be updated and returned.

=head2 pushspec( [ $spec ] )

Retrieve the pushspec of the remote. If C<$spec> is passed, the remote's
pushspec will be updated and returned.

=head2 cred_acquire( $callback )

Run $callback any time authentication is required to connect to the remote
repository. The callback receives a string containing the URL of the remote, and
it must return a L<Git::Raw::Cred> object.

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
