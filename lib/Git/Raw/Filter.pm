package Git::Raw::Filter;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Filter - Git filter class

=head1 DESCRIPTION

A C<Git::Raw::Filter> represents a Git filter.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 CONSTANTS

=head2 OK

The filter is able to run / has succeeded.

=head2 ERROR

The filter failed to run.

=head2 PASSTHROUGH

The filter should be skipped.

=head1 METHODS

=head2 create( $name, $attributes)

Create a filter. C<$name> is a name by which the filter can be referenced.
C<$attributes> is a whitespace-separated list of attribute names to check for
this filter (e.g. L<"eol crlf text">). If the attribute name is bare, it will
be simply loaded and passed to the L<"check"> callback.  If it has a value
(i.e. "name=value"), the attribute must match that value for the filter to
be applied.

=head2 callbacks( \%callbacks )

Set the callbacks for the filter. C<%callbacks> may specificy the following
callbacks.

=over 4

=item * "initialize"

Optional callback to be invoked before a filter is first used. It will be
called once at most.

=item * "shutdown"

Optional callback to be invoked when the filter is unregistered or when
the library is shutting down. It will be called once at most. This may be
called even if C<"initialize"> has never been called.

=item * "check"

Optional callback that checks if filtering is needed for a given source.
The callback receives the following parameters: The filter source, a
C<Git::Raw::Filter::Source> object.

If the filter should be applied, C<OK> should be returned. If the filter
should be skipped, C<PASSTHROUGH> should be returned.

=item * "apply"

Callback that actually filters data.

The callback receives the following parameters: The filter source, a
C<Git::Raw::Filter::Source> object, C<$from> the source data and C<$to>,
a scalar reference where the output should be written to.

If the filter successfully writes the output, C<OK> should be returned.
If the filter failed, C<ERROR> should be returned. If the filter does not want
to run, C<PASSTHROUGH> should be returned.

=item * "cleanup"

Opitional callback to clean up after filtering has been applied.

=back

=head2 register( $priority )

Register the filter with priority C<$priority>.

=head2 unregister( )

Remove the filter.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Filter
