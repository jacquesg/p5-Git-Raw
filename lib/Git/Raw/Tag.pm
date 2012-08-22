package Git::Raw::Tag;

use strict;
use warnings;

=head1 NAME

Git::Raw::Tag - Git tag class

=head1 DESCRIPTION

A C<Git::Raw::Tag> represents a Git tag.

=head1 METHODS

=head2 create( $repo, $name, $msg, $tagger, $target )

Create a new L<Git::Raw::Tag> given a name, a message, a L<Git::Raw::Signature>
representing the tagger and a target. The target may be a L<Git::Raw::Blob>,
a L<Git::Raw::Commit>, a L<Git::Raw::Tag> or a L<Git::Raw::Tree>.

=head2 lookup( $repo, $id )

Retrieve the tag corresponding to the given id. This function is pretty much
the same as C<$repo -> lookup($id)> except that it only returns tags.

=head2 delete( $repo, $name )

Delete the tag with the given name.

=head2 id( )

Retrieve the id of the tag, as string.

=head2 name( )

Retrieve the name of the tag.

=head2 message( )

Retrieve the message of the tag.

=head2 tagger( )

Retrieve the C<Git::Raw::Signature> representing the tag's tagger.

=head2 target( )

Retrieve the target of the tag. This function may return a L<Git::Raw::Blob>,
a L<Git::Raw::Commit>, a L<Git::Raw::Tag> or a L<Git::Raw::Tree>.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Tag
