#!perl

use Test::More;

use Git::Raw;
use File::Slurp::Tiny qw(write_file);
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $file  = $repo -> workdir . 'test';
write_file($file, 'this is a test for stash');

is_deeply $repo -> status({}) -> {'test'}, {'flags' => ['worktree_modified']};

my $config = $repo -> config;
my $name   = $config -> str('user.name');
my $email  = $config -> str('user.email');

my $me = Git::Raw::Signature -> now($name, $email);

ok ($repo -> stash($me, 'some stash'));

Git::Raw::Stash -> foreach($repo, sub {
	my ($i, $msg, $oid) = @_;

	is $i, 0;
	is $msg, 'On master: some stash';

	0;
});

is $repo -> stash($me, 'some stash'), undef;

Git::Raw::Stash -> drop($repo, 0);

Git::Raw::Stash -> foreach($repo, sub { die 'This should not be called' });

my $untracked_file  = $repo -> workdir . 'untracked';
write_file($untracked_file, 'this is an untracked file');

$repo -> stash($me, 'stash untracked files', [undef, 'include_untracked']);

my @stashes;
Git::Raw::Stash -> foreach($repo, sub {
	my ($index, $msg, $id) = @_;
	push @stashes, { 'index' => $index, 'msg' => $msg, 'id' => $id };

	0;
});

is scalar(@stashes), 1;
is $stashes[0] -> {'msg'}, 'On master: stash untracked files';
ok (! -f $untracked_file);

write_file($untracked_file, 'this is an untracked file');
my $index = $repo -> index;
$index -> add('untracked');
$index -> write;

$repo -> stash($me, 'dont stash indexed files', ['keep_index']);

@stashes = ();
Git::Raw::Stash -> foreach($repo, sub {
	my ($index, $msg, $id) = @_;
	push @stashes, { 'index' => $index, 'msg' => $msg, 'id' => $id };

	0;
});

is scalar(@stashes), 2;
is $stashes[0] -> {'msg'}, 'On master: dont stash indexed files';
ok (-f $untracked_file);

$repo -> ignore("ignored\n");
my $ignored_file = $repo -> workdir . 'ignored';
write_file($ignored_file, 'this is an ignored file');

$repo -> stash($me, 'stash ignored files', ['include_ignored']);

@stashes = ();
Git::Raw::Stash -> foreach($repo, sub {
	my ($index, $msg, $id) = @_;
	push @stashes, { 'index' => $index, 'msg' => $msg, 'id' => $id };

	0;
});

is scalar(@stashes), 3;
is $stashes[0] -> {'msg'}, 'On master: stash ignored files';
ok (! -f $untracked_file);
ok (! -f $ignored_file);

done_testing;
