package Git::Raw::Repository;

use strict;
use warnings;

use Git::Raw;

=head1 NAME

Git::Raw::Repository - Git repository class

=head1 SYNOPSIS

    use Git::Raw;

    # clone a Git repository
    my $url  = 'git://github.com/jacquesg/p5-Git-Raw.git';
    my $callbacks = {
      'transfer_progress' => sub {
        my ($total_objects, $received_objects, $local_objects, $total_deltas,
          $indexed_deltas, $received_bytes) = @_;

        print "Objects: $received_objects/$total_objects", "\n";
        print "Received: ", int($received_bytes/1024), "KB", "\n";
      }
    };
    my $repo = Git::Raw::Repository -> clone($url, 'p5-Git-Raw', {}, {
      'callbacks' => $callbacks
    });

    # print all the tags of the repository
    foreach my $tag ($repo -> tags) {
      say $tag -> name;
    }

    # merge a reference
    my $ref = Git::Raw::Reference -> lookup('HEAD', $repo);
    $repo -> merge ($ref);

    my @conflicts = $repo -> index -> conflicts;
    print "Got ", scalar (@conflicts), " conflicts!\n";

=head1 DESCRIPTION

A L<Git::Raw::Repository> represents a Git repository.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 METHODS

=head2 init( $path, $is_bare )

Initialize a new repository at C<$path>.

=head2 clone( $url, $path, \%opts, [\%fetch_opts, \%checkout_opts])

Clone the repository at C<$url> to C<$path>. Valid fields for the C<%opts> hash
are:

=over 4

=item * "bare"

If true (default is false) create a bare repository.

=item * "checkout_branch"

The name of the branch to checkout (default is to use the remote's HEAD).

=item * "disable_checkout"

If true (default is false) files will not be checked out after the clone completes.

=item * "callbacks"

=over 8

=item * "remote_create"

Remote customization callback. If a non-default remote is required, i.e. a remote
with a remote name other than 'origin', this callback should be used. The callback
receives a L<Git::Raw::Repository> object, a string containing the default name
for the remote, typically 'origin', and a string containing the URL of the remote.
This callback should return a L<Git::Raw::Remote> object. The returned object and
the repository object passed to this callback are ephemeral. B<Note:> Do not take any
references to it, as it may be freed internally.

=back

=back

See C<Git::Raw::Remote-E<gt>fetch()> for valid C<%fetch_opts> values and
C<Git::Raw::Repository-E<gt>checkout()> for valid C<%checkout_opts> values.

=head2 open( $path )

Open the repository at C<$path>.

=head2 discover( $path )

Discover the path to the repository directory given a subdirectory.

=head2 new( )

Create a new repository with neither backends nor config object.

=head2 config( )

Retrieve the default L<Git::Raw::Config> of the repository.

=head2 commondir( )

Get the path of the shared common directory for this repository.

=head2 is_worktree( )

Check if the repository is a linked work tree.

=head2 index( [$new_index] )

Retrieve the index of the repository. If C<$new_index> is passed, it will be used
as the index of the repository. If C<$new_index> is C<undef> the index associated
with the repository will be disassociated. Returns a L<Git::Raw::Index> object or
C<undef> if index has been disassociated as part of the call.

=head2 odb( [$new_odb] )

Retrieve the object database of the repository. If C<$odb> is passed, it will be
used as the object database. Returns a L<Git::Raw::Odb> object.

=head2 head( [$new_head] )

Retrieve the L<Git::Raw::Reference> pointed by the HEAD of the repository. If
the L<Git::Raw::Reference> C<$new_head> is passed, the HEAD of the repository
will be changed to point to it.

=head2 head_for_worktree( $worktree )

Retrieve the L<Git::Raw::Reference> pointed by the HEAD of C<$worktree>.

=head2 detach_head( $commitish )

Make the repository HEAD point directly to a commit. C<$commitish> should be
peelable to a L<Git::Raw::Commit> object, that is, it should be a
L<Git::Raw::Commit> or L<Git::Raw::Reference> object, or alternatively a commit
id or commit id prefix.

=head2 lookup( $id )

Retrieve the object corresponding to C<$id>.

=head2 checkout( $object, \%opts )

Updates the files in the index and working tree to match the content of
C<$object>. Valid fields for the C<%opts> hash are:

=over 4

=item * "checkout_strategy"

Hash representing the desired checkout strategy. Valid fields are:

=over 8

=item * "none"

Dry-run checkout strategy. It doesn't make any changes, but checks for
conflicts.

=item * "force"

Take any action to make the working directory match the target (pretty much the
opposite of C<"none">).

=item * "safe_create"

Recreate missing files.

=item * "safe"

Make only modifications that will not lose changes (to be used in order to
simulate C<git checkout>).

=item * "allow_conflicts"

Apply safe updates even if there are conflicts.

=item * "remove_untracked"

Remove untracked files from the working directory.

=item * "remove_ignored"

Remove ignored files from the working directory.

=item * "update_only"

Only update files that already exist (files won't be created or deleted).

=item * "dont_update_index"

Do not write the updated files' info to the index.

=item * "dont_remove_existing"

Don not overwrite existing files or folders.

=item * "dont_write_index"

Prevent writing of the index upon completion.

=item * "no_refresh"

Do not reload the index and git attrs from disk before operations.

=item * "skip_unmerged"

Skip files with unmerged index entries, instead of treating them as conflicts.

=back

=item * "notify"

Notification flags for the notify callback. A list of the following options:

=over 8

=item * "conflict"

Notifies about conflicting paths.

=item * "dirty"

Notifies about files that don't need an update but no longer match the baseline.
Core git displays these files when checkout runs, but won't stop the checkout.

=item * "updated"

Notification on any file changed.

=item * "untracked"

Notification about untracked files.

=item * "ignored"

Notifies about ignored files.

=item * "all"

All of the above.

=back

=item * "callbacks"

Hash containing progress and notification callbacks. Valid fields are:

=over 8

=item * "notify"

This callback is called for each file matching one of the C<notify> options
selected. It runs before modifying any files on disk. This callback should
return a non-zero value should the checkout be cancelled.  The callback receives
a string containing the path of the file C<$path> and an array reference
containing the reason C<$why>.

=item * "progress"

The callback to be invoked as a file is checked out. The callback receives a
string containing the path of the file C<$path>, an integer C<$completed_steps>
and an integer C<$total_steps>.

=back

=item * "paths"

An optional array representing the list of files that should be checked out. If
C<"paths"> is not specified, all files will be checked out (default).

=item * "our_label"

The name of the "our" side of conflicts.

=item * "their_label"

The name of the "their" side of conflicts.

=item * "ancestor_label"

The name of the common ancestor side of conflicts.

=item * "target_directory"

Alternative checkout path to the working directory.

=back

Example:

    $repo -> checkout($repo -> head -> target, {
      'checkout_strategy' => { 'safe'  => 1 },
      'notify'    => [ 'all' ],
      'callbacks' => {
         'notify' => sub {
           my ($path, $why) = @_;

           print "File: $path: ", join(' ', @$why), "\n";
         },
         'progress' => sub {
            my ($path, $completed_steps, $total_steps) = @_;

            print "File: $path", "\n" if defined ($path);
            print "Progress: $completed_steps/$total_steps", "\n";
         }
      },
      'paths' => [ 'myscript.pl' ]
    });

=head2 reset( $target, \%opts )

Reset the current HEAD to the given commit. Valid fields for the C<%opts>
hash are:

=over 4

=item * "type"

Set the type of the reset to be performed. Valid values are: C<"soft"> (the head
will be moved to the commit), C<"mixed"> (trigger a soft reset and replace the
index with the content of the commit tree) or C<"hard"> (trigger a C<"mixed">
reset and the working directory will be replaced with the content of the index).

=item * "paths"

List of entries in the index to be updated from the target commit tree.  This is
particularly useful to implement C<"git reset HEAD -- file file"> behaviour.
Note, if this parameter is specified, a value of C<"mixed"> will be used for
C<"type"> (setting C<"type"> to C<"soft"> or C<"hard"> has no effect).

=back

=head2 status( \%opts, [$file, $file, ...] )

Retrieve the status of files in the index and/or working directory. This function
returns a hash reference with an entry for each C<$file>, or all files if no file
parameters are provided. Each C<$file> entry has a list of C<"flags">, which may
include: C<"index_new">, C<"index_modified">, C<"index_deleted">, C<"index_renamed">,
C<"worktree_new">, C<"worktree_modified">, C<"worktree_deleted">,
C<"worktree_renamed">, C<"worktree_unreadable">, C<"conflicted"> and C<"ignored">.

If C<$file> has been renamed in either the index or worktree or both, C<$file>
will also have a corresponding entry C<"index"> and/or C<"worktree">, containing
the previous filename C<"old_file">.

Valid fields for the C<%opts> hash are:

=over 4

=item * "flags"

Flags for the status. Valid values include:

=over 8

=item * "include_untracked"

Callbacks should be made on untracked files. These will only be made if the
workdir files are included in the C<$show> option.

=item * "include_ignored"

Callbacks should be made on ignored files. These will only be made if the
ignored files get callbacks.

=item * "include_unmodified"

Include even unmodified files.

=item * "exclude_submodules"

Submodules should be skipped. This only applies if there are no pending
typechanges to the submodule (either from or to another type).

=item * "recurse_untracked_dirs"

All files in untracked directories should be included. Normally if an entire
directory is new, then just the top-level directory is included (with a
trailing slash on the entry name). This flag includes all of the individual
files in the directory instead.

=item * "disable_pathspec_match"

Each C<$file> specified should be treated as a literal path, and not as a
pathspec pattern.

=item * "recurse_ignored_dirs"

The contents of ignored directories should be included in the status. This is
like doing C<git ls-files -o -i --exclude-standard> with core git.

=item * "renames_head_to_index"

Rename detection should be processed between the head and the index.

=item * "renames_index_to_workdir"

Rename detection should be run between the index and the working directory.

=item * "sort_case_sensitively"

Override the native case sensitivity for the file system and force the output
to be in case-sensitive order.

=item * "sort_case_insensitively"

Override the native case sensitivity for the file system and force the output
to be in case-insensitive order.

=item * "renames_from_rewrites"

Rename detection should include rewritten files.

=item * "no_refresh"

Bypass the default status behavior of doing a "soft" index reload (i.e.
reloading the index data if the file on disk has been modified outside
C<Git::Raw>).

=item * "update_index"

Refresh the stat cache in the index for files that are unchanged but have 
out-of-date stat information in the index. It will result in less work being done
on subsequent calls to C<status>. This is mutually exclusive with the
C<"no_refresh"> option.

=item * "include_unreadable"

Include unreadable files.

=item * "include_unreadable_as_untracked"

Include unreadable files as untracked files.

=back

=item * "show"

One of the following values (Defaults to C<index_and_worktree>):

=over 8

=item * "index_and_worktree"

=item * "index"

=item * "worktree"

=back

=back

Example:

    my $opts = {
      'flags' => {
        'include_untracked'        => 1,
        'renames_head_to_index'    => 1,
        'renames_index_to_workdir' => 1,
      },
      'show' => 'index_and_worktree'
    };
    my $file_statuses = $repo -> status($opts);
    while (my ($file, $status) = each %$file_statuses) {
      my $flags = $status -> {'flags'};
      print "File: $file: Status: ", join (' ', @$flags), "\n";

      if (grep { $_ eq 'index_renamed' } @$flags) {
        print "Index previous filename: ",
        $status -> {'index'} -> {'old_file'}, "\n";
      }

      if (grep { $_ eq 'worktree_renamed' } @$flags) {
        print "Worktree previous filename: ",
        $status -> {'worktree'} -> {'old_file'}, "\n";
      }
    }

=head2 merge_base( @objects )

Find the merge base between C<@objects>. Each element in C<@objects> should be
peelable to a L<Git::Raw::Commit> object, that is, it should be a
L<Git::Raw::Commit> or L<Git::Raw::Reference> object, or alternatively a commit
id or commit id prefix.

=head2 merge_analysis( $reference )

Analyzes the given C<$reference> and determines the opportunities for merging
them into the HEAD of the repository. This function returns an array reference
with optional members C<"normal">, C<"up_to_date">, C<"fast_forward"> and/or
C<"unborn">.

=over 4

=item * "normal"

A "normal" merge. Both HEAD and the given merge input have diverged from their
common ancestor. The divergent commits must be merged.

=item * "up_to_date"

All given merge inputs are reachable from HEAD, meaning the repository is
up-to-date and no merge needs to be performed.

=item * "fast_forward"

The given merge input is a fast-forward from HEAD and no merge needs to be
performed. Instead, the given merge input may be checked out.

=item * "unborn"

The HEAD of the current repository is "unborn" and does not point to a valid
commit. No merge can be performed, but the caller may wish to simply set
HEAD to the target commit(s).

=back

=head2 merge( $ref, [\%merge_opts, \%checkout_opts])

Merge the given C<$ref> into HEAD, writing the results into the working
directory. Any changes are staged for commit and any conflicts are written
to the index. The index should be inspected for conflicts after this method
completes and any conflicts should be resolved. At this stage a commit
may be created to finalise the merge.

=over 4

=item * "flags"

Merge flags. Valid values include:

=over 8

=item * "find_renames"

Detect renames.

=back

=item * "file_flags"

See C<Git::Raw::Index-E<gt>merge()> for options.

=item * "favor"

Specify content automerging behaviour. Valid values are C<"ours">, C<"theirs">,
and C<"union">.

=item * "rename_threshold"

Similarity metric for considering a file renamed (default is 50).

=item * "target_limit"

Maximum similarity sources to examine (overrides the C<"merge.renameLimit">
configuration entry) (default is 200).

=back

Example:

    my $branch = Git::Raw::Branch -> lookup($repo, 'branch', 1);
    my $analysis = $repo -> merge_analysis($branch);
    my $merge_opts = {
      'favor' => 'theirs'
    };
    my $checkout_opts = {
      'checkout_strategy' => {
        'force' => 1
      }
    };
    $repo -> merge($branch1, $merge_opts, $checkout_opts);

=head2 ignore( $rules )

Add an ignore rules to the repository. The format of the rules is the same one
of the C<.gitignore> file (see the C<gitignore(5)> manpage). Example:

    $repo -> ignore("*.o\n");

=head2 path_is_ignored( $path )

Checks the ignore rules to see if they would apply to the given file. This indicates
if the file would be ignored regardless of whether the file is already in the index
or committed to the repository.

=head2 diff( [\%diff_opts] )

Compute the L<Git::Raw::Diff> between the repo's default index and another tree.
Valid fields for the C<%diff_opts> hash are:

=over 4

=item * "tree"

If provided, the diff is computed between C<"tree"> and the repo's default index.
The default is the repo's working directory.

=item * "flags"

Flags for generating the diff. Valid values include:

=over 8

=item * "reverse"

Reverse the sides of the diff.

=item * "include_ignored"

Include ignored files in the diff.

=item * "include_typechange"

Enable the generation of typechange delta records.

=item * "recurse_ignored_dirs"

Even if C<"include_ignored"> is specified, an entire ignored directory
will be marked with only a single entry in the diff. This flag adds all files
under the directory as ignored entries, too.

=item * "include_untracked"

Include untracked files in the diff.

=item * "recurse_untracked_dirs"

Even if C<"include_untracked"> is specified, an entire untracked directory
will be marked with only a single entry in the diff (core git behaviour).
This flag adds all files under untracked directories as untracked entries, too.

=item * "ignore_filemode"

Ignore file mode changes.

=item * "ignore_case"

Use case insensitive filename comparisons.

=item * "ignore_submodules"

Treat all submodules as unmodified.

=item * "ignore_whitespace"

Ignore all whitespace.

=item * "ignore_whitespace_change"

Ignore changes in amount of whitespace.

=item * "ignore_whitespace_eol"

Ignore whitespace at end of line.

=item * "skip_binary_check"

Disable updating of the binary flag in delta records. This is useful when
iterating over a diff if you don't need hunk and data callbacks and want to avoid
having to load file completely.

=item * "enable_fast_untracked_dirs"

When diff finds an untracked directory, to match the behavior of core git, it
scans the contents for ignored and untracked files. If all contents are ignore,
then the directory is ignored. If any contents are not ignored, then the
directory is untracked.  This is extra work that may not matter in many cases.
This flag turns off that scan and immediately labels an untracked directory
as untracked (changing the behavior to not match core git).

=item * "show_untracked_content"

Include the content of untracked files. This implies C<"include_untracked">.

=item * "show_unmodified"

Include the names of unmodified files.

=item * "patience"

Use the C<"patience diff"> algorithm.

=item * "minimal"

Take extra time to find minimal diff.

=item * "show_binary"

Include the necessary deflate / delta information so that C<git apply> can
apply given diff information to binary files.

=item * "force_text"

Treat all files as text, disabling binary attributes and detection.

=item * "force_binary"

Treat all files as binary, disabling text diffs.

=back

=item * "prefix"

=over 8

=item * "a"

The virtual C<"directory"> to prefix to old file names in hunk headers.
(Default is C<"a">.)

=item * "b"

The virtual C<"directory"> to prefix to new file names in hunk headers.
(Default is C<"b">.)

=back

=item * "context_lines"

The number of unchanged lines that define the boundary of a hunk (and
to display before and after)

=item * "interhunk_lines"

The maximum number of unchanged lines between hunk boundaries before
the hunks will be merged into a one.

=item * "paths"

A list of paths to constrain diff.

=back

=head2 blob( $buffer )

Create a new L<Git::Raw::Blob>. Shortcut for C<Git::Raw::Blob-E<gt>create()>.

=cut

sub blob { return Git::Raw::Blob -> create(@_) }

=head2 branch( $name, $target )

Create a new L<Git::Raw::Branch>. Shortcut for C<Git::Raw::Branch-E<gt>create()>.

=cut

sub branch { return Git::Raw::Branch -> create(@_) }

=head2 branches( [$type] )

Retrieve a list of L<Git::Raw::Branch> objects. Possible values for C<$type>
include C<"local">, C<"remote"> or C<"all">.

=head2 commit( $msg, $author, $committer, \@parents, $tree [, $update_ref ] )

Create a new L<Git::Raw::Commit>. Shortcut for C<Git::Raw::Commit-E<gt>create()>.

=cut

sub commit { return Git::Raw::Commit -> create(@_) }

=head2 tag( $name, $msg, $tagger, $target )

Create a new L<Git::Raw::Tag>. Shortcut for C<Git::Raw::Tag-E<gt>create()>.

=cut

sub tag { return Git::Raw::Tag -> create(@_) }

=head2 tags( [$type] )

Retrieve the list of annotated and/or lightweight tag objects. Possible values
for C<$type> include C<"all">, C<"annotated"> or C<"lightweight">.

=cut

sub tags {
	my $self = shift;

	my @tags;

	Git::Raw::Tag -> foreach($self, sub {
		push @tags, shift; 0
	}, @_);

	return @tags;
}

=head2 stash( $repo, $msg )

Save the local modifications to a new stash. Shortcut for C<Git::Raw::Stash-E<gt>save()>.

=cut

sub stash { return Git::Raw::Stash -> save(@_) }

=head2 remotes( )

Retrieve the list of L<Git::Raw::Remote> objects.

=head2 refs( )

Retrieve the list of L<Git::Raw::Reference> objects.

=head2 walker( )

Create a new L<Git::Raw::Walker>. Shortcut for C<Git::Raw::Walker-E<gt>create()>.

=cut

sub walker { return Git::Raw::Walker -> create(@_) }

=head2 path( )

Retrieve the complete path of the repository.

=head2 workdir( [$new_dir] )

Retrieve the working directory of the repository. If C<$new_dir> is passed, the
working directory of the repository will be set to the directory.

=head2 blame( $path )

Retrieve blame information for C<$path>. Returns a L<Git::Raw::Blame> object.

=head2 cherry_pick( $commit, [\%merge_opts, \%checkout_opts, $mainline] )

Cherry-pick the given C<$commit>, producing changes in the index and working
directory. See C<Git::Raw::Repository-E<gt>merge()> for valid C<%merge_opts>
and C<%checkout_opts> values. For merge commits C<$mainline> specifies the
parent.

=head2 revert( $commit, [\%merge_opts, \%checkout_opts, $mainline] )

Revert the given C<$commit>, producing changes in the index and working
directory. See C<Git::Raw::Repository-E<gt>merge()> for valid C<%merge_opts>
and C<%checkout_opts> values. For merge commits C<$mainline> specifies the
parent.

=head2 revparse( $spec )

Parse the revision string C<$spec> to for C<from>, C<to> and C<intent>. Returns a
list of objects in list context and the number of objects parsed from C<$spec>
in scalar context.

	my ($from, $to) = $repo -> revparse('HEAD~..HEAD');
	print "Range is $from -> $to", "\n";

=head2 state( )

Determine the state of the repository. One of the following values is returned:

=over 4

=item * "none"

Normal state

=item * "merge"

Repository is in a merge.

=item * "revert"

Repository is in a revert.

=item * "cherry_pick"

Repository is in a cherry-pick.

=item * "bisect"

Repository is bisecting.

=item * "rebase"

Repository is rebasing.

=item * "rebase_interactive"

Repository is in an interactive rebase.

=item * "rebase_merge"

Repository is in an rebase merge.

=item * "apply_mailbox"

Repository is applying patches.

=item * "mailbox_or_rebase"

Repository is applying patches or rebasing.

=back

=head2 state_cleanup( )

Remove all the metadata associated with an ongoing command like merge, revert,
cherry-pick, etc.

=head2 message( )

Retrieve the content of git's prepared message i.e. C<".git/MERGE_MSG">.

=head2 is_empty( )

Check if the repository is empty.

=head2 is_bare( )

Check if the repository is bare.

=head2 is_shallow( )

Check if the repository is a shallow clone.

=head2 is_head_detached( )

Check if the repository's C<HEAD> is detached, that is, it points directly to
a commit.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

Jacques Germishuys <jacquesg@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Git::Raw::Repository
