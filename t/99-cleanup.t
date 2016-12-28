#!perl

use Test::More;

use File::Spec::Functions qw(catfile rel2abs);
use File::Path qw(rmtree);

my $path = rel2abs(catfile('t', 'test_repo'));
my $odb_path = rel2abs(catfile('t', 'odb'));

rmtree $path;
ok ! -e $path;

rmtree $odb_path;
ok ! -e $odb_path;

done_testing;
