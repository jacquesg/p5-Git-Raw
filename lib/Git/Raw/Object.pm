package Git::Raw::Object;

use strict;
use warnings;
use Carp;

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Git::Raw::Object::constant not defined" if $constname eq '_constant';
    my ($error, $val) = _constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

use Git::Raw;

=head1 NAME

Git::Raw::Object - Git object

=head1 DESCRIPTION

L<Git::Raw::Object> provides a namespace for object constants.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 lookup( $id )

Retrieve the object corresponding to C<$id>. Returns a L<Git::Raw::Object>.

=head2 type( )

Get the object type.

=head1 CONSTANTS

=head2 ANY

Any

=head2 BAD

Invalid

=head2 COMMIT

Commit

=head2 TREE

Tree (directory listing)

=head2 BLOB

File revision (blob)

=head2 TAG

Annotated tag

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Object
