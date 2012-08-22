package Git::Raw::Commit;

use strict;
use warnings;

=head1 NAME

Git::Raw::Commit - Git commit class

=head1 DESCRIPTION

A C<Git::Raw::Commit> represents a Git commit.

=head1 METHODS

=head2 lookup( $repo, $id )

Retrieve the commit corresponding to the given id. This function is pretty much
the same as C<$repo -> lookup($id)> except that it only returns commits.

=head2 id( )

Retrieve the id of the commit, as string.

=head2 message( )

Retrieve the commit's message.

=head2 author( )

Retrieve the C<Git::Raw::Signature> representing the commit's author.

=head2 committer( )

Retrieve the C<Git::Raw::Signature> representing the commit's committer.

=head2 time( )

Retrieve the committer time of a commit.

=head2 offset( )

Retrieve the committer time offset (in minutes) of a commit.

=head2 tree( )

Retrieve the L<Git::Raw::Tree> a commit points to.

=head2 parents( )

Retrieve the list of parents of the commit. The parents are C<Git::Raw::Commit>
too,

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Commit
