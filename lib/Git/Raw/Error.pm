package Git::Raw::Error;

use strict;
use warnings;
use Carp;

use overload
	'""'       => sub { return $_[0] -> message.' at '.$_[0] -> file.' line '.$_[0] -> line },
	'0+'       => sub { return $_[0] -> code },
	'bool'     => sub { return $_[0] -> _is_error },
	'fallback' => 1;

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Git::Raw::Error::constant not defined" if $constname eq '_constant';
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

Git::Raw::Error - Error class

=head1 DESCRIPTION

A L<Git::Raw::Error> represents an error. A L<Git::Raw::Error> may be the result
of a libgit2 error, or may be generated internally due to misuse of the API.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 message( )

Error message.

=head2 file( )

Caller file.

=head2 line( )

Caller line.

=head2 code( )

Error code.

=head2 category( )

The category (class) or source of the error.

=head1 CONSTANTS

=head2 OK

No error.

=head2 ERROR

Generic error.

=head2 ENOTFOUND

The eequested object could not be found.

=head2 EEXISTS

The object already exists.

=head2 EAMBIGUOUS

More than one object matches.

=head2 EBUFS

Output buffer too short to hold data.

=head2 EBAREREPO

The operation is is not allowed on a bare repository.

=head2 EUNBORNBRANCH

C<HEAD> refers to a branch with no commits.

=head2 EUNMERGED

A merge is in progress.

=head2 ENONFASTFORWARD

Reference was not fast-forwardable.

=head2 EINVALIDSPEC

Name/ref spec was not in a valid format.

=head2 ECONFLICT

Checkout conflicts prevented operation.

=head2 ELOCKED

Lock file prevented operation.

=head2 EMODIFIED

Reference value does not match expected.

=head2 EAUTH

Authentication error.

=head2 ECERTIFICATE

Server certificate is invalid.

=head2 EAPPLIED

Patch/merge has already been applied.

=head2 EPEEL

The requested peel operation is not possible.

=head2 EEOF

Unepected C<EOF>.

=head2 EINVALID

Invalid operation or input.

=head2 EUNCOMMITTED

Uncommited changes in index prevented operation.

=head2 EDIRECTORY

The operation is not valid for a directory.

=head2 EMERGECONFLICT

A merge conflict exists and cannot continue.

=head2 PASSTHROUGH

Passthrough

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

Jacques Germishuys <jacquesg@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Error
