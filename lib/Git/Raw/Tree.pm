package Git::Raw::Tree;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Tree - Git tree class

=head1 DESCRIPTION

A C<Git::Raw::Tree> represents a Git tree.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 lookup( $repo, $id )

Retrieve the tree corresponding to C$id>. This function is pretty much the same
as C<$repo-E<gt>lookup($id)> except that it only returns trees.

=head2 id( )

Retrieve the id of the tree, as string.

=head2 entries( )

Retrieve a list of L<Git::Raw::TreeEntry> objects.

=head2 entry_byname( $name )

Retrieve a L<Git::Raw::TreeEntry> object by name.

=head2 entry_bypath( $path )

Retrieve a L<Git::Raw::TreeEntry> object by path.

=head2 diff( [\%opts] )

Compute the L<Git::Raw::Diff> between two trees. Valid fields for the C<%opts>
hash are:

=over 4

=item * "tree"

If provided, the diff is computed against C<"tree">. The default is the repo's
working directory.

=item * "flags"

Flags for generating the diff. Valid values include:

=over 8

=item * "reverse"

Reverse the sides of the diff.

=item * "include_ignored"

Include ignored files in the diff.

=item * "recurse_ignored_dirs"

Even if L<"include_ignored"> is specified, an entire ignored directory
will be marked with only a single entry in the diff. This flag adds all files
under the directory as ignored entries, too.

=item * "include_untracked"

Include untracked files in the diff.

=item * "recurse_untracked_dirs"

Even if L<"include_untracked"> is specified, an entire untracked directory
will be marked with only a single entry in the diff (core git behaviour).
This flag adds all files under untracked directories as untracked entries, too.

=item * "ignore_filemode"

Ignore file mode changes.

=item * "ignore_submodules"

Treat all submodules as unmodified.

=item * "ignore_whitespace"

Ignore all whitespace.

=item * "ignore_whitespace_change"

Ignore changes in amount of whitespace.

=item * "ignore_whitespace_eol"

Ignore whitespace at end of line.

=item * "patience"

Use the L<"patience diff"> algorithm.

=item * "minimal"

Take extra time to find minimal diff.

=back

=item * "prefix"

=over 8

=item * "a"

The virtual L<"directory"> to prefix to old file names in hunk headers.
(Default is L"a".)

=item * "b"

The virtual L<"directory"> to prefix to new file names in hunk headers.
(Default is L"b".)

=back

=item * "context_lines"

The number of unchanged lines that define the boundary of a hunk (and
to display before and after)

=item * "interhunk_lines"

The maximum number of unchanged lines between hunk boundaries before
the hunks will be merged into a one.

=item * "paths"

A list of paths to constrain diff.

=back

=cut

=head2 is_tree( )

Returns true.

=cut

=head2 is_blob( )

Returns false.

=cut

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Tree
