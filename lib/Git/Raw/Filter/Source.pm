package Git::Raw::Filter::Source;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Filter::Source - Git filter source class

=head1 DESCRIPTION

A C<Git::Raw::Filter::Source> represents a Git filter source.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 id( )

Retrieve the id of the filter source as a string.

=head2 path( )

Retrieve the path that the filter source data is coming from.

=head2 file_mode( )

Retrieve the file mode of the source file, as an integer. If the mode
is unknown, this will return 0.

=head2 mode( )

Retrieve the mode to be applied. Possible values include:

=over 4

=item * "to_worktree"

The file is being exported from the Git object database to the working
directory.

=item * "to_odb"

The file is being import from the working directory to the Git object
database.

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

1; # End of Git::Raw::Filter::Source
