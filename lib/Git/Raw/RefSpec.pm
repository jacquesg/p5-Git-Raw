package Git::Raw::RefSpec;

use strict;
use warnings;
use overload
	'""'       => sub { return $_[0] -> string },
	fallback   => 1;

=head1 NAME

Git::Raw::RefSpec - Git refspec class

=head1 DESCRIPTION

A L<Git::Raw::RefSpec> represents a Git refspec.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 parse( $input, $is_fetch )

Parse the refspec string C<$input>.

=head2 dst( )

Retrieve the destination specifier of the refspec.

=head2 dst_matches( $name )

Check if the refspec's destination descriptor matches the reference named
by C<$name>.

=head2 src( )

Retrieve the source specifier of the refspec.

=head2 src_matches( $name )

Check if the refspec's source descriptor matches the reference named
by C<$name>.

=head2 string( )

Get the refspec's string.

=head2 direction( )

Get the refspec's direction. It is either C<"fetch"> or C<"push">.

=head2 transform( $name )

Transform C<$name> to its target following the refspec's rules.

=head2 rtransform( $name )

Transform the target reference C<$name> to its source reference name following
the refspec's rules.

=head2 is_force( )

Get the refspec's force update setting.

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

1; # End of Git::Raw::RefSpec
