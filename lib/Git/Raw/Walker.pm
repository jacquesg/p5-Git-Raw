package Git::Raw::Walker;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Walker - Git revwalker class

=head1 SYNOPSIS

    use Git::Raw;

    # open the Git repository at $path
    my $repo = Git::Raw::Repository -> open($path);

    # create a new walker
    my $log  = $repo -> walker;

    # push the head of the repository
    $log -> push($repo -> head);

    # print all commit messages
    while (my $commit = $log -> next) {
      say $commit -> message;
    }

=head1 DESCRIPTION

A C<Git::Raw::Walker> represents a graph walker used to walk through the
repository's revisions (sort of like C<git log>).

=head1 METHODS

=head2 create( $repo )

Create a new revision walker.

=head2 push( $commit )

Push a L<Git::Raw::Commit> to the list of commits to be used as roots when
starting a revision walk.

=head2 push_glob( $glob )

Push references by C<$glob> to the list of commits to be used as roots when
starting a revision walk.

=head2 push_ref( $name )

Push a reference by C<$name> to the list of commits to be used as roots when
starting a revision walk.

=head2 push_head( )

Push HEAD of the repository to the list of commits to be used as roots when
starting a revision walk.

=head2 hide( $commit )

Hide a L<Git::Raw::Commit> and its ancestors from the walker.

=head2 hide_glob( $glob )

Hide references by C<$glob> and all ancestors from the walker.

=head2 hide_ref( $name )

Hide a reference by C<$name> and its ancestors from the walker.

=head2 hide_head( )

Hide HEAD of the repository and its ancestors from the walker.

=head2 next( )

Retrieve the next commit from the revision walk.

=head2 reset( )

Reset the revision walker (this is done automatically at the end of a walk).

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Walker
