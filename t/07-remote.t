#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $name = 'github';
my $url  = 'git://github.com/ghedo/p5-Git-Raw.git';

my $github = Git::Raw::Remote -> add($repo, $name, $url);

my $remotes = $repo -> remotes;

is $remotes -> [0] -> name, $name;
is $remotes -> [0] -> url, $url;
is $remotes -> [1], undef;

$github -> connect('fetch');
is $github -> is_connected, 1;

unless ($ENV{NETWORK_TESTING}) {
	diag('remote fetch tests require network');
	done_testing;
	exit;
}

$github -> download;
$github -> update_tips;

my $ref = Git::Raw::Reference -> lookup('refs/remotes/github/master', $repo);
is $ref -> type, 'direct';

my $head = $ref -> target($repo);
isa_ok $head, 'Git::Raw::Commit';

is $head -> author -> name, 'Alessandro Ghedini';

done_testing;
