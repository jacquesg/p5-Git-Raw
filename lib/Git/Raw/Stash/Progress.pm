package Git::Raw::Stash::Progress;

use strict;
use warnings;
use Carp;

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Git::Raw::Stash::Progress::constant not defined" if $constname eq '_constant';
    my ($error, $val) = _constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

use Git::Raw;

=head1 NAME

Git::Raw::Stash::Progress - Git stash progress

=head1 DESCRIPTION

L<Git::Raw::Stash::Progress> provides a namespace for stash progress constants.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 CONSTANTS

=head2 NONE

None.

=head2 LOADING_STASH

Stashed data is being loaded from the object database.

=head2 ANALYZE_INDEX

The stored index is being analyzed.

=head2 ANALYZE_MODIFIED

The modified files are being analyzed.

=head2 ANALYZE_UNTRACKED

The untracked and ignored files are being analyzed.

=head2 CHECKOUT_UNTRACKED

The untracked files are being written to disk.

=head2 CHECKOUT_MODIFIED

The modified files are being written to disk.

=head2 DONE

The stash was successfully applied.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Stash::Progress
