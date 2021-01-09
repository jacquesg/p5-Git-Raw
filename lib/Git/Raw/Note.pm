package Git::Raw::Note;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Note - Git note class

=head1 DESCRIPTION

A L<Git::Raw::Note> represents a git note.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 create( $repo, $commitish, $content, [$refname, $force] )

Add a note for an object. C<$refname> is the canonical name of the note
reference to use (defaults to C<"refs/notes/commits">). Returns a
L<Git::Raw::Note> object.

=head2 read( $repo, $commitish, [$refname] )

Read the note for C<$commitish>. Returns a L<Git::Raw::Note> object if a note
is associated with C<$commitish>, otherwise C<undef>.

=head2 remove( $repo, $commitish, [$refname] )

Remove the note from C<$commitish>.

=head2 id( )

Retrieve the note's id as a string.

=head2 message( )

Retrieve the note's message.

=head2 author( )

Retrieve the L<Git::Raw::Signature> representing the author of the note.

=head2 committer( )

Retrieve the L<Git::Raw::Signature> representing the committer.

=head2 default_ref( $repo )

Get the default notes reference for the repository. Returns a
L<Git::Raw::Reference> object if the reference exists otherwise C<undef>.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Note
