package Git::Raw::Commit;

use strict;
use warnings;
use overload
	'""'       => sub { return $_[0] -> id },
	'eq'       => \&_cmp,
	'ne'       => sub { !&_cmp(@_) };

use Git::Raw;

=head1 NAME

Git::Raw::Commit - Git commit class

=head1 SYNOPSIS

    use Git::Raw;

    # open the Git repository at $path
    my $repo = Git::Raw::Repository -> open($path);

    # add a file to the repository default index
    my $index = $repo -> index;
    $index -> add('test');
    $index -> write;

    # create a new tree out of the repository index
    my $tree_id = $index -> write_tree;
    my $tree    = $repo -> lookup($tree_id);

    # retrieve user's name and email from the Git configuration
    my $config = $repo -> config;
    my $name   = $config -> str('user.name');
    my $email  = $config -> str('user.email');

    # create a new Git signature
    my $me = Git::Raw::Signature -> now($name, $email);

    # create a new commit out of the above tree, with the repository HEAD as
    # parent
    my $commit = $repo -> commit(
      'some commit', $me, $me, [ $repo -> head -> target ], $tree
    );

=head1 DESCRIPTION

A C<Git::Raw::Commit> represents a Git commit.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 create( $repo, $msg, $author, $committer, [@parents], $tree [, $update_ref ] )

Create a new commit given a message, two L<Git::Raw::Signature> (one is the
commit author and the other the committer), a list of parent commits and a
L<Git::Raw::Tree>. If C<$update_ref> is provided and is defined, the reference
with the corresponding name is automatically updated or created. If
C<$update_ref> is C<undef>, no reference is updated.  If C<$update_ref> is not
provided, "HEAD" is updated.

=cut

sub amend {
	my $baseline = shift;
	Git::Raw::Commit -> create(
		$baseline -> owner(),
		$baseline -> message,
		$baseline -> author,
		$baseline -> committer,
		@_
	);
}

=head2 amend( $baseline, [@parents], $tree [, $update_ref ] )

Create a new commit using C<$baseline> as a template for the message, author
and committer. This method is useful for rewriting a commit, by replacing its
parents and trees. See C<Git::Raw::Commit-E<gt>create()>

=head2 lookup( $repo, $id )

Retrieve the commit corresponding to C<$id>. This function is pretty much the
same as C<$repo-E<gt>lookup($id)> except that it only returns commits. If the
commit doesn't exist, this function wil return C<undef>.

=head2 owner( )

Retrieve the L<Git::Raw::Repository> owning the commit.

=head2 id( )

Retrieve the id of the commit, as string.

=head2 message( )

Retrieve the message of the commit.

=head2 summary( )

Retrieve the summary of the commit.

=head2 author( )

Retrieve the L<Git::Raw::Signature> representing the author of the commit.

=head2 committer( )

Retrieve the L<Git::Raw::Signature> representing the committer.

=head2 time( )

Retrieve the committer time of the commit.

=head2 offset( )

Retrieve the committer time offset (in minutes) of the commit.

=head2 tree( )

Retrieve the L<Git::Raw::Tree> the commit points to.

=head2 parents( )

Retrieve the list of parents of the commit.

=head2 merge( $commit, [ \%merge_opts ])

Merge C<$commit> into this commit. See C<Git::Raw::Repository-E<gt>merge()>
for valid C<%merge_opts> values. Returns a L<Git::Raw::Index> object
containing the merge result.

=head2 ancestor( $gen )

Retrieve the L<Git::Raw::Commit> object that is the C<$gen>'th generation
ancestor of this commit, following only the first parents.

=head2 as_email( [\%opts] )

Retrieve the patch e-mail associated with the commit. Valid fields for the
C<%opts> has are:

=over 4

=item * "patch_no"

The patch number for this commit.

=item * "total_patches"

Total number of patches.

=item * "flags"

E-mail generation flags. Valid fields for this hash include:

=over 8

=item * "exclude_subject_patch_marker"

Don't insert C<"[PATCH]"> in the subject header.

=back

=back

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

sub _cmp {
	if (defined($_[0]) && defined ($_[1])) {
		my ($a, $b);

		$a = $_[0] -> id;

		if (ref($_[1])) {
			if (!$_[1] -> can('id')) {
				return 0;
			}
			$b = $_[1] -> id;
		} else {
			$b = "$_[1]";
		}

		return $a eq $b;
	}

	return 0;
}

1; # End of Git::Raw::Commit
