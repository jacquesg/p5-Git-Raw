#!perl

BEGIN {
  unless ($ENV{NETWORK_TESTING} or $ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'remote clone tests require network');
  }
}

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $url  = 'git://github.com/ghedo/p5-Algorithm-URL-Shorten.git';
my $path = abs_path('t/test_repo_clone');

my $origin = Git::Raw::Remote -> new(undef, 'origin', $url, '');

my $repo = Git::Raw::Repository -> clone(
	$origin, $path, { "update_missing" => 1 }, 0
);

ok !$repo -> is_bare;
ok !$repo -> is_empty;

is_deeply $repo -> status('Changes'), [];

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
