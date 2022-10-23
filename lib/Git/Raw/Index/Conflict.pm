package Git::Raw::Index::Conflict;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Index::Conflict - Git index conflict class

=head1 DESCRIPTION

A L<Git::Raw::Index::Conflict> represents a conflict in a Git repository index.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 ours( )

Retrieve our side of the conflict. Returns a L<Git::Raw::Index::Entry> object,
or C<undef> if not applicable.

=head2 ancestor( )

Retrieve the ancestor side of the conflict. Returns a L<Git::Raw::Index::Entry>
object, or C<undef> if not applicable.

=head2 theirs( )

Retrieve their side of the conflict. Returns a L<Git::Raw::Index::Entry> object,
or C<undef> if not applicable.

=head1 AUTHOR

Jacques Germishuys <jacquesg@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Index::Conflict
