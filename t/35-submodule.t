#!perl
#
BEGIN {
  unless ($ENV{NETWORK_TESTING} or $ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'remote clone tests require network');
  }
}

use Test::More;
use File::Spec::Functions qw(catfile rel2abs);
use Git::Raw;
use File::Path qw(rmtree);

my $url = 'https://github.com/git-up/test-repo-submodules.git';
my $path = rel2abs(catfile('t', 'test_repo_submodules'));

my $repo = Git::Raw::Repository -> clone($url, $path, {});
ok !$repo -> is_bare;
ok !$repo -> is_empty;

my $name;
Git::Raw::Submodule -> foreach($repo, sub
	{
		$name = shift;
		return 0;
	}
);

is $name, 'base';
my $sm = Git::Raw::Submodule->lookup ($repo, $name);
isa_ok $sm, 'Git::Raw::Submodule';

is $sm -> name, 'base';
is $sm -> path, 'base';
is $sm -> url, 'https://github.com/git-up/test-repo-base.git';

my $sideband = 0;
my $transfer = 0;
$sm->update (1, {
	'checkout_opts' => {
		'checkout_strategy' => {
			'force' => 1
		}
	},
	'fetch_opts' => {
		'callbacks' => {
			'sideband_progress' => sub {
				++$sideband;
			},
			'transfer_progress' => sub {
				++$transfer;
			},
		}
	},
});
$sm->sync();
$sm->reload();

ok $sideband > 0;
ok $transfer > 0;

my $repo2 = $sm -> open;
isa_ok $repo2, 'Git::Raw::Repository';

done_testing;
