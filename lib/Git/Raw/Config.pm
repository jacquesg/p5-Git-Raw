package Git::Raw::Config;

use strict;
use warnings;

=head1 NAME

Git::Raw::Config - libgit2 config class

=head1 DESCRIPTION

A C<Git::Raw::Config> represents a Git configuration file.

=head1 METHODS

=head2 get_str( $name )

Retrieve the value of the C<$name> configuration field of type string.

=head2 set_str( $name, $value )

Set the value of the C<$name> configuration field of type string.

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
