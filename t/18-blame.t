#!perl

use Test::More;

use Git::Raw;
use File::Slurp;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $branch_name = 'blame_branch';

my $branch = $repo -> branch($branch_name, $repo -> head -> target);
is $branch -> type, 'direct';
is $branch -> name, "refs/heads/$branch_name";

$repo -> checkout($repo -> head($branch), {
	'checkout_strategy' => {
		'safe' => 1
	}
});

my $file  = $repo -> workdir . 'blame';
my @lines = ('line1', 'line2', 'line3', 'line4');
write_file($file, map { "$_\n" } @lines);

my $index = $repo -> index;
$index -> add('blame');
$index -> write;

my $me = Git::Raw::Signature -> default($repo);
my $commit1 = $repo -> commit("commit1 on blame branch\n", $me, $me, [$repo -> head -> target],
	$repo -> lookup($index -> write_tree));

@lines = ('line1', 'line2', 'line31', 'line4');
write_file($file, map { "$_\n" } @lines);
$index -> add('blame');
$index -> write;

my $commit2 = $repo -> commit("commit2 on blame branch\n", $me, $me, [$repo -> head -> target],
	$repo -> lookup($index -> write_tree));

@lines = ('line1', 'line2', 'line31', 'line41');
write_file($file, map { "$_\n" } @lines);
$index -> add('blame');
$index -> write;

my $commit3 = $repo -> commit("commit3 on blame branch\n", $me, $me, [$repo -> head -> target],
	$repo -> lookup($index -> write_tree));

my $blame = $repo -> blame('blame');
isa_ok $blame, 'Git::Raw::Blame';
is $blame -> hunk_count, 3;

my @hunks = $blame -> hunks;
is scalar(@hunks), 3;

my $hunk1 = shift @hunks;
is $hunk1 -> lines_in_hunk, 2;
is $hunk1 -> final_commit_id, $commit1 -> id;
is $hunk1 -> final_start_line_number, 1;
is $hunk1 -> orig_commit_id, $commit1 -> id;
is $hunk1 -> orig_start_line_number, 1;
is $hunk1 -> orig_path, 'blame';
is $hunk1 -> boundary, 0;

my $hunk2 = shift @hunks;
is $hunk2 -> lines_in_hunk, 1;
is $hunk2 -> final_commit_id, $commit2 -> id;
is $hunk2 -> final_start_line_number, 3;
is $hunk2 -> orig_commit_id, $commit2 -> id;
is $hunk2 -> orig_start_line_number, 3;
is $hunk2 -> orig_path, 'blame';
is $hunk2 -> boundary, 0;

my $hunk3 = shift @hunks;
is $hunk3 -> lines_in_hunk, 1;
is $hunk3 -> final_commit_id, $commit3 -> id;
is $hunk3 -> final_start_line_number, 4;
is $hunk3 -> orig_commit_id, $commit3 -> id;
is $hunk3 -> orig_start_line_number, 4;
is $hunk3 -> orig_path, 'blame';
is $hunk3 -> boundary, 0;

@hunks = $blame -> hunks(2);
is scalar(@hunks), 1;
is $hunks[0] -> final_commit_id, $hunk3 -> final_commit_id;

my $line_hunk = $blame -> line(4);
is $line_hunk -> final_commit_id, $hunk3 -> final_commit_id;

my $master  = Git::Raw::Branch -> lookup($repo, 'master', 1);
$repo -> checkout($repo -> head($master), {
	'checkout_strategy' => {
		'force' => 1
	}
});

@lines = ('line11', 'line2', 'line31', 'line41');
my $memory_blame = $blame -> buffer(join ("\n", @lines));
my @memory_hunks = $memory_blame -> hunks(0);
is $memory_blame -> hunk_count, 4;

my $memory_hunk = shift @memory_hunks;
is $memory_hunk -> lines_in_hunk, 1;
is $memory_hunk -> final_commit_id, '0' x 40;
is $memory_hunk -> final_start_line_number, 1;
is $memory_hunk -> orig_commit_id, '0' x 40;
is $memory_hunk -> orig_start_line_number, 0;
is $memory_hunk -> orig_path, 'blame';

done_testing;
