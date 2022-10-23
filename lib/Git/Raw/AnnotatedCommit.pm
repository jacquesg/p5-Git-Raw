package Git::Raw::AnnotatedCommit;

use strict;
use warnings;
use overload
	'""'       => sub { return $_[0] -> id },
	fallback   => 1;

use Git::Raw;

=head1 NAME

Git::Raw::AnnotatedCommit - Git note class

=head1 DESCRIPTION

A L<Git::Raw::AnnotatedCommit> represents a git annotated commit.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 id( )

Retrieve the id of the commit as a string.

=head2 lookup( $repo, $id )

Create a L<Git::Raw::Annotated::Commit> from the given commit C<$id>.

=head1 AUTHOR

Jacques Germishuys <jacquesg@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::AnnotatedCommit
