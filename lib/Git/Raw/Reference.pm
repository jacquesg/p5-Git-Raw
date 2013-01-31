package Git::Raw::Reference;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Reference - Git reference class

=head1 DESCRIPTION

A C<Git::Raw::Reference> represents a Git reference.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 lookup( $name, $repo )

Retrieve the reference with name C<$name> in C<$repo>.

=head2 delete( )

Delete the reference. The L<Git::Raw::Reference> object must not be accessed
afterwards.

=head2 name( )

Retrieve the name of the reference.

=head2 type( )

Retrieve the type of the reference. Can be either C<"direct"> or C<"symbolic">.

=head2 target( )

Retrieve the target of the reference. This function returns either an object
(L<Git::Raw::Blob>, L<Git::Raw::Commit>, L<Git::Raw::Tag> or L<Git::Raw::Tree>)
for direct references, or another reference for symbolic references.

=head2 owner( )

Retrieve the L<Git::Raw::Repository> owning the reference.

=head2 is_branch( )

Check if the reference is a branch.

=head2 is_packed( )

Check if the reference is packed.

=head2 is_remote( )

Check if the reference is remote.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Reference
