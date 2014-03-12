#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);
use File::Path qw(make_path rmtree);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

# my $name = 'some_remote';
my $name = 'github';
my $url  = 'git://github.com/ghedo/a_git_repository.git';

my $github = Git::Raw::Remote -> create($repo, $name, $url);

is $github -> name, $name;
is $github -> url, $url;

my @remotes = $repo -> remotes;

is $remotes[0] -> name, $name;
is $remotes[0] -> url, $url;

is $remotes[1], undef;
@remotes = ();

$name = 'github';
$url  = 'git://github.com/ghedo/p5-Git-Raw.git';

# FIXME: remote rename
# is $github -> name($name), $name;
is $github -> url($url), $url;

unless ($ENV{NETWORK_TESTING} or $ENV{RELEASE_TESTING}) {
	diag('remote fetch tests require network');
	done_testing;
	exit;
}

$github = Git::Raw::Remote -> load($repo, 'github');

$github -> connect('fetch');
is $github -> is_connected, 1;

$github -> download;
$github -> update_tips;

my $ref = Git::Raw::Reference -> lookup('refs/remotes/github/master', $repo);
is $ref -> type, 'direct';

my $head = $ref -> target;
isa_ok $head, 'Git::Raw::Commit';

is $head -> author -> name, 'Alessandro Ghedini';

my $reflog = $ref -> reflog;
my @entries = $reflog -> entries;
is scalar(@entries), 1;

ok !defined($entries[0] -> {'message'});
is $entries[0] -> {'old_id'}, '0000000000000000000000000000000000000000';
is $entries[0] -> {'new_id'}, $ref -> target -> id;

$repo = Git::Raw::Repository -> new();
$github = Git::Raw::Remote -> create_inmemory($repo, undef, $url);

$github -> connect('fetch');
is $github -> is_connected, 1;

my $ls = $github -> ls;

is_deeply $ls -> {'HEAD'}, $ls -> {'refs/heads/master'};

make_path ('t/callbacks_repo');
$path = abs_path('t/callbacks_repo');
$repo = Git::Raw::Repository -> init ($path, 0);

$github = Git::Raw::Remote -> create($repo, $name, $url);

my ($progress, $transfer_progress, $update_tips);
$github -> callbacks({
	'progress' => sub {
		$progress = 1;
	},
	'transfer_progress' => sub {
		$transfer_progress = 1;
	},
	'update_tips' => sub {
		my ($ref, $a, $b) = @_;
		ok $ref =~ /^refs\//;
		ok $a eq '0000000000000000000000000000000000000000';
		ok length($b) == 40;

		$update_tips = 1;
	}
});

$github -> connect('fetch');
is $github -> is_connected, 1;

$github -> download;
ok $progress;
ok $transfer_progress;

my $config = $repo -> config;

$name  = 'Git::Raw author';
$email = 'git-xs@example.com';

is $config -> str('user.name', $name), $name;
is $config -> str('user.email', $email), $email;

$github -> update_tips;
ok $update_tips;

$repo = undef;
$github = undef;
rmtree $path;
ok ! -e $path;

done_testing;
