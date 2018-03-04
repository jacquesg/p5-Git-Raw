#!perl

use Test::More;

use File::Spec::Functions qw(catfile rel2abs);
use File::Path qw(rmtree);

my $repo_path = rel2abs(catfile('t', 'test_repo'));
my $worktree_path1 = rel2abs(catfile('t', 'test_repo_myworktree1'));
my $worktree_path2 = rel2abs(catfile('t', 'test_repo_myworktree2'));
my $odb_path = rel2abs(catfile('t', 'odb'));

rmtree $repo_path;
ok ! -e $repo_path;

rmtree $odb_path;
ok ! -e $odb_path;

done_testing;
