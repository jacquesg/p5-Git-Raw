#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $head = $repo -> head -> target;
my $tree = $head -> tree;

my $entries = $tree -> entries;

is $entries -> [0] -> name, 'test';
is $entries -> [1] -> name, 'test2';

my $obj0 = $entries -> [0] -> object($repo);

isa_ok $obj0, 'Git::Raw::Blob';
is $obj0 -> content, 'this is a test';
is $obj0 -> size, '14';

my $obj1 = $entries -> [1] -> object($repo);

isa_ok $obj1, 'Git::Raw::Blob';
is $obj1 -> content, 'this is a second test';
is $obj1 -> size, '21';

is $entries -> [2], undef;

done_testing;
