#!perl

use Test::More;

use Git::Raw;
use File::Slurp::Tiny qw(write_file read_file);
use File::Spec::Functions qw(catfile rel2abs);

my $path = rel2abs(catfile('t', 'test_repo'));
my $repo = Git::Raw::Repository -> open($path);

my $initial_head = $repo -> head;
my $branch = $repo -> branch('rbranch', $initial_head -> target);

$repo -> checkout($repo -> head($branch), {
	'checkout_strategy' => {
		'force' => 1
	}
});

my $file1 = $repo -> workdir . 'revert_file';
write_file($file1, 'this is revert_file');

my $index = $repo -> index;
is $index -> has_conflicts, 0;
$index -> add('revert_file');
$index -> write;

is_deeply $repo -> status({}) -> {'revert_file'} -> {'flags'}, ['index_new'];

my $me = Git::Raw::Signature -> default($repo);
my $commit1 = $repo -> commit("commit1 on rbranch\n", $me, $me, [$branch -> target],
	$index -> write_tree);

is $repo -> status({}) -> {'revert_file'}, undef;

write_file($file1, "this is revert_file\nwith some more modifications\nand some more");
$index -> add('revert_file');
$index -> write;

is_deeply $repo -> status({}) -> {'revert_file'} -> {'flags'}, ['index_modified'];

my $commit2 = $repo -> commit("commit2 on rbranch\n", $me, $me, [$commit1],
	$index -> write_tree);

is $repo -> status({}) -> {'revert_file'}, undef;

my $revert_branch = $repo -> branch('revert_branch', $commit2);
$repo -> checkout($repo -> head($revert_branch), {
	'checkout_strategy' => {
		'force' => 1
	}
});

ok (!eval { $repo -> revert($commit2, {}, {}, 9999) });
$repo -> revert($commit2, {}, {}, 0);

is_deeply $repo -> status({}) -> {'revert_file'} -> {'flags'}, ['index_modified'];

is read_file($file1), 'this is revert_file';

my $revert_commit = $repo -> commit("revert commit1\n", $me, $me, [$commit2],
	$index -> write_tree);

is_deeply $repo -> status({}) -> {'revert_file'}, undef;
is $revert_commit -> tree -> id, $commit1 -> tree -> id;

is $repo -> state, "revert";
$repo -> state_cleanup;
is $repo -> state, "none";

my $main = Git::Raw::Branch -> lookup($repo, 'main', 1);
$index -> read_tree($main -> target -> tree);
$index -> write;

$repo -> checkout($main -> target -> tree, {
	'checkout_strategy' => {
		'safe' => 1
	}
});

$repo -> head($main);

done_testing;
