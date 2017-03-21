package Git::Raw::Odb::Object;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Odb::Object - Git object database backend class

=head1 DESCRIPTION

A L<Git::Raw::Odb::Object> represents a git object database object.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 METHODS

=head2 id( )

Retrieve the id of the object, as a string.

=head2 type( )

Get the object type.

=head2 size( )

Get the object size.

=head2 data( )

Get the uncompressed, raw data without the leading header.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Odb::Object
