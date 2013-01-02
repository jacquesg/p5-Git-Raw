package Git::Raw::Repository;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Repository - Git repository class

=head1 SYNOPSIS

    use Git::Raw;

    # clone a Git repository
    my $url  = 'git://github.com/ghedo/p5-Git-Raw.git';
    my $repo = Git::Raw::Repository -> clone($url, 'p5-Git-Raw', { });

    # print all the tags of the repository
    foreach my $tag (@{ $repo -> tags }) {
      say $tag -> name;
    }

=head1 DESCRIPTION

A C<Git::Raw::Repository> represents a Git repository.

=head1 METHODS

=head2 init( $path, $is_bare )

Initialize a new repository at C<$path>.

=head2 clone( $url, $path, \%opts )

Clone the repository at C<$url> to C<$path>. Valid fields for the C<%opts> hash
are:

=over 4

=item * "bare" If true (default is false) create a bare repository.

=back

=head2 open( $path )

Open the repository at C<$path>.

=head2 discover( $path )

Discover the path to the repository directory given a subdirectory.

=head2 config( )

Retrieve the default L<Git::Raw::Config> of the repository.

=head2 index( )

Retrieve the default L<Git::Raw::Index> of the repository.

=head2 head( )

Retrieve the L<Git::Raw::Reference> pointed by the HEAD of the repository.

=head2 lookup( $id )

Retrieve the object corresponding to C<$id>.

=head2 checkout( $object, \%strategy )

Updates the files in the index and working tree to match the content of
C<$object>. The C<%strategy> paramenter can have set the following values:

=over 4

=item * "update_unmodified"

=item * "update_missing"

=item * "update_modified"

=item * "update_untracked"

=item * "allow_conflicts"

=item * "skip_unmerged"

=item * "update_only"

=item * "remove_untracked"

=back

Example:

    $repo -> checkout($repo -> head, {
      'update_missing'  => 1,
      'update_modified' => 1
    });

=head2 reset( $target, $type )

Reset the current HEAD to the given commit. Valid reset types are: C<"soft">
(the head will be moved to the commit) or C<"mixed"> (trigger a soft reset and
replace the index with the content of the commit tree).

=head2 status( $file )

Retrieve the status of <$file> in the working directory. This functions returns
a list of status flags. Possible status flags are: C<"index_new">,
C<"index_modified">, C<"index_deleted">, C<"worktree_new">,
C<"worktree_modified">, C<"worktree_deleted"> and C<"ignored">.

=head2 ignore( $rules )

Add an ignore rules to the repository. The format of the rules is the same one
of the C<.gitignore> file (see the C<gitignore(5)> manpage). Example:

    $repo -> ignore("*.o\n");

=head2 diff( $repo [, $tree] )

Compute the L<Git::Raw::Diff> between the given L<Git::Raw::Tree> and the repo
default index. If no C<$tree> is passed, the diff will be computed between the
repo index and the working directory.

=head2 blob( $buffer )

Create a new L<Git::Raw::Blob>. Shortcut for C<Git::Raw::Blob-E<gt>create()>.

=cut

sub blob { return Git::Raw::Blob -> create(@_) }

=head2 branch( $name, $target )

Create a new L<Git::Raw::Branch>. Shortcut for C<Git::Raw::Branch-E<gt>create()>.

=cut

sub branch { return Git::Raw::Branch -> create(@_) }

=head2 branches( )

Retrieve a list of L<Git::Raw::Branch> objects.

=cut

sub branches {
	my $self = shift;
	my $branches;

	Git::Raw::Branch -> foreach($self, sub {
		push @$branches, shift; 0
	});

	return $branches;
}

=head2 commit( $msg, $author, $committer, \@parents, $tree )

Create a new L<Git::Raw::Commit>. Shortcut for C<Git::Raw::Commit-E<gt>create()>.

=cut

sub commit { return Git::Raw::Commit -> create(@_) }

=head2 tag( $name, $msg, $tagger, $target )

Create a new L<Git::Raw::Tag>. Shortcut for C<Git::Raw::Tag-E<gt>create()>.

=cut

sub tag { return Git::Raw::Tag -> create(@_) }

=head2 tags( )

Retrieve a list of L<Git::Raw::Tag> objects.

=cut

sub tags {
	my $self = shift;
	my $tags;

	Git::Raw::Tag -> foreach($self, sub {
		push @$tags, shift; 0
	});

	return $tags;
}

=head2 stash( $stasher, $msg )

Save the local modifications to a new stash. Shortcut for C<Git::Raw::Stash-E<gt>save()>.

=cut

sub stash { return Git::Raw::Stash -> save(@_) }

=head2 remotes( )

Retrieve a list of L<Git::Raw::Remote> objects.

=head2 walker( )

Create a new L<Git::Raw::Walker>. Shortcut for C<Git::Raw::Walker-E<gt>create()>.

=cut

sub walker { return Git::Raw::Walker -> create(@_) }

=head2 path( )

Retrieve the complete path of the repository.

=head2 workdir( )

Retrieve the working directory of the repository.

=head2 is_empty( )

Check if the repository is empty.

=head2 is_bare( )

Check if the repository is bare.

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
