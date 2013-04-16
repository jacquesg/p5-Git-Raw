package Git::Raw::Branch;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Branch - Git branch class

=head1 SYNOPSIS

    use Git::Raw;

    # open the Git repository at $path
    my $repo = Git::Raw::Repository -> open($path);

    # create a new branch named 'some_branch'
    $repo -> branch('some_branch', $repo -> head -> target);

=head1 DESCRIPTION

Helper class for branch manipulation. Note that a Git branch is nothing more
than a L<Git::Raw::Reference>, so this class inherits all methods from it.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 create( $repo, $name, $target )

Create a new branch given a name and a target object (either a
L<Git::Raw::Commit> or a L<Git::Raw::Tag>).

=head2 lookup( $repo, $name, $is_local )

Retrieve the branch corresponding to the given branch name.

=head2 move( $name, $force )

Rename the branch to C<$name>. Note that in order to get the updated branch
object, an additional C<Git::Raw::Branch-E<gt>lookup()> is needed.

=head2 foreach( $repo, $callback )

Run C<$callback> for every branch in the repo. The callback receives a
branch object. A non-zero return value stops the loop.

=head2 upstream( )

Retrieve the reference supporting the remote tracking branch, given the local
branch.

=head2 is_head( )

Check if the current local branch is pointed at by HEAD.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Branch
