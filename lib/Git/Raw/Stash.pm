package Git::Raw::Stash;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Stash - Git stash class

=head1 DESCRIPTION

Helper class to manage stashes.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 apply( $repo, $index, [\%stash_apply_opts] )

Apply a single stashed state from the stash list. If local changes in the
working directory conflict with changes in the stash this function will throw a
C<Git::Raw::Error> exception with a C<Git::Raw::Error::EMERGECONFLICT> error
code. If you are restoring untracked files or ignored files and there is a
conflict when applying the modified files, then those files will remain in the
working directory. Valid fields for C<%stash_apply_opts> include:

=over 4

=item * "checkout_opts"

See C<Git::Raw::Repository-E<gt>checkout()>.

=item * "flags"

=over 8

=item * "reinstate_index"

Try to reinstate not only the working tree's changes, but also the index's changes.

=back

=item * "callbacks"

=over 8

=item * "apply_progress"

Progress notification function. The callback receives a single C<$progress> value which
may be any constant provided by C<Git::Raw::Stash::Progress>.

=back

=back

=head2 pop( $repo, $index, [\%stash_apply_opts] )

Apply a single stashed state from the stash list and remove it from the list if
successful.

=head2 save( $repo, $stasher, $msg [, \@opts] )

Save the local modifications to a new stash. Non-default options may be
specified by providing the optional C<@opts> argument. If files were stashed,
this function will return a L<Git::Raw::Commit> object, otherwise C<undef>.

Valid fields for the C<@opts> array are:

=over 4

=item * "keep_index"

All changes already added to the index are left intact in the working directory.
The default is to also stash changes in the index.

=item * "include_untracked"

All untracked files are also stashed and then cleaned up from the working
directory. The default is to leave untracked files in the working directory.

=item * "include_ignored"

All ignored files are also stashed and then cleaned up up from the working
directory. The default is to leave ignored files in the working directory.

=back

=head2 foreach( $repo, $callback )

Run C<$callback> for every stash in the repo. The callback receives three
arguments: the stash C<$index>, the stash C<$message> and the stash C<$commit>,
a L<Git::Raw::Commit> object. A non-zero return value will stop the loop.

=head2 drop( $repo, $index )

Remove a single stash from the stash list.

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

1; # End of Git::Raw::Stash
