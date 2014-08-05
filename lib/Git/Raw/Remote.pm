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
      'credentials' => sub { Git::Raw::Cred -> userpass($usr, $pwd) }
      'update_tips' => sub {
        my ($ref, $a, $b) = @_);
        print "Updated $ref: $a -> $b", "\n";
      }
    });

    # connect the remote
    $remote -> connect('fetch');

    # fetch from the remote and update the local tips
    $remote -> download;
    $remote -> update_tips;

    # disconnect
    $remote -> disconnect;

    my $empty_repo = Git::Raw::Repository -> new;
    my $anonymous_remote = Git::Raw::Remote -> create_anonymous($repo, $url, undef);
    my $list = $anonymous_remote -> ls;

=head1 DESCRIPTION

A C<Git::Raw::Remote> represents a Git remote.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 create( $repo, $name, $url )

Create a remote with the default fetch refspec and add it to the repository's
configuration.

=head2 create_anonymous( $repo, $url, $fetch_refspec )

Create a remote in memory (anonymous).

=head2 load( $repo, $name )

Load an existing remote.

=head2 owner( )

Retrieve the L<Git::Raw::Repository> owning the remote.

=head2 name( [ $name, \@problems ] )

Retrieve the name of the remote. If C<$name> is passed, the remote's name will
be updated and returned. Non-default refspecs cannot be renamed and will be
store in C<@problems> if provided.

=head2 url( [ $url ] )

Retrieve the URL of the remote. If C<$url> is passed, the remote's URL will be
updated and returned.

=head2 pushurl( [ $url ] )

Retrieve the push URL for the remote. If C<$url> is passed, teh rmeote's push
URL will be updated and returned.

=head2 check_cert( $value )

Set whether to check the server's certificate (applies to HTTPS only).

=head2 add_fetch( $spec )

Add a fetch spec to the remote.

=head2 add_push( $spec )

Add a push spec to the remote.

=head2 clear_refspecs( )

Clear the remote's refspecs.

=head2 refspec_count( )

Retrieve the refspec count.

=head2 refspecs( )

Retrieve the remote's refspecs. Returns a list of L<Git::Raw::RefSpec> objects.

=head2 ls( )

Retrieve the list of refs at the remote. Returns a hash reference where the key
is the name of the reference, and the value is a hash reference containing the
following values:

=over 4

=item * "local"

Whether the reference exists locally.

=item * "id"

The object ID of the reference.

=item * "lid"

The local object ID of the reference (optional).

=back

=head2 callbacks( \%callbacks )

=over 4

=item * "credentials"

The callback to be called any time authentication is required to connect to the
remote repository. The callback receives a string containing the URL of the
remote, and it must return a L<Git::Raw::Cred> object.

=item * "sideband_progress"

Textual progress from the remote. Text send over the progress side-band will be
passed to this function (this is the 'counting objects' output). The callback
receives a string containing progress information.

=item * "transfer_progress"

During the download of new data, this will be regularly called with the current
count of progress done by the indexer. The callback receives the following integers:
C<total_objects>, C<received_objects>, C<local_objects>, C<total_deltas>,
C<indexed_deltas> and C<received_bytes>.

=item * "update_tips"

Each time a reference is updated locally, this function will be called with
information about it. The callback receives a string containing the name of the
reference that was updated, and the two OID's C<a> before and after C<b> the update.

=back

=head2 fetch( )

Download new data and update tips. Convenience function to connect to a remote,
download the data, disconnect and update the remote-tracking branches.

=head2 connect( $direction )

Connect to the remote. The C<$direction> should either be C<"fetch"> or C<"push">.

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

=head2 is_url_valid( $url )

Check whether C<$url> is a valid remote URL.

=head2 is_url_supported( $url )

Check whether C<$url> the passed URL is supported by this version of the
library.

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
