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

    # connect the remote and set the acquire credentials callback
    $remote -> connect('fetch', {
      'credentials' => sub {
        Git::Raw::Cred -> userpass($usr, $pwd)
      },
    });

    # fetch from the remote and update the local tips
    $remote -> download;
    $remote -> update_tips({
      'update_tips' => sub {
        my ($ref, $a, $b) = @_;
        print "Updated $ref: $a -> $b", "\n";
      }
    });

    # disconnect
    $remote -> disconnect;

    my $empty_repo = Git::Raw::Repository -> new;
    my $anonymous_remote = Git::Raw::Remote -> create_anonymous($repo, $url);
    my $list = $anonymous_remote -> ls;

=head1 DESCRIPTION

A C<Git::Raw::Remote> represents a Git remote.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 create( $repo, $name, $url )

Create a remote with the default fetch refspec and add it to the repository's
configuration.

=head2 create_with_fetchspec( $repo, $name, $url, $fetch )

Create a remote with the provided fetch refspec and add it to the repository's
configuration.

=head2 create_anonymous( $repo, $url )

Create a remote in memory (anonymous).

=head2 load( $repo, $name )

Load an existing remote. Returns a L<Git::Raw::Remote> object if the remote
was found, otherwise C<undef>.

=head2 delete( $repo, $name )

Delete an existing remote.

=head2 owner( )

Retrieve the L<Git::Raw::Repository> owning the remote.

=head2 default_branch( )

Retrieve the default branch of remote repository, that is, the branch which
HEAD points to. If the remote does not support reporting this information
directly, it performs the guess as git does, that is, if there are multiple
branches which point to the same commit, the first one is chosen. If the master
branch is a candidate, it wins. If the information cannot be determined, this
function will return C<undef>. B<Note>, this function should only be called after
the remote has established a connection.

=head2 name( )

Retrieve the name of the remote.

=head2 rename( $repo, $old_name, $new_name, [ \@problems ] )

Rename a remote. Non-default refspecs cannot be renamed and will be store in
C<@problems> if provided.

=head2 url( [ $url ] )

Retrieve the URL of the remote. If C<$url> is passed, the remote's URL will be
updated and returned.

=head2 pushurl( [ $url ] )

Retrieve the push URL for the remote. If C<$url> is passed, the remote's push
URL will be updated and returned.

=head2 add_fetch( $spec )

Add a fetch spec to the remote.

=head2 add_push( $spec )

Add a push spec to the remote.

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

The OID of the reference.

=item * "lid"

The local OID of the reference (optional).

=back

=head2 fetch( [ \%fetch_opts ] )

Download new data and update tips. Convenience function to connect to a remote,
download the data, disconnect and update the remote-tracking branches. Valid fields for
the C<%fetch_opts> hash are:

=over 4

=item * "callbacks"

See L<C<CALLBACKS>>.

=item * "prune"

NOT IMPLEMENTED.

=item * "update_fetchead"

NOT IMPLEMENTED.

=item * "download_tags"

NOT IMPLEMENTED.

=item * "custom_headers"

NOT IMPLEMENTED.

=back

=head2 push( \@refspecs, [ \%push_opts ] )

Perform all the steps of a push, including uploading new data and updating the
remote tracking-branches. Valid fields for the C<%push_opts> hash are:

=over 4

=item * "callbacks"

See L<C<CALLBACKS>>.

=item * "custom_headers"

NOT IMPLEMENTED.

=back

=head2 connect( $direction, [ \%callbacks ] )

Connect to the remote. The C<$direction> should either be C<"fetch"> or C<"push">.

=head2 disconnect( )

Disconnect the remote.

=head2 download( [ \%fetch_opts ] )

Download the remote packfile. See C<Git::Raw::Remote-E<gt>fetch()> for valid
C<%fetch_opts> values.

=head2 upload( \@refspecs, [ \%push_opts ] )

Create a packfile and send it to the server. C<@refspecs> is a list of refspecs
to use for the negotiation with the server to determine the missing objects
that need to be uploaded.

=head2 prune( [ \%callbacks ] )

Prune tracking refs that are no longer present on remote.

=head2 update_tips( [ \%callbacks ] )

Update the tips to the new status.

=head2 is_connected( )

Check if the remote is connected.

=head1 CALLBACKS

=head2 credentials

The callback to be called any time authentication is required to connect to the
remote repository. The callback receives a string C<$url> containing the URL of
the remote, the C<$user> extracted from the URL and a list of supported
authentication C<$types>. The callback should return either a L<Git::Raw::Cred>
object or alternatively C<undef> to abort the authentication process. C<$types>
may contain one or more of the following:

=over 4

=item * "userpass_plaintext"

Plaintext username and password.

=item * "ssh_key"

A SSH key from disk

=item * "ssh_custom"

A SSH key with a custom signature function.

=item * "ssh_interactive"

Keyboard-interactive based SSH authentication

=item * "username"

Username-only credential information.

=item * "default"

A key for NTLM/Kerberos default credentials.

=back

B<Note:> this callback may be invoked more than once.

=head2 certificate_check

Callback to be invoked if cert verification fails. The callback receives a
L<Git::Raw::Cert::X509> or L<Git::Raw::Cert::HostKey> object, a truthy
value C<$valid> and C<$host>. This callback should return a negative number to
abort.

=head2 sideband_progress

Textual progress from the remote. Text sent over the progress side-band will be
passed to this function (this is the 'counting objects' output or any other
information the remote sends). The callback receives a string C<$msg>
containing the progress information.

=head2 transfer_progress

During the download of new data, this will be regularly called with the current
count of progress done by the indexer. The callback receives a
L<Git::Raw::TransferProgress> object.

=head2 update_tips

Each time a reference is updated locally, this function will be called with
information about it. The callback receives a string containing the reference
C<$ref> of the reference that was updated, and the two OID's C<$a> before and
after C<$b> the update. C<$a> will be C<undef> if the reference was created,
likewise C<$b> will be C<undef> if the reference was removed.

=head2 push_transfer_progress

During the upload of new data, this will regularly be called with the transfer
progress. The callback receives the following integers:
C<$current>, C<$total> and C<$bytes>.

=head2 push_update_reference

For each of the updated references, this will be called with a status report
for the reference. The callback receives C<$ref> and C<$msg> as strings. If
C<$msg> is defined, the reference mentioned in C<$ref> has not been updated.

=head2 push_negotation

The callbacks receives a list of updates that will be sent to the destination.
Each items consists of C<$src_refname>, C<$dst_refname> as well as their OIDs,
C<$src> and C<$dst>. This callback should return a negative number to abort.

=head2 pack_progress

During the packing of new data, this will regularly be called with the progress
of the pack operation. Be aware that this is called inline with pack
building operations, so performance may be affected. The callback receives the
following integers:
C<$stage>, C<$current> and C<$total>.

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

1; # End of Git::Raw::Remote
