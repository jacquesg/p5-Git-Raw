#!perl

use Test::More;

use Git::Raw;
use File::Copy;
use File::Slurp::Tiny qw(write_file);
use File::Spec::Functions qw(catfile canonpath rel2abs);
use File::Path 2.07 qw(make_path remove_tree);
use Time::Local;

my $path = rel2abs(catfile('t', 'test_repo'));
my $repo = Git::Raw::Repository -> open($path);
$repo -> config -> bool('diff.mnemonicprefix', 0);

my $file  = $repo -> workdir . 'test';
my $untracked_file = $repo -> workdir . 'untracked_file';
write_file($file, 'this is a test');

ok (!eval {$repo -> status({'show' => 'blah'})});

is_deeply $repo -> status({'show' => 'index', 'flags' => {'include_untracked' => 1}}, 'test') -> {'test'},
	undef;

is_deeply $repo -> status({'show' => 'worktree', 'flags' => {'include_untracked' => 1}}, 'test') -> {'test'},
	{'flags' => ['worktree_new']};

is_deeply $repo -> status({'show' => 'index_and_worktree', 'flags' => {'include_untracked' => 1}}, 'test') -> {'test'},
	{'flags' => ['worktree_new']};

my $index = $repo -> index;
is canonpath($index -> path), canonpath(catfile($path, '.git/index'));

ok (!eval { $index -> add($index) });
$index -> add_all({
	'paths' => [
		'test'
	]
});
$index -> write;

my $tree = $index -> write_tree;
isa_ok $tree, 'Git::Raw::Tree';

my $non_existent = $repo -> lookup('123456789987654321');
is $non_existent, undef;

is_deeply $repo -> status({}) -> {'test'}, {'flags' => ['index_new']};

write_file($file, 'this is a test with more content');
is_deeply $repo -> status({}) -> {'test'}, {'flags' => ['index_new', 'worktree_modified']};

$index -> update_all({
	'paths' => [
		'test'
	]
});
$index -> write;

is_deeply $repo -> status({}) -> {'test'}, {'flags' => ['index_new']};

write_file($file, 'this is a test');
$index -> add('test');
$index -> write;

my $entry = $index -> find('test');
isa_ok $entry, 'Git::Raw::Index::Entry';
is $entry -> path, 'test';
is $entry -> stage, 0;

my $non_existent_entry = $index -> find('non-existent');
is $non_existent_entry, undef;

write_file($untracked_file, 'this is an untracked file');
is_deeply $repo -> status({'flags' => {'include_untracked' => 1}}) -> {'untracked_file'},
	{'flags' => ['worktree_new']};

remove_tree($untracked_file);
is_deeply $repo -> status({'flags' => {'include_untracked' => 1}}) -> {'untracked_file'},
	undef;

isa_ok $tree, 'Git::Raw::Tree';

my $config = $repo -> config;
my $name   = $config -> str('user.name');
my $email  = $config -> str('user.email');

my $time = time();
my $off  = 120;
my $me   = Git::Raw::Signature -> new($name, $email, $time, $off);

my $commit = Git::Raw::Commit -> create($repo, "initial commit\n", $me, $me, [], $tree);

ok (!eval { $commit -> diff(0)});
ok (!eval { $commit -> diff(1)});

my $diff = $commit -> diff;
isa_ok $diff, 'Git::Raw::Diff';

$diff = $commit -> diff(undef, {});

is_deeply $repo -> status({}) -> {'test'}, undef;

my $author = $commit -> author;

is $commit -> message, "initial commit\n";
is $commit -> summary, "initial commit";

is $commit -> author -> name, $name;
is $commit -> author -> email, $email;
is $commit -> author -> time, $time;
is $commit -> author -> offset, $off;

is $commit -> committer -> name, $name;
is $commit -> committer -> email, $email;
is $commit -> committer -> time, $time;
is $commit -> committer -> offset, $off;

is $commit -> time, $time;
is $commit -> offset, $off;

subtest "overloading" => sub {
    is $commit->id, "$commit",          "stringification";
    cmp_ok $commit, 'eq', $commit->id,  "eq";
    ok !($commit ne $commit->id),       "ne";
    is $commit cmp $commit->id, 0,      "cmp";
};

my $repo2 = $commit -> owner;
isa_ok $repo2, 'Git::Raw::Repository';
is $repo2 -> path, $repo -> path;

write_file($file, 'this is a test....');
is_deeply $repo -> status({}) -> {'test'}, {'flags' => ['worktree_modified'] };
ok (!eval { $repo -> reset($commit, {'type' => 'invalid_type'}) });
$repo -> reset($commit, {'type' => 'hard'});
is $repo -> status({}) -> {'test'}, undef;

move($file, $file.'.moved');
$index -> remove('test');
$index -> add('test.moved');
$index -> write;
is_deeply $repo -> status({'flags' => {'renames_head_to_index' => 1}}) -> {'test.moved'}, {
		'flags' => ['index_renamed'],
		'index' => {'old_file' => 'test'}
	};

write_file($file.'.moved', 'this is a test with more content');
is_deeply $repo -> status({'flags' => {'renames_head_to_index' => 1}}) -> {'test.moved'}, {
	'flags' => ['index_renamed', 'worktree_modified'],
	'index' => {'old_file' => 'test'}
	};

move($file.'.moved', $file);
$index -> remove('test.moved');
$index -> add('test');
$index -> write;
is_deeply $repo -> status({}) -> {'test'}, {'flags' => ['index_modified']};

$repo -> reset($commit, {'paths' => [undef, 'test']});
is_deeply $repo -> status({}) -> {'test'}, {'flags' => ['worktree_modified']};

ok (!eval { $index -> update_all({
	'paths' => [ 'test' ],
	'notification' => sub { die "Bad!"; }
})});

is_deeply $repo -> status({}) -> {'test'}, {'flags' => ['worktree_modified']};

$index -> update_all({
	'paths' => [ 'test' ],
	'notification' => sub { return 1; }
});

is_deeply $repo -> status({}) -> {'test'}, {'flags' => ['worktree_modified']};

$index -> update_all({
	'paths' => [
		undef,
		'test'
	],
	'notification' => sub {
		my ($path, $pathspec) = @_;

		is $path, 'test';
		is $path, $pathspec;

		return 0;
	}
});

$index -> write;
is_deeply $repo -> status({}) -> {'test'}, {'flags' => ['index_modified']};

write_file($file, 'this is a test');
$index -> add('test');
$index -> write;
is_deeply $repo -> status({}) -> {'test'}, undef;

$file  = $repo -> workdir . 'test2';
write_file($file, 'this is a second test');

$index -> add('test2');
$index -> write;

$tree = $index -> write_tree;

$time += 1;

my @current_time = localtime($time);
$off = (timegm(@current_time) - timelocal(@current_time))/60;

$me   = Git::Raw::Signature -> new($name, $email, $time, $off);

my $head = $repo -> head -> target;
isa_ok $head, 'Git::Raw::Commit';

my $commit2 = $repo -> commit(
	"second commit\n", $me, $me, [$head], $tree
);

ok (!eval { $commit2 -> diff(1) });
$diff = $commit2 -> diff;
isa_ok $diff, 'Git::Raw::Diff';
my $diff2 = $commit2 -> diff(0);
isa_ok $diff2, 'Git::Raw::Diff';

my $commit2_id = $commit2 -> id;
my $patch = "\n".join("\n", grep { $_ !~ /^Date/ } split (/\n/, $commit2 -> as_email))."\n";
my $expected_patch = qq{
From $commit2_id Mon Sep 17 00:00:00 2001
From: Git::Raw author <git-xs\@example.com>
Subject: [PATCH] second commit

---
 test2 | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 test2

diff --git a/test2 b/test2
new file mode 100644
index 0000000..7b79d2f
--- /dev/null
+++ b/test2
@@ -0,0 +1 @@
+this is a second test
\\ No newline at end of file
--
libgit2 0.25.0
};

is $patch, $expected_patch;

my $email_opts = {
	'patch_no'      => 1,
	'total_patches' => 2,
};

$patch = "\n".join("\n", grep { $_ !~ /^Date/ } split (/\n/, $commit2 -> as_email($email_opts, {})))."\n";
$expected_patch = qq{
From $commit2_id Mon Sep 17 00:00:00 2001
From: Git::Raw author <git-xs\@example.com>
Subject: [PATCH 1/2] second commit

---
 test2 | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 test2

diff --git a/test2 b/test2
new file mode 100644
index 0000000..7b79d2f
--- /dev/null
+++ b/test2
@@ -0,0 +1 @@
+this is a second test
\\ No newline at end of file
--
libgit2 0.25.0
};

is $patch, $expected_patch;

$email_opts->{flags} = {
	'exclude_subject_patch_marker' => 1
};

$patch = "\n".join("\n", grep { $_ !~ /^Date/ } split (/\n/, $commit2 -> as_email($email_opts)))."\n";
$expected_patch = qq{
From $commit2_id Mon Sep 17 00:00:00 2001
From: Git::Raw author <git-xs\@example.com>
Subject: second commit

---
 test2 | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 test2

diff --git a/test2 b/test2
new file mode 100644
index 0000000..7b79d2f
--- /dev/null
+++ b/test2
@@ -0,0 +1 @@
+this is a second test
\\ No newline at end of file
--
libgit2 0.25.0
};

is $patch, $expected_patch;


my $amended = $commit2 -> amend([$head], $tree, undef);
is $amended -> tree -> id, $commit2 -> tree -> id;
is $amended -> id, $commit2 -> id;

ok ($amended eq $commit2);
ok ($amended eq $commit2 -> id);
ok ($amended -> id eq $commit2);
ok ($commit2 ne $commit);
ok ($commit2 ne $repo);

is $commit2 -> ancestor(0) -> id, $commit2 -> id;
is $commit2 -> ancestor(1) -> id, $commit -> id;

$head = $repo -> head -> target;

is (Git::Raw::Graph -> is_descendant_of($repo, $commit2, $commit), 1);
is (Git::Raw::Graph -> is_descendant_of($repo, $commit2 -> id, $commit -> id), 1);

is (Git::Raw::Graph -> is_descendant_of($repo, $commit, $commit2), 0);
is (Git::Raw::Graph -> is_descendant_of($repo, $commit -> id, $commit2 -> id), 0);

ok (!eval { Git::Raw::Graph -> is_descendant_of($repo, $commit, '12341234') });
ok (!eval { Git::Raw::Graph -> is_descendant_of($repo, '12341234', $commit) });

is $head -> message, "second commit\n";
is $head -> summary, "second commit";

is $head -> author -> name, $name;
is $head -> author -> email, $email;
is $head -> author -> time, $time;
is $head -> author -> offset, $off;

is $head -> committer -> name, $name;
is $head -> committer -> email, $email;
is $head -> committer -> time, $time;
is $head -> committer -> offset, $off;

is $head -> time, $time;
is $head -> offset, $off;

$head -> parents; # void context
my $parent_count = $head -> parents;
is $parent_count, 1;
my @parents = $head -> parents;
is scalar(@parents), 1;

is $parents [0] -> message, "initial commit\n";

make_path($repo -> workdir . 'test3/under/the/tree');
$file  = $repo -> workdir . 'test3/under/the/tree/test3';
write_file($file, 'this is a third test');

$index -> add('test3/under/the/tree/test3');
$index -> write;

$tree = $index -> write_tree;

$index -> read_tree($tree);
my @entries = $index -> entries();
is scalar(@entries), 3;

$time += 1;
$me   = Git::Raw::Signature -> new($name, $email, $time, $off);

my $commit3 = $repo -> commit(
	"third commit\n\n Hello World ", $me, $me, [$repo -> head -> target], $tree
);

is $commit3 -> ancestor(0) -> id, $commit3 -> id;
is $commit3 -> ancestor(1) -> id, $commit2 -> id;
is $commit3 -> ancestor(2) -> id, $commit -> id;
ok (!eval { $commit3 -> ancestor(3) });

is (Git::Raw::Graph -> is_descendant_of($repo, $commit3, $commit), 1);
is (Git::Raw::Graph -> is_descendant_of($repo, $commit3 -> id, $commit -> id), 1);
is (Git::Raw::Graph -> is_descendant_of($repo, substr($commit3 -> id, 0, 7), $commit -> id), 1);

is (Git::Raw::Graph -> is_descendant_of($repo, $commit, $commit3), 0);
is (Git::Raw::Graph -> is_descendant_of($repo, $commit -> id, $commit3 -> id), 0);
is (Git::Raw::Graph -> is_descendant_of($repo, substr($commit -> id, 0, 7), $commit3 -> id), 0);

$head = $repo -> head -> target;

isa_ok $head, 'Git::Raw::Commit';

is $head -> message, "third commit\n\n Hello World ";
is $head -> summary, "third commit";
is $head -> body, "Hello World";

is $head -> author -> name, $name;
is $head -> author -> email, $email;
is $head -> author -> time, $time;
is $head -> author -> offset, $off;

is $head -> committer -> name, $name;
is $head -> committer -> email, $email;
is $head -> committer -> time, $time;
is $head -> committer -> offset, $off;

is $head -> time, $time;
is $head -> offset, $off;

my @before_refs = sort map { $_ -> name() } $repo -> refs();

my $commit4 = $repo -> commit(
    "fourth commit\n", $me, $me, [], $tree, undef
);

is $repo -> head -> target -> id, $commit3 -> id, q{Make sure that undef reference doesn't update HEAD};

$non_existent = Git::Raw::Commit -> lookup($repo, '123456789987654321');
is $non_existent, undef;
$commit4 = Git::Raw::Commit -> lookup($repo, $commit4 -> id);

is $commit4 -> message, "fourth commit\n";
is $commit4 -> summary, "fourth commit";

is $commit4 -> author -> name, $name;
is $commit4 -> author -> email, $email;
is $commit4 -> author -> time, $time;
is $commit4 -> author -> offset, $off;

is $commit4 -> committer -> name, $name;
is $commit4 -> committer -> email, $email;
is $commit4 -> committer -> time, $time;
is $commit4 -> committer -> offset, $off;

my @after_refs = sort map { $_ -> name() } $repo -> refs();

is_deeply \@after_refs, \@before_refs, 'No new references should be created when specifying undef as the update ref argument';

my $commit5 = $repo -> commit(
    "fifth commit\n", $me, $me, [], $tree, 'refs/commit-test-ref',
);

is $repo -> head -> target -> id, $commit3 -> id, q{Make sure that stringy reference doesn't update HEAD};

$commit5 = Git::Raw::Reference -> lookup('refs/commit-test-ref', $repo) -> target;

is $commit5 -> message, "fifth commit\n";
is $commit5 -> summary, "fifth commit";

is $commit5 -> author -> name, $name;
is $commit5 -> author -> email, $email;
is $commit5 -> author -> time, $time;
is $commit5 -> author -> offset, $off;

is $commit5 -> committer -> name, $name;
is $commit5 -> committer -> email, $email;
is $commit5 -> committer -> time, $time;
is $commit5 -> committer -> offset, $off;

$file  = $repo -> workdir . 'prerename';
write_file($file, q{
renamed in worktree
renamed in worktree
renamed in worktree
renamed in worktree
});
$index -> add('prerename');
$index -> write;

move($file, $file.'.moved');
is_deeply $repo -> status({'flags' => {'renames_index_to_workdir' => 1, 'include_untracked' => 1}}) -> {'prerename.moved'}, {
	'flags' => ['index_new', 'worktree_renamed'],
	'worktree' => {'old_file' => 'prerename'}
	};

move($file.'.moved', $file);
is_deeply $repo -> status({'flags' => {'renames_index_to_workdir' => 1, 'include_untracked' => 1}}) -> {'prerename'}, {
	'flags' => ['index_new']
	};

remove_tree($file);
is_deeply $repo -> status({'flags' => {'renames_index_to_workdir' => 1, 'include_untracked' => 1}}) -> {'prerename'}, {
	'flags' => ['index_new', 'worktree_deleted']
	};

$index -> remove('prerename');
$index -> write();

my $old_head = $repo -> head;
$repo -> detach_head($old_head -> target);
is $repo -> is_head_detached, 1;

$repo -> head ($old_head);
is $repo -> is_head_detached, 0;

my $reflog = Git::Raw::Reflog -> open(Git::Raw::Reference -> lookup ('HEAD', $repo));
my $entry_count = $reflog -> entry_count;
ok $entry_count >= 2;

@entries = $reflog -> entries(0, 2);
is scalar(@entries), 2;
like $entries[0] -> message, qr/^checkout: moving from /;
like $entries[0] -> message, qr/to master$/;
like $entries[1] -> message, qr/^checkout: moving from master to/;

ok (!eval {$repo -> detach_head()});

my $checksum = $index -> checksum;
is length ($checksum), 40;
isnt $checksum, '0' x 40;

done_testing;
