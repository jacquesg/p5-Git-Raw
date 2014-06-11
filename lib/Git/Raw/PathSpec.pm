package Git::Raw::PathSpec;

use strict;
use warnings;

=head1 NAME

Git::Raw::PathSpec - Git pathspec class

=head1 DESCRIPTION

A C<Git::Raw::PathSpec> represents a Git pathspec.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 new( @paths )

Compile a new pathspec. C<@match> is the list of paths to match.

=head2 match( $object [, \%options] )

Math the pathspec against C<$object>. C<$object> could be a
L<Git::Raw::Repository> (matches against the working directory),
L<Git::Raw::Index> (matches against the index), L<Git::Raw::Tree> (matches
against the tree) or a L<Git::Raw::Diff> (matches against the diff). Returns
a L<Git::Raw::PathSpec::MatchList> object. Valid fields for C<%options> are:

=over 4

=item * "flags"

Flags for the matches. Valid values include:

=over 8

=item * "ignore_case"

Forces match to ignore case, otherwise the match will use native case
sensitivity of the platform's filesystem.

=item * "use_case"

Forces case sensitive match, otherwise the match will use native case
sensitivity of the platform's filesystem.

=item * "no_glob"

Disables glob patterns and just uses simple string comparison for matching.

=item * "no_match_error"

C<math> should return an error code if no matches were found.

=item * "find_failures"

Record patterns that did not match.

=item * "failures_only"

Only determine if there were patterns that did not match.

=back

=back

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

1; # End of Git::Raw::PathSpec
