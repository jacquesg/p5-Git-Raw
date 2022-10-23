package Git::Raw::Tag;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Tag - Git tag class

=head1 SYNOPSIS

    use Git::Raw;

    # open the Git repository at $path
    my $repo = Git::Raw::Repository -> open($path);

    # retrieve user's name and email from the Git configuration
    my $config = $repo -> config;
    my $name   = $config -> str('user.name');
    my $email  = $config -> str('user.email');

    # create a new Git signature
    my $me = Git::Raw::Signature -> now($name, $email);

    # create a new tag
    my $tag = $repo -> tag(
      'v0.1', 'Initial version', $me, $repo -> head -> target
    );

=head1 DESCRIPTION

A L<Git::Raw::Tag> represents an annotated Git tag.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 create( $repo, $name, $msg, $tagger, $target )

Create a new annotated tag given a name, a message, a
L<Git::Raw::Signature> representing the tagger and a target object.

=head2 lookup( $repo, $id )

Retrieve the tag corresponding to C<$id>. This function is pretty much the same
as C<$repo-E<gt>lookup($id)> except that it only returns tags. If the tag
doesn't exist, this function will return C<undef>.

=head2 owner( )

Retrieve the L<Git::Raw::Repository> owning the tag.

=head2 foreach( $repo, $callback, [$type] )

Run C<$callback> for every tag in the repo. The callback receives a tag object,
which will either a be a L<Git::Raw::Tag> object for annotated tags, or a
L<Git::Raw::Reference> for lightweight tags. C<$type> may be C<"all">,
C<"annotated"> or C<"lightweight">. If C<$type> is not specified or is C<undef>,
all tags will be returned. A non-zero return value stops the loop.

=head2 delete( )

Delete the tag. The L<Git::Raw::Tag> object must not be accessed afterwards.

=head2 id( )

Retrieve the id of the tag, as a string.

=head2 name( )

Retrieve the name of the tag.

=head2 message( )

Retrieve the message of the tag.

=head2 tagger( )

Retrieve the L<Git::Raw::Signature> representing the tag's tagger. If there
is no tagger, C<undef> will be returned.

=head2 target( )

Retrieve the target object of the tag.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

Jacques Germishuys <jacquesg@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Tag
