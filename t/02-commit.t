#!perl

use Test::More;

use Git::Raw;
use File::Slurp;
use Cwd qw(abs_path);
use File::Path 2.07 qw(make_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $file  = $repo -> workdir . 'test';
write_file($file, 'this is a test');

is_deeply $repo -> status -> {'test'}, ['worktree_new'];

my $index = $repo -> index;
$index -> add('test');
$index -> write;

my $tree_id = $index -> write_tree;
my $tree    = $repo -> lookup($tree_id);

is_deeply $repo -> status -> {'test'}, ['index_new'];

isa_ok $tree, 'Git::Raw::Tree';

my $config = $repo -> config;
my $name   = $config -> str('user.name');
my $email  = $config -> str('user.email');

my $time = time();
my $off  = 120;
my $me   = Git::Raw::Signature -> new($name, $email, $time, $off);

my $commit = $repo -> commit("initial commit\n", $me, $me, [], $tree);

is_deeply $repo -> status -> {'test'}, undef;

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

$file  = $repo -> workdir . 'test2';
write_file($file, 'this is a second test');

$index -> add('test2');
$index -> write;

$tree_id = $index -> write_tree;
$tree    = $repo -> lookup($tree_id);

my $commit2 = $repo -> commit(
	"second commit\n", $me, $me, [$repo -> head -> target], $tree
);

my $head = $repo -> head -> target;

isa_ok $head, 'Git::Raw::Commit';

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

my $parents = $head -> parents;

is $parents -> [0] -> message, "initial commit\n";

make_path($repo -> workdir . 'test3/under/the/tree');
$file  = $repo -> workdir . 'test3/under/the/tree/test3';
write_file($file, 'this is a third test');

$index -> add('test3/under/the/tree/test3');
$index -> write;

$tree_id = $index -> write_tree;
$tree    = $repo -> lookup($tree_id);

my $commit3 = $repo -> commit(
	"third commit\n", $me, $me, [$repo -> head -> target], $tree
);

$head = $repo -> head -> target;

isa_ok $head, 'Git::Raw::Commit';

is $head -> message, "third commit\n";
is $head -> summary, "third commit";

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

done_testing;
