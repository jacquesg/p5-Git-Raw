#!perl

use Test::More;

use File::Spec::Functions qw(catfile rel2abs);
use File::Path qw(rmtree);

my @repos = (qw(test_repo rebase_repo));
foreach my $repo (@repos) {
	my $path = rel2abs(catfile('t', $repo));

	rmtree $path;
	ok ! -e $path;
}

my $odb_path = rel2abs(catfile('t', 'odb'));
rmtree $odb_path;
ok ! -e $odb_path;

done_testing;
