package Git::Raw::Packbuilder;

use strict;
use warnings;
use Carp;

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Git::Raw::Packbuilder::constant not defined" if $constname eq '_constant';
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

Git::Raw::Packbuilder - Git packbuilder class

=head1 SYNOPSIS

	use File::Spec::Functions qw(catfile);
	use Git::Raw;

	my $pb = Git::Raw::Packbuilder -> new($repo);
	$pb -> insert($commit);
	$pb -> write(catfile($repo -> path, 'objects', 'pack'));

=head1 DESCRIPTION

A L<Git::Raw::Packbuilder> represents a git packfile builder.

=head1 CONSTANTS

=head2 ADDING_OBJECTS

Objects are being added to the object database.

=head2 DELTAFICATION

Deltas are calculated/resolved.

=head1 METHODS

=head2 new( $repo )

Create a new packbuilder.

=head2 insert( $object, [$recursive = 1] )

Insert an object and by default its referenced objects. C<$object> may be
a L<Git::Raw::Commit>, L<Git::Raw::Tree>, L<Git::Raw::Blob> or L<Git::Raw::Walker>.

=head2 write( $path )

Write the new pack and corresponding index file to C<$path>.

=head2 written( )

Retrieve the number of objects the packbuilder has already written out.

=head2 object_count( )

Retrieve the total number of objects the packbuilder will write out.

=head2 threads( $count )

Set number of threads to spawn. By default libgit2 won't spawn any threads at all;
when set to 0, libgit2 will autodetect the number of CPUs.

=head2 hash( )

Get the packfile's hash. A packfile's name is derived from the sorted hashing of all
object names. This is only correct after the packfile has been written.

=head2 callbacks( \%callbacks )

Set the callbacks for the packbuilder. See L<C<CALLBACKS>>.

=head1 CALLBACKS

=head2 pack_progress

During the packing of new data, this will regularly be called with the progress
of the pack operation. Be aware that this is called inline with pack
building operations, so performance may be affected. The callback receives the
following integers:
C<$stage>, C<$current> and C<$total>.

=head2 transfer_progress

This will be regularly called with the current count of progress done by the
indexer. The callback receives the following integers: C<$total_objects>,
C<$received_objects>, C<$local_objects>, C<$total_deltas>, C<$indexed_deltas>
and C<$received_bytes>.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Packbuilder
