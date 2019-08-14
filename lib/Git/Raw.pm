package Git::Raw;

use strict;
use warnings;

require XSLoader;
XSLoader::load('Git::Raw', $Git::Raw::VERSION);

use Git::Raw::Error;
use Git::Raw::Error::Category;
use Git::Raw::AnnotatedCommit;
use Git::Raw::Packbuilder;
use Git::Raw::Blob;
use Git::Raw::Commit;
use Git::Raw::Index;
use Git::Raw::Indexer;
use Git::Raw::Object;
use Git::Raw::Odb;
use Git::Raw::Odb::Object;
use Git::Raw::Mempack;
use Git::Raw::Rebase;
use Git::Raw::Reference;
use Git::Raw::Repository;
use Git::Raw::Stash;
use Git::Raw::Stash::Progress;
use Git::Raw::Submodule;
use Git::Raw::Tree;
use Git::Raw::TransferProgress;
use Git::Raw::Worktree;

1;

__END__

=for HTML
<a href="https://dev.azure.com/jacquesgermishuys/p5-Git-Raw/_build">
	<img src="https://dev.azure.com/jacquesgermishuys/p5-Git-Raw/_apis/build/status/jacquesg.p5-Git-Raw?branchName=master" alt="Build Status: Azure Pipeline" align="right" />
</a>
<a href="https://ci.appveyor.com/project/jacquesg/p5-git-raw">
	<img src="https://ci.appveyor.com/api/projects/status/il9rm9fsf9dj1dcu/branch/master?svg=true" alt="Build Status: AppVeyor" align="right" />
</a>
<a href="https://coveralls.io/r/jacquesg/p5-Git-Raw">
	<img src="https://coveralls.io/repos/jacquesg/p5-Git-Raw/badge.png?branch=master" alt="coveralls" align="right" />
</a>
=cut

=head1 NAME

Git::Raw - Perl bindings to the Git linkable library (libgit2)

=head1 DESCRIPTION

L<libgit2|http://libgit2.github.com> is a pure C implementation of the Git core
methods provided as a re-entrant linkable library designed to be fast and
portable with a solid API.  This module provides Perl bindings to the libgit2
API.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 features( )

List of (optional) compiled in features. Git::Raw may be built with support
for threads, HTTPS and SSH.

=head2 message_prettify( $msg, [$strip_comments, $comment_char] )

Clean up C<$msg> from excess whitespace and ensure that the last line ends with
a newline. The default is to strip all comments, starting with a C<#>, unless
otherwise specified.

=head1 DOCUMENTATION

=head2 L<Git::Raw::AnnotatedCommit>

=head2 L<Git::Raw::Blame>

=head2 L<Git::Raw::Blame::Hunk>

=head2 L<Git::Raw::Blob>

=head2 L<Git::Raw::Branch>

=head2 L<Git::Raw::Cert>

=head2 L<Git::Raw::Cert::HostKey>

=head2 L<Git::Raw::Cert::X509>

=head2 L<Git::Raw::Commit>

=head2 L<Git::Raw::Config>

=head2 L<Git::Raw::Cred>

=head2 L<Git::Raw::Diff>

=head2 L<Git::Raw::Diff::Delta>

=head2 L<Git::Raw::Diff::File>

=head2 L<Git::Raw::Diff::Hunk>

=head2 L<Git::Raw::Diff::Stats>

=head2 L<Git::Raw::Error>

=head2 L<Git::Raw::Error::Category>

=head2 L<Git::Raw::Filter>

=head2 L<Git::Raw::Filter::List>

=head2 L<Git::Raw::Filter::Source>

=head2 L<Git::Raw::Graph>

=head2 L<Git::Raw::Index>

=head2 L<Git::Raw::Index::Conflict>

=head2 L<Git::Raw::Index::Entry>

=head2 L<Git::Raw::Indexer>

=head2 L<Git::Raw::Mempack>

=head2 L<Git::Raw::Merge::File::Result>

=head2 L<Git::Raw::Note>

=head2 L<Git::Raw::Object>

=head2 L<Git::Raw::Odb>

=head2 L<Git::Raw::Odb::Backend>

=head2 L<Git::Raw::Odb::Backend::Loose>

=head2 L<Git::Raw::Odb::Backend::OnePack>

=head2 L<Git::Raw::Odb::Backend::Pack>

=head2 L<Git::Raw::Odb::Object>

=head2 L<Git::Raw::Packbuilder>

=head2 L<Git::Raw::Patch>

=head2 L<Git::Raw::PathSpec>

=head2 L<Git::Raw::PathSpec::MatchList>

=head2 L<Git::Raw::Rebase>

=head2 L<Git::Raw::Rebase::Operation>

=head2 L<Git::Raw::RefSpec>

=head2 L<Git::Raw::Reference>

=head2 L<Git::Raw::Reflog>

=head2 L<Git::Raw::Reflog::Entry>

=head2 L<Git::Raw::Remote>

=head2 L<Git::Raw::Repository>

=head2 L<Git::Raw::Signature>

=head2 L<Git::Raw::Submodule>

=head2 L<Git::Raw::Stash>

=head2 L<Git::Raw::Stash::Progress>

=head2 L<Git::Raw::Tag>

=head2 L<Git::Raw::TransferProgress>

=head2 L<Git::Raw::Tree>

=head2 L<Git::Raw::Tree::Builder>

=head2 L<Git::Raw::Tree::Entry>

=head2 L<Git::Raw::Walker>

=head2 L<Git::Raw::Worktree>

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
