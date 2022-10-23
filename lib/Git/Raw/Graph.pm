package Git::Raw::Graph;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Graph - Git graph class

=head1 SYNOPSIS

    use Git::Raw;

    # open the Git repository at $path
    my $repo = Git::Raw::Repository -> open($path);

    my $commit1 = Git::Raw::Commit -> lookup($repo,
      '4a202b346bb0fb0db7eff3cffeb3c70babbd2045');

    my $commit2 = Git::Raw::Commit -> lookup($repo,
      '5b5b025afb0b4c913b4c338a42934a3863bf3644');

    if (Git::Raw::Graph -> is_descendant_of($repo, $commit1, $commit2)) {
      print $commit1 -> id, ' is a descendant of ', $commit2 -> id, "\n";
    } else {
      print $commit1 -> id, ' is a not descendant of ', $commit2 -> id, "\n";
    }

=head1 DESCRIPTION

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head2 ahead( $repo, $local, $upstream )

Get the commits C<$local> is ahead of C<$upstream>. C<$local> and C<$upstream>
should be peelable to a L<Git::Raw::Commit> object, that is, it should be a
L<Git::Raw::Commit> or L<Git::Raw::Reference> object, or alternatively a commit
id or commit id prefix. This method returns a list of L<Git::Raw::Commit>
objects, sorted in topological order.

=head2 behind( $repo, $local, $upstream )

Get the commits C<$local> is behind C<$upstream>. C<$local> and C<$upstream>
should be peelable to a L<Git::Raw::Commit> object, that is, it should be a
L<Git::Raw::Commit> or L<Git::Raw::Reference> object, or alternatively a commit
id or commit id prefix. This method returns a list of L<Git::Raw::Commit>
objects, sorted in topological order.

=head2 ahead_behind( $repo, $local, $upstream )

Get the unique commits between C<$local> and C<$upstream>. C<$local>
and C<$upstream> should be peelable to a L<Git::Raw::Commit> object, that is,
it should be a L<Git::Raw::Commit> or L<Git::Raw::Reference> object, or
alternatively a commit id or commit id prefix. This method returns a hash
reference with optional members C<"ahead"> and C<"behind">, each an array
of L<Git::Raw::Commit> objects, sorted in topological order.

=head2 is_descendant_of( $repo, $commitish, $ancestor )

Determine if C<$commitish> is the descendant of C<$ancestor>. C<$commitish>
and C<$ancestor> should be peelable to a L<Git::Raw::Commit> object, that is,
it should be a L<Git::Raw::Commit> or L<Git::Raw::Reference> object, or
alternatively a commit id or commit id prefix.

=head1 AUTHOR

Jacques Germishuys <jacquesg@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Graph
