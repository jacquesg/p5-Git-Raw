package Git::Raw::Diff;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Diff - Git diff class

=head1 DESCRIPTION

A C<Git::Raw::Diff> represents the diff between two entities.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 merge( $from )

Merge the given diff with the C<Git::Raw::Diff> C<$from>.

=head2 delta_count( )

Query how many diff records there are in the diff.

=head2 patches( )

Return a list of C<Git::Raw::Patch> objects for the diff.

=head2 print( $format, $callback )

Generate text output from the diff object. The C<$callback> will be called for
each line of the diff with two arguments: the first one represents the type of
the patch line (C<"ctx"> for context lines, C<"add"> for additions, C<"del">
for deletions, C<"file"> for file headers, C<"hunk"> for hunk headers or
C<"bin"> for binary data) and the second argument contains the content of the
patch line.

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

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Diff
