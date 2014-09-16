package Git::Raw::Tree;

use strict;
use warnings;
use overload
	'""'       => sub { return $_[0] -> id },
	'eq'       => \&_cmp,
	'ne'       => sub { !&_cmp(@_) };

use Git::Raw;

=head1 NAME

Git::Raw::Tree - Git tree class

=head1 DESCRIPTION

A L<Git::Raw::Tree> represents a Git tree.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 lookup( $repo, $id )

Retrieve the tree corresponding to C<$id>. This function is pretty much the same
as C<$repo-E<gt>lookup($id)> except that it only returns trees. If the tree
doesn't exist, this function wil return C<undef>.

=head2 owner( )

Retrieve the L<Git::Raw::Repository> owning the tree.

=head2 id( )

Retrieve the id of the tree, as string.

=head2 entries( )

Retrieve a list of L<Git::Raw::Tree::Entry> objects.

=head2 entry_byname( $name )

Retrieve a L<Git::Raw::Tree::Entry> object by name. If the entry cannot be found,
this function will return C<undef>.

=head2 entry_bypath( $path )

Retrieve a L<Git::Raw::Tree::Entry> object by path. If the entry cannot be found,
this function will return C<undef>.

=head2 merge( $ancestor, $theirs, [\%merge_opts] )

Merge C<$theirs> into this tree. C<$ancestor> and C<$theirs> should be
L<Git::Raw::Tree> objects.  See C<Git::Raw::Repository-E<gt>merge()> for valid
C<%merge_opts> values. Returns a L<Git::Raw::Index> object containing the
merge result.

=head2 diff( [\%diff_opts] )

Compute the L<Git::Raw::Diff> between two trees. See
C<Git::Raw::Repository-E<gt>diff()> for valid C<%diff_opts> values.

=head2 is_tree( )

Returns true.

=head2 is_blob( )

Returns false.

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

1; # End of Git::Raw::Tree
