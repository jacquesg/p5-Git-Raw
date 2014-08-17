package Git::Raw::PathSpec::MatchList;

use strict;
use warnings;

=head1 NAME

Git::Raw::PathSpec::MatchList - Git pathspec matchlist class

=head1 DESCRIPTION

A L<Git::Raw::PathSpec::MatchList> represents a Git pathspec list of matches.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 count( )

Retrieve the number of succesful match entries.

=head2 entries( )

Retrieve the sucessful match entries. Returns a list of strings.

=head2 failed_count( )

Retrieve the number of failed entries.

=head2 failed_entries( )

Retrieve the failed entries. Returns a list of strings.

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

1; # End of Git::Raw::PathSpec::MatchList
