package Git::Raw::Diff;

use strict;
use warnings;

=head1 NAME

Git::Raw::Diff - Git diff class

=head1 DESCRIPTION

A C<Git::Raw::Diff> represents the diff between two entities.

=head1 METHODS

=head2 merge( $from )

Merge the given diff with the C<Git::Raw::Diff> C<$from>.

=head2 patch( $callback )

Generate text output from a C<Git::Raw::Diff>. The C<$callback> will be called
for each line of the diff, with two arguments: the first one represents the type
of patch line (either C<"ctx"> for context lines, C<"add"> for additions,
C<"del"> for deletions, C<"file"> for file headers, C<"hunk"> for hunk headers
and C<"bin"> for binary data) and the second argument contains the actual patch
line.

=head2 compact( $callback )

Generate compact text output from a C<Git::Raw::Diff>. Differently from
C<patch()>, this function only passes names and status of changed files.

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
