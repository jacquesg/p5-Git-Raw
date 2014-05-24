#!perl

use Test::More;

use Git::Raw;
use File::Spec;
use File::Slurp;
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
	$repo -> lookup($index -> write_tree));

my $initial_head = $repo -> head;
my $branch1 = $repo -> branch('branch1', $initial_head -> target);
my $branch2 = $repo -> branch('branch2', $initial_head -> target);
my $branch3 = $repo -> branch('branch3', $initial_head -> target);

$repo -> head($branch1);
write_file($file1, 'this is file1 on branch1');
$index -> add('test1');
$index -> write;

my $commit1 = $repo -> commit("commit on branch1\n", $me, $me, [$branch1 -> target],
	$repo -> lookup($index -> write_tree));

my $master  = Git::Raw::Branch -> lookup($repo, 'master', 1);
$repo -> checkout($repo -> head($master), {
	'checkout_strategy' => {
		'safe_create' => 1
	}
});

ok (!eval { $repo -> merge_base("refs/heads/master", substr($commit1 -> id, 0, 2)) });
ok (!eval { $repo -> merge_base("refs/heads/master", sub {}) });
is $master -> target -> id, $repo -> merge_base("refs/heads/master", $commit1 -> id);
is $master -> target -> id, $repo -> merge_base("refs/heads/master", $commit1);
is $master -> target -> id, $repo -> merge_base("refs/heads/master", substr($commit1 -> id, 0, 7));
is $master -> target -> id, $repo -> merge_base($master, $commit1);
is $master -> target -> id, $repo -> merge_base($master, 'refs/heads/branch1');

ok (!eval { $repo -> merge_base($master) });
ok (!eval { $repo -> merge_base($master, 'refs/heads/unknown_branch') });

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
is_deeply $repo -> status -> {'test1'}, {'flags' => ['index_modified']};

$master -> target($commit1);
$master = Git::Raw::Branch -> lookup ($repo, 'master', 1);

is_deeply $repo -> status -> {'test1'}, undef;

$repo -> checkout($repo -> head($branch2), {
	'checkout_strategy' => {
		'force' => 1
	}
});

write_file($file1, 'this is file1 on branch2');
$index -> add('test1');
$index -> write;

my $commit2 = $repo -> commit("commit on branch2\n", $me, $me, [$branch2 -> target],
	$repo -> lookup($index -> write_tree));

$repo -> checkout($repo -> head($master), {
	'checkout_strategy' => {
		'force' => 1
	}
});

is $branch2 -> target -> id, $repo -> merge_base($branch2, $commit2);
is $commit -> id, $repo -> merge_base($commit1, $commit2);

$r = $repo ->merge_analysis($branch2);
is_deeply $r, ['normal'];

Git::Raw::Graph -> is_descendant_of($repo, $branch1, $branch2), 0;
Git::Raw::Graph -> is_descendant_of($repo, $branch2, $branch1), 0;

$repo -> merge($branch2);
is $index -> has_conflicts, 1;

my @conflicts = $index -> conflicts;
is scalar(@conflicts), 1;

my $conflict = shift @conflicts;
my $ancestor_entry = $conflict -> {'ancestor'};
my $our_entry = $conflict -> {'ours'};
my $their_entry = $conflict -> {'theirs'};

is $ancestor_entry -> path, 'test1';
is $our_entry -> path, 'test1';
is $their_entry -> path, 'test1';

is length($ancestor_entry -> id), 40;
is length($our_entry -> id), 40;
is length($their_entry -> id), 40;

ok $ancestor_entry -> id ne $our_entry -> id;
ok $ancestor_entry -> id ne $their_entry -> id;
ok $our_entry -> id ne $their_entry -> id;

$index -> remove_conflict('test1');
is $index -> has_conflicts, 0;

$index -> conflict_cleanup;
write_file($file1, 'this is file1 on branch1');
$index -> add('test1');

$repo -> merge($branch2);
is $index -> has_conflicts, 1;

write_file($file1, 'this is file1 on branch1 and branch2');
$index -> add('test1');
$index -> write;

my $merge_msg = $repo -> message();
is $merge_msg, "Merge branch 'branch2'\n\nConflicts:\n\ttest1\n";

my $target = $master -> target;
$commit = $repo -> commit("Merge commit!", $me, $me, [$target, $commit2],
	$repo -> lookup($index -> write_tree));

Git::Raw::Graph -> is_descendant_of($repo, $commit, $target), 1;
Git::Raw::Graph -> is_descendant_of($repo, $commit, $commit2), 1;
Git::Raw::Graph -> is_descendant_of($repo, $commit, 'refs/heads/branch2'), 1;
Git::Raw::Graph -> is_descendant_of($repo, $commit, 'branch2'), 1;
Git::Raw::Graph -> is_descendant_of($repo, $target, $commit), 0;
Git::Raw::Graph -> is_descendant_of($repo, $commit2, $commit), 0;

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
	$repo -> lookup($index -> write_tree));

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
	$repo -> lookup($index -> write_tree));

write_file($file1, 'post-commit merge');
$index -> add('test1');
$index -> write;

my $merge_commit2 = $repo -> commit("merge commit on branch1\n", $me, $me, [$merge_commit1],
	$repo -> lookup($index -> write_tree));

my $merged_index = $merge_commit1 -> merge($merge_commit2, {});
isa_ok $merged_index, 'Git::Raw::Index';
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
