package Git::Raw::Repository;

use strict;
use warnings;

=head1 NAME

Git::Raw::Repository - libgit2 repository class

=head1 DESCRIPTION

A C<Git::Raw::Repository> represents a Git repository.

=head1 METHODS

=head2 init( $path, $is_bare )

Initialize a new repository at C<$path>.

=head2 open( $path )

Open the repository at C<$path>.

=head2 config( )

Retrieve the default L<Git::Raw::Config> of the repository.

=head2 index( )

Retrieve the default L<Git::Raw::Index> of the repository.

=head2 head( )

Retrieve the HEAD of the repository. This function may return a L<Git::Raw::Blob>,
a L<Git::Raw::Commit>, a L<Git::Raw::Tag> or a L<Git::Raw::Tree>.

=head2 lookup( $id )

Retrieve the object corresponding to the given id. This function may return a
L<Git::Raw::Blob>, a L<Git::Raw::Commit>, a L<Git::Raw::Tag> or a
L<Git::Raw::Tree>.

=head2 commit( $msg, $author, $committer, [@parents], $tree )

Create a new L<Git::Raw::Commit> given a message, an author and committer
(L<Git::Raw::Signature>), a list of parents (L<Git::Raw::Commit>) and a tree
(L<Git::Raw::Tree>).

=head2 tag( $name, $msg, $tagger, $target )

Create a new L<Git::Raw::Tag> given a name, a message, a $tagger
(L<Git::Raw::Signature>) and a $target. The target may be a L<Git::Raw::Blob>,
a L<Git::Raw::Commit>, a L<Git::Raw::Tag> or a L<Git::Raw::Tree>.

=head2 walker( )

Create a new L<Git::Raw::Walker> to iterate over repository's revisions.

=head2 path( )

Retrieve the complete path of the repository.

=head2 workdir( )

Retrieve the working directory of the repository.

=head2 is_empty( )

Tell whether the repository is empty or not.

=head2 is_bare( )

Tell whether the repository is bare or not.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Repository
