#!perl

use Test::More;

use Cwd qw(abs_path);
use File::Path qw(remove_tree);

my $path = abs_path('t').'/test_repo';
remove_tree($path);

ok 1;

done_testing;
