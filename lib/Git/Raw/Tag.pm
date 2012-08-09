package Git::Raw::Tag;

use strict;
use warnings;

=head1 NAME

Git::Raw::Tag - Git tag class

=head1 DESCRIPTION

A C<Git::Raw::Tag> represents a Git tag.

=head1 METHODS

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
