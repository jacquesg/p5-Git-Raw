package Git::Raw::Blame::Hunk;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Blame::Hunk - Git blame hunk class

=head1 DESCRIPTION

A L<Git::Raw::Blame::Hunk> represents a hunk in the blame information of a file.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 lines_in_hunk( )

Retrieve the number of lines in the hunk.

=head2 final_commit_id( )

Retrieve the id of the commit where this line was last changed as a string.

=head2 final_start_line_number( )

Retrieve the 1-based line number where this hunk begins in the final version
of the file.

=head2 orig_commit_id( )

Retrieve the id of the commit where this hunk was found. This will usually
be the same as C<"final_commit_id">.

=head2 orig_start_line_number( )

Retrieve the 1-based line number where this hunk begins in the file named by
C<"orig_path"> in the commit specified by C<"orig_commit_id">.

=head2 orig_path( )

Retrieve the path to the file where this hunk originated.

=head2 boundary( )

If the hunk has been tracked to a boundary commit.

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

1; # End of Git::Raw::Blame::Hunk
