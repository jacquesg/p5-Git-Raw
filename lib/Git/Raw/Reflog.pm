package Git::Raw::Reflog;

use strict;
use warnings;

=head1 NAME

Git::Raw::Reflog - Git reflog class

=head1 SYNOPSIS

    use Git::Raw;

    # open the Git repository at $path
    my $repo = Git::Raw::Repository -> open($path);

    # get the master branch
    my $master = Git::Raw::Branch -> lookup($repo, 'master', 1);

    # retrieve the reflog for 'master'
    my $reflog = $master -> reflog;

    # print out reflog information
    my @entries = $reflog -> entries;
    foreach my $entry (@entries) {
        my $committer = $entry -> {'committer'};
        print "Committer:", "\n";
        print "\t", "Name:   ", $committer -> name, "\n";
        print "\t", "E-Mail  ", $committer -> email, "\n";
        print "\t", "Time:   ", $committer -> time, "\n";
        print "\t", "Offset: ", $committer -> offset, "\n";
        print "\n";

        print "Message: ", $entry -> {'message'}, "\n";
        print "Old id:  ", $entry -> {'old_id'}, "\n";
        print "New id:  ", $entry -> {'new_id'}, "\n";
    }

    # add a new entry to the reflog
    my $signature = Git::Raw::Signature -> default($repo);
    $reflog -> append("Hello", $signature);
    $reflog -> write;

    # drop an entry from the reflog
    $reflog -> drop(0);
    $reflog -> write;

    # remove the reflog
    $reflog -> delete;
    $reflog -> write;

=head1 DESCRIPTION

A C<Git::Raw::Reflog> represents a Git reflog.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 open( $reference )

Open the reflog for the reference C<$reference>.

=head2 delete( )

Delete the reflog for the reference.

=head2 append( $message [, $signature])

Add a new entry to the reflog. If C<$signature> is not provided,
the default signature, C<Git::Raw::Signature-E<gt>default()> will be used.

=head2 drop( $index )

Remove entry C<$index> from the reflog.

=head2 write( )

Write the reflog back to disk.

=head2 entry_count( )

Retrieve the number of entries in the reflog.

=head2 entries( [$index, $count] )

Retrieve a list of reflog entries.Each entry is a hash with the
following members:

=over 4

=item * "committer"

The committer of the entry, a L<Git::Raw::Signature> object.

=item * "message"

The message for the entry.

=item * "new_id"

The new C<OID> for the entry.

=item * "old_id"

The old C<OID> for the entry.

=back

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Reflog
