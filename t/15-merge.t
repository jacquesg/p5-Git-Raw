#!perl

use Test::More;

use Git::Raw;
use File::Spec;
use File::Slurp::Tiny qw(write_file read_file);
use Cwd qw(abs_path);
use File::Path qw(rmtree);

my $path = abs_path('t').'/merge_repo';
my $repo = Git::Raw::Repository -> init($path, 0);

my $file1 = $repo -> workdir . 'test1';
write_file($file1, 'this is file1');

my $index = $repo -> index;
$index -> add('test1');
$index -> write;

my $config = $repo -> config;

my $name  = 'Git::Raw author';
my $email = 'git-xs@example.com';

is $config -> str('user.name', $name), $name;
is $config -> str('user.email', $email), $email;

my $me = Git::Raw::Signature -> default($repo);

my $commit = $repo -> commit("initial commit\n", $me, $me, [],
	$index -> write_tree);

my $initial_head = $repo -> head;
my $branch1 = $repo -> branch('branch1', $initial_head -> target);
my $branch2 = $repo -> branch('branch2', $initial_head -> target);
my $branch3 = $repo -> branch('branch3', $initial_head -> target);

$repo -> head($branch1);
write_file($file1, 'this is file1 on branch1');
$index -> add('test1');
$index -> write;

my $commit1 = $repo -> commit("commit on branch1\n", $me, $me, [$branch1 -> target],
	$index -> write_tree);

my $master  = Git::Raw::Branch -> lookup($repo, 'master', 1);
$repo -> checkout($repo -> head($master), {
	'checkout_strategy' => {
		'safe_create' => 1
	}
});

ok (!eval { $repo -> merge_base("refs/heads/master", substr($commit1 -> id, 0, 2)) });
ok (!eval { $repo -> merge_base("refs/heads/master", sub {}) });
ok (!eval { $repo -> merge_base($master) });
ok (!eval { $repo -> merge_base($master, 'refs/heads/unknown_branch') });

my $mb = $repo -> merge_base("refs/heads/master", $commit1 -> id);
isa_ok $mb, 'Git::Raw::Commit';
is $mb -> id, "$mb";

is $master -> target -> id, $repo -> merge_base("refs/heads/master", $commit1 -> id);
is $master -> target -> id, $repo -> merge_base("refs/heads/master", $commit1) -> id;
is $master -> target -> id, $repo -> merge_base("refs/heads/master", substr($commit1 -> id, 0, 7)) -> id;
is $master -> target -> id, $repo -> merge_base($master, $commit1) -> id;
is $master -> target -> id, $repo -> merge_base($master, 'refs/heads/branch1') -> id;

my $r = $repo -> merge_analysis($branch1);
is_deeply $r, ['normal', 'fast_forward'];

ok (!eval { $repo -> merge($branch1, {
	'flags' => [
		undef,
		'bogus_flag'
	]
})});

ok (!eval { $repo -> merge($branch1, {
	'favor' => 'bogus',
})});

$repo -> merge($branch1, {
		'rename_threshold' => 50,
		'target_limit'     => 200,
	}, {
		'checkout_strategy' => {
			'force' => 1
		}
	}
);

is $repo -> index -> has_conflicts, 0;
is_deeply $repo -> status({}) -> {'test1'}, {'flags' => ['index_modified']};

$master -> target($commit1);
$master = Git::Raw::Branch -> lookup ($repo, 'master', 1);

is_deeply $repo -> status({}) -> {'test1'}, undef;

$repo -> checkout($repo -> head($branch2), {
	'checkout_strategy' => {
		'force' => 1
	}
});

write_file($file1, 'this is file1 on branch2');
$index -> add('test1');
$index -> write;

my $commit2 = $repo -> commit("commit on branch2\n", $me, $me, [$branch2 -> target],
	$index -> write_tree);

$repo -> checkout($repo -> head($master), {
	'checkout_strategy' => {
		'force' => 1
	}
});

is $branch2 -> target -> id, $repo -> merge_base($branch2, $commit2) -> id;
is $commit -> id, $repo -> merge_base($commit1, $commit2) -> id;

$r = $repo ->merge_analysis($branch2);
is_deeply $r, ['normal'];

Git::Raw::Graph -> is_descendant_of($repo, $branch1, $branch2), 0;
Git::Raw::Graph -> is_descendant_of($repo, $branch2, $branch1), 0;

$repo -> merge($branch2);
is $index -> has_conflicts, 1;

my @conflicts = $index -> conflicts;
is scalar(@conflicts), 1;

my $conflict = shift @conflicts;
isa_ok $conflict, 'Git::Raw::Index::Conflict';

my $ancestor_entry = $conflict -> ancestor;
my $our_entry = $conflict -> ours;
my $their_entry = $conflict -> theirs;
isa_ok $ancestor_entry, 'Git::Raw::Index::Entry';
isa_ok $ancestor_entry -> blob, 'Git::Raw::Blob';
isa_ok $our_entry, 'Git::Raw::Index::Entry';
isa_ok $our_entry -> blob, 'Git::Raw::Blob';
isa_ok $their_entry, 'Git::Raw::Index::Entry';
isa_ok $their_entry -> blob, 'Git::Raw::Blob';

my $merge_result = $index -> merge ($ancestor_entry,
	$their_entry, $our_entry, {
		'ancestor_label' => 'test1',
		'our_label'      => 'HEAD',
		'their_label'    => 'branch2',
		'flags'          => {
			'merge' => 1
		}
});
isa_ok $merge_result, 'Git::Raw::Merge::File::Result';
is $merge_result -> automergeable, 0;
is $merge_result -> path, $ancestor_entry -> path;
is $merge_result -> path, $our_entry -> path;
is $merge_result -> path, $their_entry -> path;

$content = read_file($file1);
is $merge_result -> content, $content;

is $ancestor_entry -> path, 'test1';
is $our_entry -> path, 'test1';
is $their_entry -> path, 'test1';

my $dup = $ancestor_entry -> clone('test1.cloned');
isa_ok $dup, 'Git::Raw::Index::Entry';
is $dup -> path, 'test1.cloned';
is $dup -> id, $ancestor_entry -> id;

$merge_result = $index -> merge ($ancestor_entry,
	$their_entry, $our_entry, {
		'favor' => 'ours'
});
is $merge_result -> automergeable, 1;

$merge_result = eval { $index -> merge ($ancestor_entry,
	$their_entry, $our_entry, { 'favor' => 'blah' }) };
is $merge_result, undef;

is length($ancestor_entry -> id), 40;
is length($our_entry -> id), 40;
is length($their_entry -> id), 40;

ok $ancestor_entry -> id ne $our_entry -> id;
ok $ancestor_entry -> id ne $their_entry -> id;
ok $our_entry -> id ne $their_entry -> id;

$index -> remove_conflict('test1');
is $index -> has_conflicts, 0;

$index -> add_conflict($ancestor_entry, $their_entry, $our_entry);
is $index -> has_conflicts, 1;
$conflict = $index -> get_conflict('test1');
isa_ok $conflict, 'Git::Raw::Index::Conflict';
is $conflict -> ancestor -> id, $ancestor_entry -> id;
is $conflict -> ours -> id, $our_entry -> id;
is $conflict -> theirs -> id, $their_entry -> id;

$index -> remove_conflict('test1');
is $index -> has_conflicts, 0;

$index -> conflict_cleanup;
$repo -> state_cleanup;
write_file($file1, 'this is file1 on branch1');
$index -> add('test1');
$index -> write();

is $index -> has_conflicts, 0;
$repo -> merge($branch2);
is $index -> has_conflicts, 1;

write_file($file1, 'this is file1 on branch1 and branch2');
$index -> add('test1');
$index -> write;

my $merge_msg = $repo -> message();
is $merge_msg, "Merge branch 'branch2'\n\nConflicts:\n\ttest1\n";

my $target = $master -> target;
$commit = $repo -> commit("Merge commit!", $me, $me, [$target, $commit2],
	$index -> write_tree);

Git::Raw::Graph -> is_descendant_of($repo, $commit, $target), 1;
Git::Raw::Graph -> is_descendant_of($repo, $commit, $commit2), 1;
Git::Raw::Graph -> is_descendant_of($repo, $commit, 'refs/heads/branch2'), 1;
Git::Raw::Graph -> is_descendant_of($repo, $commit, 'branch2'), 1;
Git::Raw::Graph -> is_descendant_of($repo, $target, $commit), 0;
Git::Raw::Graph -> is_descendant_of($repo, $commit2, $commit), 0;

ok (!eval { Git::Raw::Graph -> ahead_behind($repo, "blah", $target) });
ok (!eval { Git::Raw::Graph -> ahead_behind($repo, $commit, "blah") });

my $ahead_behind = Git::Raw::Graph->ahead_behind ($repo, $commit, $target);
ok (exists($ahead_behind->{ahead}));
ok (!exists($ahead_behind->{behind}));
my $ahead = $ahead_behind->{ahead};
is scalar(@$ahead), 2;
is $ahead -> [0] -> id, $commit -> id;
is $ahead -> [1] -> id, $commit2 -> id;

$ahead_behind = Git::Raw::Graph->ahead_behind ($repo, $target, $commit);
ok (exists($ahead_behind->{behind}));
ok (!exists($ahead_behind->{ahead}));
my $behind = $ahead_behind->{behind};
is scalar(@$behind), 2;
is $behind -> [0] -> id, $commit -> id;
is $behind -> [1] -> id, $commit2 -> id;

ok (!eval { Git::Raw::Graph -> ahead($repo, "blah", $target) });
ok (!eval { Git::Raw::Graph -> ahead($repo, $commit, "blah") });

Git::Raw::Graph -> ahead($repo, $commit, $target);
my $ahead_count = Git::Raw::Graph -> ahead($repo, $commit, $target);
is $ahead_count, 2;
my @a = Git::Raw::Graph -> ahead($repo, $commit, $target);
is scalar(@a), 2;
is_deeply $ahead, [@a];

ok (!eval { Git::Raw::Graph -> behind($repo, "blah", $target) });
ok (!eval { Git::Raw::Graph -> behind($repo, $commit, "blah") });

Git::Raw::Graph -> behind($repo, $target, $commit);
my $behind_count = Git::Raw::Graph -> behind($repo, $target, $commit);
is $behind_count, 2;
my @b = Git::Raw::Graph -> behind($repo, $target, $commit);
is scalar(@b), 2;
is_deeply $behind, [@b];

is $repo -> state, "merge";
$repo -> state_cleanup;
is $repo -> state, "none";

$r = $repo ->merge_analysis($branch2);
is_deeply $r, ['up_to_date'];

$repo -> checkout($repo -> head($branch3), {
	'checkout_strategy' => {
		'force' => 1
	}
});

write_file($file1, 'this is file1 on branch3');
$index -> add('test1');
$index -> write;

$commit = $repo -> commit("commit on branch3\n", $me, $me, [$branch3 -> target],
	$index -> write_tree);

is (Git::Raw::Graph -> is_descendant_of($repo, $commit, $initial_head), 1);
is (Git::Raw::Graph -> is_descendant_of($repo, $commit -> id, $initial_head), 1);

$repo -> checkout($repo -> head($master), {
	checkout_strategy => {
		'force' => 1
}});

$r = $repo -> merge_analysis($branch3);
is_deeply $r, ['normal'];

$repo -> merge($branch3, {
	'favor' => 'theirs',
	}, {
	checkout_strategy => {
		'safe_create' => 1
	}
});

is $index -> has_conflicts, 0;

my $content = read_file($file1);
chomp ($content);
is $content, 'this is file1 on branch3';
is $repo -> state, "merge";
$repo -> state_cleanup;
is $repo -> state, "none";

$repo -> checkout($repo -> head($master), {
	checkout_strategy => {
		'force' => 1
	}
});

$r = $repo -> merge_analysis($branch3);
is_deeply $r, ['normal'];

$repo -> merge($branch3, {
	'favor' => 'ours',
});

is $index -> has_conflicts, 0;

$content = read_file($file1);
chomp ($content);
is $content, 'this is file1 on branch1 and branch2';
is $repo -> state, "merge";
$repo -> state_cleanup;
is $repo -> state, "none";

$master = $repo -> head;
my $head_commit = $master -> target;

write_file($file1, 'pre-commit merge');
$index -> add('test1');
$index -> write;

my $merge_commit1 = $repo -> commit("merge commit on branch1\n", $me, $me, [$head_commit],
	$index -> write_tree);

write_file($file1, 'post-commit merge');
$index -> add('test1');
$index -> write;

my $merge_commit2 = $repo -> commit("merge commit on branch1\n", $me, $me, [$merge_commit1],
	$index -> write_tree);

my $merged_index = $merge_commit1 -> merge($merge_commit2, {});
isa_ok $merged_index, 'Git::Raw::Index';
is $merged_index -> path, undef;
is $merged_index -> has_conflicts, 0;
my @merged_index_entries = $merged_index -> entries;
ok (scalar(@merged_index_entries) > 0);
$merged_index -> clear;
@merged_index_entries = $merged_index -> entries;
is scalar(@merged_index_entries), 0;

$merged_index = $merge_commit1 -> tree -> merge($head_commit -> tree, $merge_commit2 -> tree, {});
isa_ok $merged_index, 'Git::Raw::Index';
is $merged_index -> has_conflicts, 1;

$repo = undef;
rmtree $path;
ok ! -e $path;

done_testing;
