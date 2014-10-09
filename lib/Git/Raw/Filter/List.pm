package Git::Raw::Filter::List;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Filter::List - Git filter list class

=head1 DESCRIPTION

A C<Git::Raw::Filter::List> represents a Git filter list.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 load( $repo, $path, $mode )

Load the filter list for a given C<$path>. See
C<Git::Raw::Filter::Source-E<gt>mode()> for possible value of C<$mode>.

=head2 apply_to_blob( $blob )

Apply the filter list to C<$blob>. Returns a string containing the filtered
content.

=head2 apply_to_data( $data )

Apply the filter list to C<$data>. Returns a string containing the filtered
content.

=head2 apply_to_file( $path )

Apply the filter list to the file specified by C<$path>. Returns a string
containing the filtered content.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Filter::List
