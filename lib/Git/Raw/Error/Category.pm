package Git::Raw::Error::Category;

use strict;
use warnings;
use Carp;

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Git::Raw::Error::Category::constant not defined" if $constname eq '_constant';
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

Git::Raw::Error::Category - Error category class

=head1 DESCRIPTION

A L<Git::Raw::Error::Category> represents an error category or classification.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 CONSTANTS

=head2 NONE

=head2 NOMEMORY

=head2 OS

=head2 INVALID

=head2 REFERENCE

=head2 ZLIB

=head2 REPOSITORY

=head2 CONFIG

=head2 REGEX

=head2 ODB

=head2 INDEX

=head2 OBJECT

=head2 NET

=head2 TAG

=head2 TREE

=head2 INDEXER

=head2 SSL

=head2 SUBMODULE

=head2 THREAD

=head2 STASH

=head2 CHECKOUT

=head2 FETCHHEAD

=head2 MERGE

=head2 SSH

=head2 FILTER

=head2 REVERT

=head2 CALLBACK

=head2 CHERRYPICK

=head2 DESCRIBE

=head2 REBASE

=head2 FILESYSTEM

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

1; # End of Git::Raw::Error::Category
