#!perl

use Test::More;

use File::Spec::Functions qw(catfile rel2abs);
use File::Path qw(rmtree);
use Git::Raw;

my @repos = (qw(test_repo rebase_repo test_repo_submodules));
foreach my $repo (@repos) {
	my $path = rel2abs(catfile('t', $repo));

	rmtree $path;
	ok ! -e $path;
}

my $odb_path = rel2abs(catfile('t', 'odb'));
rmtree $odb_path;
ok ! -e $odb_path;

my $fileName = rel2abs(catfile('t', 'initBranch'));
if (-e $fileName) {
	open my $fh, '<', $fileName or
		die "could not open '$fileName': $!";
	my $default = <$fh>;
	close $fh;

	my $config = Git::Raw::Config -> default();
	$config -> str('init.defaultBranch', $default);
	unlink $fileName;
}

done_testing;
