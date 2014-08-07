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

=head2 create( $name, $repo, $object [, $force] )

Creates and returns a new direct reference named C<$name> in C<$repo> pointing
to C<$object>. C<$object> can be a L<Git::Raw::Blob>, L<Git::Raw::Commit>,
or a L<Git::Raw::Tree> object.  If C<$force> is a truthy value, any existing
reference is overwritten.  If C<$force> is falsy (the default) and a reference
named C<$name> already exists, an error is thrown.

=head2 delete( )

Delete the reference. The L<Git::Raw::Reference> object must not be accessed
afterwards.

=head2 name( )

Retrieve the name of the reference.

=head2 shorthand( )

Get the reference's short name. This will transform the reference name into a
"human-readable" version. If no shortname is appropriate, it will return the
full name.

=head2 type( )

Retrieve the type of the reference. Can be either C<"direct"> or C<"symbolic">.

=head2 target( [$new_target] )

Retrieve the target of the reference. If the C<$new_target> parameter of type
L<Git::Raw::Reference> is passed, the reference will be changed to point to it.

Note that updating the target will invalidate all existing handles to the
reference.

This function returns either an object (L<Git::Raw::Blob>, L<Git::Raw::Commit>,
L<Git::Raw::Tag> or L<Git::Raw::Tree>) for direct references, or another
reference for symbolic references.

=head2 peel( $type )

Recursively peel the reference until an object of the specified C<$type> is
found. Valid values for C<$type> include: C<"commit">, C<"tree"> or C<"tag">.

=head2 reflog( )

Retrieve the L<Git::Raw::Reflog> of the reference. Shortcut for
C<Git::Raw::Reflog-E<gt>open()>.

=cut

sub reflog { return Git::Raw::Reflog -> open (shift); }

=head2 owner( )

Retrieve the L<Git::Raw::Repository> owning the reference.

=head2 is_branch( )

Check if the reference is a branch.

=head2 is_remote( )

Check if the reference is remote.

=head2 is_tag( )

Check if the reference lives in the C<refsE<sol>tags> namespace.

=head2 is_note( )

Check if the reference lives in the C<refsE<sol>notes> namespace.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Reference
