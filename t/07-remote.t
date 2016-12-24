#!perl

use Test::More;

use Git::Raw;
use File::Spec::Functions qw(catfile rel2abs);
use File::Path qw(make_path rmtree);

my $path = rel2abs(catfile('t', 'test_repo'));
my $repo = Git::Raw::Repository -> open($path);

# my $name = 'some_remote';
my $name = 'github';
my $url  = 'git://github.com/ghedo/a_git_repository.git';

my $github = Git::Raw::Remote -> create($repo, $name, $url);
my $repo2 = $github -> owner;
isa_ok $repo2, 'Git::Raw::Repository';
is $repo2 -> path, $repo -> path;

is $github -> name, $name;
is $github -> url, $url;
is $github -> pushurl, undef;
is $github -> pushurl($url), $url;
is $github -> refspec_count, 1;
my @refspecs = $github -> refspecs;
is scalar(@refspecs), 1;

my $refspec = shift @refspecs;
is $refspec -> src, "refs/heads/*";
is $refspec -> dst, "refs/remotes/github/*";
is $refspec -> direction, "fetch";
is $refspec -> string, "+refs/heads/*:refs/remotes/github/*";
is $refspec -> is_force, 1;
is $refspec -> transform ('refs/heads/master'), "refs/remotes/github/master";
is $refspec -> src_matches('refs/heads/master'), 1;
is $refspec -> rtransform ('refs/remotes/github/master'), "refs/heads/master";
is $refspec -> dst_matches('refs/remotes/github/master'), 1;
is $refspec -> dst_matches('refs/remotes/blah/master'), 0;

my $rename = Git::Raw::Remote -> create($repo, 'pre_rename', $url);
is $rename -> name, 'pre_rename';
my @problems;
Git::Raw::Remote -> rename($repo, 'pre_rename', 'post_rename', \@problems);
is scalar(@problems), 0;
$rename = Git::Raw::Remote -> load($repo, 'post_rename');

@refspecs = $rename -> refspecs;
is scalar(@refspecs), 1;

$rename = undef;

my @remotes = $repo -> remotes;

is $remotes[0] -> name, $name;
is $remotes[0] -> url, $url;

is $remotes[1] -> name, 'post_rename';
@remotes = ();

$name = 'github';
$url  = 'git://github.com/libgit2/TestGitRepository.git';

# FIXME: remote rename
# is $github -> name($name), $name;
is $github -> url($url), $url;

unless ($ENV{NETWORK_TESTING} or $ENV{RELEASE_TESTING}) {
	diag('remote fetch tests require network');
	done_testing;
	exit;
}

my $non_existent_remote = Git::Raw::Remote -> load($repo, 'nonexistent_remote');
is $non_existent_remote, undef;

$github = Git::Raw::Remote -> load($repo, 'github');
isa_ok $github, 'Git::Raw::Remote';

ok (!eval { $github -> default_branch });
ok (!eval { $github -> connect('invalid_direction') });
$github -> connect('fetch');
is $github -> default_branch, 'refs/heads/master';
is $github -> is_connected, 1;

$github -> download;
$github -> update_tips;

$github -> disconnect;
is $github -> is_connected, 0;

$github -> fetch;
is $github -> is_connected, 0;

my $ref = Git::Raw::Reference -> lookup('refs/remotes/github/master', $repo);
is $ref -> type, 'direct';

my $dwim = Git::Raw::Reference -> lookup('github/master', $repo);
isa_ok $dwim, 'Git::Raw::Reference';
is $dwim -> name, $ref -> name;

my $non_existent_ref = Git::Raw::Reference -> lookup('github/non-existent', $repo);
is $non_existent_ref, undef;

my $master = Git::Raw::Branch -> lookup ($repo, 'master', 1);
ok ($master);
my $upstream = $master -> upstream;
is $upstream, undef;

ok (!eval { $master -> upstream($repo -> head -> target) });

$upstream = $master -> upstream($ref);
isa_ok $upstream, 'Git::Raw::Reference';
is $upstream -> name, $ref -> name;

$upstream = $master -> upstream(undef);
is $upstream, undef;

$upstream = $master -> upstream($ref -> shorthand);
isa_ok $upstream, 'Git::Raw::Reference';
is $upstream -> name, $ref -> name;

my $head = $ref -> target;
isa_ok $head, 'Git::Raw::Commit';

is $head -> author -> name, 'A U Thor';

my $reflog = $ref -> reflog;
my @entries = $reflog -> entries;
is scalar(@entries), 1;

is $entries[0] -> message, undef;
is $entries[0] -> old_id, '0000000000000000000000000000000000000000';
is $entries[0] -> new_id, $ref -> target -> id;

$repo = Git::Raw::Repository -> new();
$github = Git::Raw::Remote -> create_anonymous($repo, $url);
$github -> connect('fetch');
is $github -> is_connected, 1;

my $ls = $github -> ls;

is_deeply $ls -> {'HEAD'}, $ls -> {'refs/heads/master'};

$path = rel2abs(catfile('t', 'callbacks_repo'));
make_path($path);

$repo = Git::Raw::Repository -> init ($path, 0);

$github = Git::Raw::Remote -> create($repo, $name, $url);

my ($sideband_progress, $transfer_progress);

is $github -> is_connected, 0;

$github -> download ({
	'callbacks' => {
		'sideband_progress' => sub {
			$sideband_progress = 1;
		},
		'transfer_progress' => sub {
			$transfer_progress = 1;
		},
	}
});

ok $sideband_progress;
ok $transfer_progress;

my $config = $repo -> config;

$name  = 'Git::Raw author';
$email = 'git-xs@example.com';

is $config -> str('user.name', $name), $name;
is $config -> str('user.email', $email), $email;

my $update_tips;
$github -> update_tips({
	'update_tips' => sub {
		my ($ref, $a, $b) = @_;
		ok $ref =~ /^refs\//;
		ok (!defined($a));
		ok length($b) == 40;

		$update_tips = 1;
	}
});
ok $update_tips;

$repo = undef;
$github = undef;
rmtree $path;
ok ! -e $path;

done_testing;
