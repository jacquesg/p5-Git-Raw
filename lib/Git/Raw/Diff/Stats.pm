package Git::Raw::Diff::Stats;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Diff::Stats - Git diff statistics class

=head1 DESCRIPTION

A L<Git::Raw::Diff::Stats> represents diff statistics.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 deletions( )

Total number of deletions in the diff.

=head2 insertions( )

Total number of insertions in the diff.

=head2 files_changed( )

Total number of files changed in the diff.

=head2 buffer( [\%options] )

=over 4

=item * "flags"

Flags for generating the diff stats buffer. Valid values include:

=over 8

=item * "full"

Full statistics similar to core git's C<--stat>.

=item * "short"

Short statistics similar to core git's C<--shortstat>.

=item * "number"

Number statistics similar to core git's C<--numstat>.

=item * "summary"

Include extended header information such as creations, renames and mode changes.

=back

=back

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Diff::Stats
