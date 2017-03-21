package Git::Raw::Odb;

use strict;
use warnings;

use Git::Raw;
use Git::Raw::Odb::Backend;

=head1 NAME

Git::Raw::Odb - Git object database class

=head1 DESCRIPTION

A L<Git::Raw::Odb> represents a git object database.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 new( )

Create a new object database.

=head2 open( $directory )

Create a new object database and automatically add the two default backends.
C<$directory> should be the path to the 'objects' directory.

=head2 backend_count( )

Get the number of ODB backend objects.

=head2 refresh( )

Refresh the object database to load newly added files. If the object databases
have changed on disk while the library is running, this function will force a
reload of the underlying indexes. Use this method when you're confident that an
external application has tampered with the ODB.

=head2 foreach( $repo, $callback )

Run C<$callback> for every object available in the database. The callback receives
a single argument, the OID of the object. A non-zero return value will terminate
the loop.

=head2 add_backend( $backend, $priority )

Add a custom backend to the ODB. The backends are checked in relative ordering,
based on the value of C<$priority>.

=head2 add_alternate( $backend, $priority )

Add an alternate custom backend to the ODB. Alternate backends are always
checked for objects after all the main backends have been exhausted. Writing is
disabled on alternate backends.

=head2 read( $id )

Read an object from the database. Returns a L<Git::Raw::Odb::Object>.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Odb
