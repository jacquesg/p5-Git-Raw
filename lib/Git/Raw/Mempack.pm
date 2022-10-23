package Git::Raw::Mempack;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Mempack - Git in-memory object database class

=head1 SYNOPSIS

	use Git::Raw;

	my $mempack = Git::Raw::Mempack -> new;
	my $odb = $repo -> odb;
	$odb -> add_backend($mempack, 99);

	# Create blobs, trees and commits...

	# Index the packfile and persist
	my $odb_path = catfile($repo -> path, 'objects');
	my $tp = Git::Raw::TransferProgress -> new;
	my $indexer = Git::Raw::Indexer -> new($odb_path, $odb);

	my $pack = $mempack -> dump($repo);
	$indexer -> append($pack, $tp);
	$indexer -> commit($tp);


=head1 DESCRIPTION

A L<Git::Raw::Mempack> represents a git in-memory object database.

=head1 METHODS

=head2 new( )

Create a new mempack backend.

=head2 dump( $repo )

Dump all the queued in-memory writes to a packfile. Returns the contents of the
packfile. It is the caller's responsibility to ensure that the generated
packfile is available to the repository.

=head2 reset( )

Reset the mempack by clearing all the queued objects.

=head1 AUTHOR

Jacques Germishuys <jacquesg@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Mempack
