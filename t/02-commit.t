#!perl

use Test::More;

use Git::Raw;
use File::Slurp;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $file  = $repo -> workdir . 'test';
write_file($file, 'this is a test');

ok eq_array($repo -> status('test'), ['worktree_new']);

my $index = $repo -> index;
$index -> add('test');
$index -> write;

my $tree_id = $index -> write_tree;
my $tree    = $repo -> lookup($tree_id);

ok eq_array($repo -> status('test'), ['index_new']);

isa_ok $tree, 'Git::Raw::Tree';

my $config = $repo -> config;
my $name   = $config -> str('user.name');
my $email  = $config -> str('user.email');

my $time = time();
my $off  = 120;
my $me   = Git::Raw::Signature -> new($name, $email, $time, $off);

my $commit = $repo -> commit("initial commit\n", $me, $me, [], $tree);

ok eq_array($repo -> status('test'), []);

my $author = $commit -> author;

is $commit -> message, "initial commit\n";

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

$file  = $repo -> workdir . 'test2';
write_file($file, 'this is a second test');

$index -> add('test2');
$index -> write;

$tree_id = $index -> write_tree;
$tree    = $repo -> lookup($tree_id);

my $commit2 = $repo -> commit(
	"second commit\n", $me, $me, [$repo -> head], $tree
);

my $head = $repo -> head;

isa_ok $head, 'Git::Raw::Commit';

is $head -> message, "second commit\n";

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

my $parents = $head -> parents;

is $parents -> [0] -> message, "initial commit\n";

done_testing;
