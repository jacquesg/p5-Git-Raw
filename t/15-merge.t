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

my $branch1 = $repo -> branch('branch1', $repo -> head -> target);
my $branch2 = $repo -> branch('branch2', $repo -> head -> target);
my $branch3 = $repo -> branch('branch3', $repo -> head -> target);

$repo -> head($branch1);
write_file($file1, 'this is file1 on branch1');
$index -> add('test1');
$index -> write;

$commit = $repo -> commit("commit on branch1\n", $me, $me, [$branch1 -> target],
	$repo -> lookup($index -> write_tree));

my $master  = Git::Raw::Branch -> lookup($repo, 'master', 1);
$repo -> checkout($repo -> head($master), {
	'checkout_strategy' => {
		'safe_create' => 1
	}
});

my $r = $repo -> merge($branch1, {
	'checkout_opts' => {
		'checkout_strategy' => {
			'force' => 1
		}
	}
});

is_deeply $r, {'up_to_date' => 0, 'fast_forward' => 1, 'id' => $commit -> id};
is $repo -> index -> has_conflicts, 0;
is_deeply $repo -> status -> {'test1'}, {'flags' => ['index_modified']};

$master -> target($commit);
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

$commit = $repo -> commit("commit on branch2\n", $me, $me, [$branch2 -> target],
	$repo -> lookup($index -> write_tree));

$repo -> checkout($repo -> head($master), {
	'checkout_strategy' => {
		'force' => 1
	}
});

ok !eval { $repo -> merge($branch2, {
	'flags' => {
		'fastforward_only' => 1,
	}
})};

ok eval { $r = $repo -> merge($branch2, {
	'flags' => {
		'no_fastforward' => 1,
	}
})};

is_deeply $r, {'up_to_date' => 0, 'fast_forward' => 0};
is $repo -> index -> has_conflicts, 1;

write_file($file1, 'this is file1 on branch1 and branch2');
$index -> add('test1');
$index -> write;

$commit = $repo -> commit("Merge commit!", $me, $me, [$master -> target, $commit],
	$repo -> lookup($index -> write_tree));

is $repo -> state, "merge";
$repo -> state_cleanup;
is $repo -> state, "none";

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

$repo -> checkout($repo -> head($master), {
	checkout_strategy => {
		'force' => 1
}});

ok eval { $r = $repo -> merge($branch3, {
	'tree_opts' => {
		'automerge' => 'favor_theirs',
	}
})};

is $repo -> index -> has_conflicts, 0;
is_deeply $r, {'up_to_date' => 0, 'fast_forward' => 0};

my $content = read_file($file1);
chomp ($content);
is $content, 'this is file1 on branch3';
is $repo -> state, "merge";
$repo -> state_cleanup;
is $repo -> state, "none";

$repo -> checkout($repo -> head($master), {
	checkout_strategy => {
		'force' => 1
}});

ok eval { $r = $repo -> merge($branch3, {
	'tree_opts' => {
		'automerge' => 'favor_ours',
	}
})};

is $repo -> index -> has_conflicts, 0;
is_deeply $r, {'up_to_date' => 0, 'fast_forward' => 0};

$content = read_file($file1);
chomp ($content);
is $content, 'this is file1 on branch1 and branch2';
is $repo -> state, "merge";
$repo -> state_cleanup;
is $repo -> state, "none";

$repo = undef;
rmtree $path;
ok ! -e $path;

done_testing;
