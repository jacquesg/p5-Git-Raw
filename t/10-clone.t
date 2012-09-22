#!perl

BEGIN {
  unless ($ENV{NETWORK_TESTING} or $ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'remote clone require network');
  }
}

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $url  = 'git://github.com/ghedo/p5-Algorithm-URL-Shorten.git';
my $path = abs_path('t/test_repo_clone');
my $repo = Git::Raw::Repository -> clone($url, $path, 0);

TODO: {
	local $TODO = 'fail';

	is $repo -> is_bare, 0;
	is $repo -> is_empty, 0;
}

my $remotes = $repo -> remotes;

is $remotes -> [0] -> name, 'origin';
is $remotes -> [0] -> url, $url;
is $remotes -> [1], undef;

my $ref = Git::Raw::Branch -> lookup($repo, 'master', 1);
is $ref -> type, 'direct';

my $head = $ref -> target($repo);
isa_ok $head, 'Git::Raw::Commit';

is $head -> author -> name, 'Alessandro Ghedini';

done_testing;
