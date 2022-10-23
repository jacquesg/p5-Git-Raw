package Git::Raw::Submodule;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Submodule - Git submodule class

=head1 DESCRIPTION

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 foreach( $repo, \&callback )

Iterate over all tracked submodules of a repository. Calls C<\&callback> for each submodule.
The callback receives a single argument, the name of the submodule. A non-zero return value
will terminate the loop.

=head2 lookup( $repo, $name )

Lookup submodule information by name or path. Returns a L<Git::Raw::Submodule> object.

=head2 init( $overwrite )

Just like "git submodule init", this copies information about the submodule into ".git/config".

=head2 open( )

Open the repository for a submodule. Returns a L<Git::Raw::Repository> object.

=head2 update( $init, [\%update_opts] )

Update a submodule. This will clone a missing submodule and checkout the subrepository
to the commit specified in the index of the containing repository. If the submodule repository
doesn't contain the target commit, then the submodule is fetched using the fetch options
supplied in C<\%update_opts>. If the submodule is not initialized, setting the C<$init> flag
to true will initialize the submodule before updating. Otherwise, this method will thrown an
exception if attempting to update an uninitialzed repository.

Valid fields for C<%update_opts> are:

=over 4

=item * "checkout_opts"

See C<Git::Raw::Repository-E<gt>checkout()>.

=item * "fetch_opts"

See C<Git::Raw::Remote-E<gt>fetch()>.

=item * "allow_fetch"

Allow fetching from the submodule's default remote if the target commit isn't
found. Enabled by default.

=back

=head2 name( )

Get the name of submodule.

=head2 path( )

Get the path to the submodule.

=head2 url( )

Get the URL of the submodule.

=head2 add_to_index( )

Add current submodule HEAD commit to index of superproject.

=head2 sync( )

Copy submodule remote info into submodule repo.

=head2 reload( )

Reread submodule info from config, index, and HEAD.

=head1 AUTHOR

Jacques Germishuys <jacquesg@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Submodule
