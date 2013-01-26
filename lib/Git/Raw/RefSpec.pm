package Git::Raw::RefSpec;

use strict;
use warnings;

=head1 NAME

Git::Raw::RefSpec - Git refspec class

=head1 DESCRIPTION

A C<Git::Raw::RefSpec> represents a Git refspec.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 dst( )

Retrieve the destination specifier of the refspec.

=head2 src( )

Retrieve the source specifier of the refspec.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::RefSpec
