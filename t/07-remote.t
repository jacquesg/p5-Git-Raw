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
my $pushurl  = 'git://github.com/ghedo/a_git_repository_push_only.git';

my $github = Git::Raw::Remote -> create($repo, $name, $url);
my $repo2 = $github -> owner;
isa_ok $repo2, 'Git::Raw::Repository';
is $repo2 -> path, $repo -> path;

is $github -> name, $name;
is $github -> url, $url;
is $github -> pushurl, undef;
is $github -> pushurl($pushurl), $pushurl;
is $github -> refspec_count, 1;
my @refspecs = $github -> refspecs;
is scalar(@refspecs), 1;

my $refspec = shift @refspecs;
is $refspec -> src, "refs/heads/*";
is $refspec -> dst, "refs/remotes/github/*";
is $refspec -> direction, "fetch";
is $refspec -> string, "+refs/heads/*:refs/remotes/github/*";
is $refspec -> is_force, 1;
is $refspec -> transform ('refs/heads/main'), "refs/remotes/github/main";
is $refspec -> src_matches('refs/heads/main'), 1;
is $refspec -> rtransform ('refs/remotes/github/main'), "refs/heads/main";
is $refspec -> dst_matches('refs/remotes/github/main'), 1;
is $refspec -> dst_matches('refs/remotes/blah/main'), 0;
is $refspec, $refspec -> string;

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

$customfetch = Git::Raw::Remote -> create($repo, 'tagfetch', $url, "refs/tags/v0.0.1:refs/tags/v0.0.1" );
@refspecs = $customfetch -> refspecs;

is scalar(@refspecs), 1;
$refspec = shift @refspecs;

is $refspec -> src, "refs/tags/v0.0.1";
is $refspec -> dst, "refs/tags/v0.0.1";
is $refspec -> direction, "fetch";
is $refspec -> string, "refs/tags/v0.0.1:refs/tags/v0.0.1";

@remotes = $repo -> remotes;
is scalar(@remotes), 3;
Git::Raw::Remote -> delete($repo, 'tagfetch');
@remotes = $repo -> remotes;
is scalar(@remotes), 2;
@remotes = ();

$name = 'github';
$url  = 'https://github.com/libgit2/TestGitRepository.git';

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

is $github -> pushurl, $pushurl;

ok (!eval { $github -> default_branch });
ok (!eval { $github -> connect('invalid_direction') });
$github -> connect('fetch');
is $github -> default_branch, 'refs/heads/master';
is $github -> is_connected, 1;

$github -> download;
$github -> update_tips;

my $pruned = 0;
$github -> prune({
	'callbacks' => {
		'update_tips' => sub {
			my ($ref, $a, $b) = @_;
			$pruned = 1;
		}
	}
});
is $pruned, 0;

$github -> add_fetch("+refs/namespace/*:refs/origin/namespace/*");
$github -> add_push("+refs/namespace/*:refs/namespace/*");

$github -> disconnect;
is $github -> is_connected, 0;

$github -> fetch ({
	'callbacks' => {}
});
is $github -> is_connected, 0;

my $ref = Git::Raw::Reference -> lookup('refs/remotes/github/master', $repo);
is $ref -> type, 'direct';

my $dwim = Git::Raw::Reference -> lookup('github/master', $repo);
isa_ok $dwim, 'Git::Raw::Reference';
is $dwim -> name, $ref -> name;

my $non_existent_ref = Git::Raw::Reference -> lookup('github/non-existent', $repo);
is $non_existent_ref, undef;

my $main = Git::Raw::Branch -> lookup ($repo, 'main', 1);
ok ($main);
my $upstream = $main -> upstream;
is $upstream, undef;

ok (!eval { $main -> upstream($repo -> head -> target) });

$upstream = $main -> upstream($ref);
isa_ok $upstream, 'Git::Raw::Reference';
is $upstream -> name, $ref -> name;

$upstream = $main -> upstream(undef);
is $upstream, undef;

$upstream = $main -> upstream($ref -> shorthand);
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

$path = rel2abs(catfile('t', 'refspecs_repo'));
make_path($path);

$repo = Git::Raw::Repository -> init ($path, 0);
$github = Git::Raw::Remote -> create_anonymous($repo, $url);

$github->download({}, ['refs/heads/no-parent:']);

isa_ok $repo->lookup($ls -> {'refs/heads/no-parent'} -> {'id'}), 'Git::Raw::Commit';
is $repo->lookup($ls -> {'refs/heads/master'} -> {'id'}), undef;

rmtree $path;
ok ! -e $path;

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
