package Git::Raw::Rebase::Operation;

use strict;
use warnings;
use Carp;

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Git::Raw::Rebase::Operation::constant not defined" if $constname eq '_constant';
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

Git::Raw::Rebase::Operation - Git rebase operation class

=head1 DESCRIPTION

A L<Git::Raw::Rebase::Operation> represents a git rebase operation.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 type( )

The type of rebase operation.

=head2 id( )

The commit ID being cherry-picked. This will return C<undef> for C<EXEC>
operations.

=head2 exec( )

The executable the user has requested to run. This will return C<undef> for all
but C<EXEC> operations.

=head1 CONSTANTS

=head2 PICK

The given commit is to be cherry-picked. The client should commit the changes
and continue if there are no conflicts.

=head2 REWORD

The given commit is to be cherry-picked, but the client should prompt the user
to provide an updated commit message.

=head2 EDIT

The given commit is to be cherry-picked, but the client should stop to allow the
user to edit the changes before committing them.

=head2 SQUASH

The given commit is to be squashed into the previous commit. The commit message
will be merged with the previous message.

=head2 FIXUP

The given commit is to be squashed into the previous commit. The commit message
from this commit will be discarded.

=head2 EXEC

No commit will be cherry-picked. The client should run the given command and
(if successful) continue.

=head1 AUTHOR

Jacques Germishuys <jacquesg@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Rebase::Operation
