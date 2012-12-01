package Git::Raw::Config;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Config - Git config class

=head1 DESCRIPTION

A C<Git::Raw::Config> represents a Git configuration file.

=head1 METHODS

=head2 bool( $name [, $value ] )

Retrieve the value of the C<$name> configuration field of type boolean. If
C<$value> is passed, the value of the configration will be updated and
returned.

=head2 int( $name [, $value ] )

Retrieve the value of the C<$name> configuration field of type integer. If
C<$value> is passed, the value of the configration will be updated and
returned.

=head2 str( $name [, $value ] )

Retrieve the value of the C<$name> configuration field of type string. If
C<$value> is passed, the value of the configration will be updated and
returned.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Config
