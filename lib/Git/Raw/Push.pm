package Git::Raw::Push;

use strict;
use warnings;

=head1 NAME

Git::Raw::Push - Git push class

=head1 SYNOPSIS

    use Git::Raw;

    # open the Git repository at $path
    my $repo = Git::Raw::Repository -> open($path);

    # add a new remote
    my $remote = Git::Raw::Remote -> create($repo, 'origin', $url);

    # set the acquire credentials callback
    $remote -> cred_acquire(sub { Git::Raw::Cred -> plaintext($usr, $pwd) });

    # connect the remote
    $remote -> connect('push');

    # create a push object
    my $push = Git::Raw::Push -> new($remote);

    # add a refspec
    my $spec = "refs/heads/master:refs/heads/master";
    $push -> add_refspec($spec);

    # actually push and disconnect the remote
    $push -> finish;
    $remote -> disconnect;

    # now fetch from the remote
    $remote -> connect('fetch');
    $remote -> download;
    $remote -> update_tips;
    $remote -> disconnect;

=head1 DESCRIPTION

Helper class for pushing.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

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
