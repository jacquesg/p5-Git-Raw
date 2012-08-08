#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $head = $repo -> head;
my $tree = $head -> tree;

my $entries = $tree -> entries;

is($entries -> [0] -> name, 'test');
isa_ok($entries -> [0] -> object($repo), 'Git::Raw::Blob');

is($entries -> [1] -> name, 'test2');
isa_ok($entries -> [1] -> object($repo), 'Git::Raw::Blob');

is($entries -> [2], undef);

done_testing;
