#!perl

use Test::More;

use File::Spec::Functions qw(catfile rel2abs);
use File::Path qw(rmtree);

my $path = rel2abs(catfile('t', 'test_repo'));

rmtree $path;
ok ! -e $path;

done_testing;
