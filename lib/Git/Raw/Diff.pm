package Git::Raw::Diff;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Diff - Git diff class

=head1 DESCRIPTION

A L<Git::Raw::Diff> represents the diff between two entities.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 new( $buffer )

Create a diff from the content of a git patch.

=head2 patchid( )

Calculate the patch id.

=head2 merge( $from )

Merge the given diff with the L<Git::Raw::Diff> C<$from>.

=head2 buffer( $format )

Get the content of a diff as text. See C<Git::Raw::Diff-E<gt>print()> for valid
C<$format> values.

=head2 delta_count( )

Query how many diff records there are in the diff.

=head2 deltas( [$index] )

Returns a list of L<Git::Raw::Diff::Delta> objects. If C<$index> is specified
only the delta at the specified index will be returned.

=head2 find_similar( [\%options] )

Transform the diff marking file renames, copies, etc.  Valid fields for the
C<%options> hash include:

=over 4

=item * "flags"

Flags for finding similar files. Valid values include:

=over 8

=item * "renames"

Look for renames.

=item * "renames_from_rewrites"

Consider old side of modifies files for renames.

=item * "copies"

Look for copies.

=item * "copies_from_unmodified"

Consider unmodified files as copy sources.

=item * "rewrites"

Mark significant rewrites for split.

=item * "break_rewrites"

Actually split large rewrites into delete/add pairs.

=item * "untracked"

Find renames/copies for untracked items in the working directory.

=item * "all"

Turn on all finding features.

=item * "ignore_leading_whitespace"

Measure similarity ignoring leading whitespace (default).

=item * "ignore_whitespace"

Measure similarity ignoring all whitespace.

=item * "dont_ignore_whitespace"

Measure similarity including all data.

=item * "exact_match_only"

Measure similarity only by comparing SHAs (fast and cheap).

=item * "break_rewrites_for_renames_only"

Do not break rewrites unless they contribute to a rename.

=item * "remove_unmodified"

Remove any unmodified deltas after C<find_similar> is done.

=back

=item * "rename_threshold"

Similarity to consider a file renamed (default 50).

=item * "rename_from_rewrite_threshold"

Similarity of modified to be eligible rename source (default 50).

=item * "copy_threshold"

Similarity to consider a file a copy (default 50).

=item * "break_rewrite_threshold"

Similarity to split modify into delete/add pair (default 60).

=item * "rename_limit"

Maximum similarity sources to examine for a file (default 200).

=back

=head2 patches( )

Return a list of L<Git::Raw::Patch> objects for the diff.

=head2 print( $format, $callback )

Generate text output from the diff object. The C<$callback> will be called for
each line of the diff with two arguments: the first one represents the type of
the patch line (C<"ctx"> for context lines, C<"add"> for additions, C<"del">
for deletions, C<"file"> for file headers, C<"hunk"> for hunk headers, C<"bin">
for binary data or C<"noeol"> if both files have no LF at end) and the second
argument contains the content of the patch line.

The C<$format> can be one of the following:

=over 4

=item * "patch"

Full git diff.

=item * "patch_header"

Only the file headers of the diff.

=item * "raw"

Like C<git diff --raw>.

=item * "name_only"

Like C<git diff --name-only>.

=item * "name_status"

Like C<git diff --name-status>.

=back

=head2 stats( )

Accumlated diff statistics for all patches in the diff. Returns a
L<Git::Raw::Diff::Stats> object.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

Jacques Germishuys <jacquesg@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Diff
