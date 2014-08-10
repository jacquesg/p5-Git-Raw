package Git::Raw::Error;

use strict;
use warnings;
use Carp;

use overload
	'""'       => sub { return $_[0] -> message },
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

=head2 code( )

Error code.

=head2 category( )

The category (class) or source of the error.

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

1; # End of Git::Raw::Error
