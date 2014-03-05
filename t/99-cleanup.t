#!perl

use Test::More;

use Cwd qw(abs_path);
use File::Path qw(rmtree);

my $path = abs_path('t').'/test_repo';

rmtree($path);
ok ! -e $path;

done_testing;
