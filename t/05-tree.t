#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $head_id = $repo -> head -> target -> id;

my $head = $repo -> lookup($head_id);
ok $head -> tree -> entries -> [0] -> object;
$head = $repo -> lookup(substr($head_id, 0, 7));
ok $head -> tree -> entries -> [0] -> object;

$head = $repo -> head -> target;

$tree = $head -> tree;

ok $tree -> is_tree;
ok !$tree -> is_blob;

my $lookup_tree = Git::Raw::Tree -> lookup($repo, $tree -> id);
isa_ok $lookup_tree, 'Git::Raw::Tree';
$lookup_tree = Git::Raw::Tree -> lookup($repo, substr($tree -> id, 0, 7));
isa_ok $lookup_tree, 'Git::Raw::Tree';

my $entries = $tree -> entries;

is $entries -> [0] -> name, 'test';
is $entries -> [1] -> name, 'test2';
is $entries -> [2] -> name, 'test3';

is $entries -> [0] -> file_mode, 0100644;
is $entries -> [2] -> file_mode, 0040000;

my $obj0 = $entries -> [0] -> object;

isa_ok $obj0, 'Git::Raw::Blob';
is $obj0 -> content, 'this is a test';
is $obj0 -> size, '14';

my $obj1 = $entries -> [1] -> object;

isa_ok $obj1, 'Git::Raw::Blob';
is $obj1 -> content, 'this is a second test';
is $obj1 -> size, '21';

my $obj2 = $entries -> [2] -> object;

isa_ok $obj2, 'Git::Raw::Tree';

is $entries -> [3], undef;

my $entry = $tree -> entry_byname('test3');

isa_ok $entry, 'Git::Raw::Tree::Entry';
isa_ok $entry -> object, 'Git::Raw::Tree';

$entry = $tree -> entry_bypath('test3/under/the/tree/test3');

isa_ok $entry, 'Git::Raw::Tree::Entry';

my $obj4 = $entry -> object;

isa_ok $obj4, 'Git::Raw::Blob';
is $obj4 -> content, 'this is a third test';
is $obj4 -> size, '20';

done_testing;
