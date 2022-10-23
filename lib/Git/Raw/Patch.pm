package Git::Raw::Patch;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Patch - Git patch class

=head1 DESCRIPTION

A L<Git::Raw::Patch> represents all the text diffs for a delta.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 buffer( )

Get the content of a patch as a single diff text.

=head2 hunk_count( )

Get the number of hunks in the patch.

=head2 hunks( [$index] )

Returns a list of L<Git::Raw::Diff::Hunk> objects. If C<$index> is specified
only the hunk at the specified index will be returned.

=head2 line_stats( )

Get line counts of each type in the patch. Returns a hash with entries
C<"context">, C<"additions"> and C<"deletions">.

=head2 delta( )

Get the delta associated with the patch. Returns a L<Git::Raw::Diff::Delta>
object.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

Jacques Germishuys <jacquesg@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Patch
