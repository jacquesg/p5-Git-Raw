#!perl

use Test::More;

use Git::Raw;
use File::Slurp;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $initial_head = $repo -> head;
my $branch = $repo -> branch('cbranch', $initial_head -> target);
my $cherry_pick_branch = $repo -> branch('cherry_pick_branch', $initial_head -> target);

$repo -> checkout($repo -> head($branch), {
	'checkout_strategy' => {
		'safe' => 1
	}
});

my $file1 = $repo -> workdir . 'cherry_file';
write_file($file1, 'this is cherry_file');

my $index = $repo -> index;
$index -> add('cherry_file');
$index -> write;

is_deeply $repo -> status -> {'cherry_file'} -> {'flags'}, ['index_new'];

my $me = Git::Raw::Signature -> default($repo);
my $commit1 = $repo -> commit("commit1 on cbranch\n", $me, $me, [$branch -> target],
	$repo -> lookup($index -> write_tree));

is $repo -> status -> {'cherry_file'}, undef;

write_file($file1, "this is cherry_file\nwith some more modifications\nand some more");
$index -> add('cherry_file');
$index -> write;

is_deeply $repo -> status -> {'cherry_file'} -> {'flags'}, ['index_modified'];

my $commit2 = $repo -> commit("commit2 on cbranch\n", $me, $me, [$commit1],
	$repo -> lookup($index -> write_tree));

is $repo -> status -> {'cherry_file'}, undef;

$repo -> checkout($repo -> head($cherry_pick_branch), {
	'checkout_strategy' => {
		'force' => 1
	}
});

isnt -f $file1, 1;
is $repo -> status -> {'cherry_file'}, undef;

$repo -> cherry_pick($commit1);

is_deeply $repo -> status -> {'cherry_file'} -> {'flags'}, ['index_new'];
is $index -> has_conflicts, 0;

ok (!eval { $repo -> cherry_pick($commit2) });

my $c_commit1 = $repo -> commit("commit1 on cbranch\n", $me, $me, [$cherry_pick_branch -> target],
	$repo -> lookup($index -> write_tree));

is $repo -> status -> {'cherry_file'}, undef;

my $cherry_pick_conflict_branch = $repo -> branch('cherry_pick_conflict_branch', $c_commit1);

$repo -> cherry_pick($commit2);
is_deeply $repo -> status -> {'cherry_file'} -> {'flags'}, ['index_modified'];
is $index -> has_conflicts, 0;

ok (!eval { $repo -> cherry_pick($commit2) });

my $c_commit2 = $repo -> commit("commit2 on cbranch\n", $me, $me, [$c_commit1],
	$repo -> lookup($index -> write_tree));

is $branch -> target -> tree -> id, $cherry_pick_branch -> target -> tree -> id;

$repo -> cherry_pick($commit2);
is $index -> has_conflicts, 0;
is $repo -> state, "cherry_pick";
$repo -> state_cleanup;
is $repo -> state, "none";

my $head = $repo -> head($cherry_pick_conflict_branch);
$repo -> checkout($head -> target -> tree, {
	'checkout_strategy' => {
		'force' => 1
	}
});

$index -> read(1);
is $repo -> status -> {'cherry_file'}, undef;

write_file($file1, "this is cherry_file\nwith some conflict producing modifications");
$index -> add('cherry_file');
$index -> write;

my $conflict_commit1 = $repo -> commit("conflict commit on cbranch\n", $me, $me, [$cherry_pick_conflict_branch -> target],
	$repo -> lookup($index -> write_tree));

ok (!eval { $repo -> cherry_pick($commit2, {}, {}, 9999) });
$repo -> cherry_pick($commit2, {}, {}, 0);
is $index -> has_conflicts, 1;

write_file($file1, "resolved!");
$index -> add('cherry_file');
is $index -> has_conflicts, 0;

my $conflict_commit2 = $repo -> commit("commit2 on cbranch\n", $me, $me, [$conflict_commit1],
	$repo -> lookup($index -> write_tree));

is $index -> has_conflicts, 0;
is $repo -> status -> {'cherry_file'}, undef;
isnt $branch -> target -> tree -> id, $cherry_pick_conflict_branch -> target -> tree -> id;

my $master = Git::Raw::Branch -> lookup($repo, 'master', 1);
$index -> read_tree($master -> target -> tree);
$index -> write;

$repo -> checkout($master -> target -> tree, {
	'checkout_strategy' => {
		'safe' => 1
	}
});

$head = $repo -> head($master);

is $index -> has_conflicts, 0;
is $repo -> status -> {'cherry_file'}, undef;

done_testing;
