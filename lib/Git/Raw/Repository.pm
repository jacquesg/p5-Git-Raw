package Git::Raw::Repository;

use strict;
use warnings;

=head1 NAME

Git::Raw::Repository - Git repository class

=head1 DESCRIPTION

A C<Git::Raw::Repository> represents a Git repository.

=head1 METHODS

=head2 init( $path, $is_bare )

Initialize a new repository at C<$path>.

=head2 open( $path )

Open the repository at C<$path>.

=head2 discover( $path )

Discover the path to the repository directory given a subdirectory.

=head2 config( )

Retrieve the default L<Git::Raw::Config> of the repository.

=head2 index( )

Retrieve the default L<Git::Raw::Index> of the repository.

=head2 head( )

Retrieve the HEAD of the repository. This function may return a L<Git::Raw::Blob>,
a L<Git::Raw::Commit>, a L<Git::Raw::Tag> or a L<Git::Raw::Tree>.

=head2 lookup( $id )

Retrieve the object corresponding to the given id. This function may return a
L<Git::Raw::Blob>, a L<Git::Raw::Commit>, a L<Git::Raw::Tag> or a
L<Git::Raw::Tree>.

=head2 reset( $target, $type )

Reset the current HEAD to the given commit. Valid reset types are:

=over 4

=item C<":soft">

the head will be moved to the commit

=item C<":mixed">

trigger a Soft reset and replace the index with the content of the commit tree

=back

=head2 status( $file )

Retrieve the status of the given file in the working directory. This functions
returns a list of status flags. Valid status flags are:

=over 4

=item C<"index_new">

=item C<"index_modified">

=item C<"index_deleted">

=item C<"worktree_new">

=item C<"worktree_modified">

=item C<"worktree_deleted">

=item C<"ignored">

=back

=head2 diff( $repo [, $tree] )

Compute the L<Git::Raw::Diff> between the repository index and a tree. If no
C<$tree> is passed, the diff will be computed against the working directory.

=head2 branch( $name, $target )

Create a new L<Git::Raw::Branch>. Shortcut for C<Git::Raw::Branch -E<gt> create()>.

=cut

sub branch { return Git::Raw::Branch -> create(@_) }

=head2 commit( $msg, $author, $committer, [@parents], $tree )

Create a new L<Git::Raw::Commit>. Shortcut for C<Git::Raw::Commit -E<gt> create()>.

=cut

sub commit { return Git::Raw::Commit -> create(@_) }

=head2 tag( $name, $msg, $tagger, $target )

Create a new L<Git::Raw::Tag>. Shortcut for C<Git::Raw::Tag -E<gt> create()>.

=cut

sub tag { return Git::Raw::Tag -> create(@_) }

=head2 tags( )

Retrieve a list of L<Git::Raw::Tag> objects.

=head2 remotes( )

Retrieve a list of L<Git::Raw::Remote> objects.

=head2 walker( )

Create a new L<Git::Raw::Walker>. Shortcut for C<Git::Raw::Walker -E<gt> create()>.

=cut

sub walker { return Git::Raw::Walker -> create(@_) }

=head2 path( )

Retrieve the complete path of the repository.

=head2 workdir( )

Retrieve the working directory of the repository.

=head2 is_empty( )

Tell whether the repository is empty or not.

=head2 is_bare( )

Tell whether the repository is bare or not.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Repository
