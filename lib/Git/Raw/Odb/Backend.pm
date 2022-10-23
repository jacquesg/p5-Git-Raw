package Git::Raw::Odb::Backend;

use strict;
use warnings;

use Git::Raw;
use Git::Raw::Odb::Backend::Loose;
use Git::Raw::Odb::Backend::OnePack;
use Git::Raw::Odb::Backend::Pack;

=head1 NAME

Git::Raw::Odb::Backend - Git object database backend class

=head1 DESCRIPTION

A L<Git::Raw::Odb::Backend> represents a git object database backend.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 AUTHOR

Jacques Germishuys <jacquesg@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Odb::Backend
