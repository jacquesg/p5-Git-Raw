#!perl

use Test::More;

use Git::Raw;
use File::Spec::Functions qw(catfile rel2abs);
use File::Slurp::Tiny qw(write_file);

is 0, Git::Raw::Stash::Progress->NONE;
is 1, Git::Raw::Stash::Progress->LOADING_STASH;
is 2, Git::Raw::Stash::Progress->ANALYZE_INDEX;
is 3, Git::Raw::Stash::Progress->ANALYZE_MODIFIED;
is 4, Git::Raw::Stash::Progress->ANALYZE_UNTRACKED;
is 5, Git::Raw::Stash::Progress->CHECKOUT_UNTRACKED;
is 6, Git::Raw::Stash::Progress->CHECKOUT_MODIFIED;
is 7, Git::Raw::Stash::Progress->DONE;

my $path = rel2abs(catfile('t', 'test_repo'));
my $repo = Git::Raw::Repository -> open($path);

my $file  = $repo -> workdir . 'test';
write_file($file, 'this is a test for stash');

my $index = $repo -> index;
$index -> add ('test');
write_file($file, 'this is a test for stash2');

my $config = $repo -> config;
my $name   = $config -> str('user.name');

my $email  = $config -> str('user.email');

my $me = Git::Raw::Signature -> now($name, $email);

is_deeply $repo -> status({}) -> {'test'}, {'flags' => ['index_modified', 'worktree_modified']};
ok ($repo -> stash($me, 'some stash'));
is_deeply $repo -> status({}), {};

eval { Git::Raw::Stash -> foreach($repo, sub { 1; }) };
ok (!$@);

Git::Raw::Stash -> foreach($repo, sub {
	my ($i, $msg, $commit) = @_;

	is $i, 0;
	is $msg, 'On master: some stash';
	isa_ok $commit, 'Git::Raw::Commit';

	0;
});

is $repo -> stash($me, 'some stash'), undef;

my $count = 0;
my $apply_opts = {
	callbacks => {
		apply_progress => sub {
			my ($progress) = @_;
			$count++;
		}
	},
	flags => {
		reinstate_index => 1
	}
};
Git::Raw::Stash -> apply($repo, 0, $apply_opts);

write_file($file, 'this is a test for stash3');

is $count, 5;
is_deeply $repo -> status({}) -> {'test'}, {'flags' => ['index_modified', 'worktree_modified']};
ok ($repo -> stash($me, 'some stash'));
is_deeply $repo -> status({}), {};

$count = 0;
Git::Raw::Stash -> pop($repo, 0, $apply_opts);

is $count, 5;
is_deeply $repo -> status({}) -> {'test'}, {'flags' => ['index_modified', 'worktree_modified']};
ok ($repo -> stash($me, 'some stash'));
is_deeply $repo -> status({}), {};

my $count = 0;
Git::Raw::Stash -> foreach($repo, sub { $count++ });
is $count, 2;

Git::Raw::Stash -> drop($repo, 0);
Git::Raw::Stash -> drop($repo, 0);

Git::Raw::Stash -> foreach($repo, sub { die 'This should not be called' });

my $untracked_file  = $repo -> workdir . 'untracked';
write_file($untracked_file, 'this is an untracked file');

ok (!eval { $repo -> stash($me, 'stash bad', ['blah']) });

my $commit = $repo -> stash($me, 'stash untracked files', [undef, 'include_untracked']);
isa_ok $commit, 'Git::Raw::Commit';

my @stashes;
Git::Raw::Stash -> foreach($repo, sub {
	my ($index, $msg, $commit) = @_;
	push @stashes, { 'index' => $index, 'msg' => $msg, 'commit' => $commit };

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
	my ($index, $msg, $commit) = @_;
	push @stashes, { 'index' => $index, 'msg' => $msg, 'commit' => $commit };

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
	push @stashes, { 'index' => $index, 'msg' => $msg, 'commit' => $commit };

	0;
});

is scalar(@stashes), 3;
is $stashes[0] -> {'msg'}, 'On master: stash ignored files';
ok (! -f $untracked_file);
ok (! -f $ignored_file);

@stashes = ();
Git::Raw::Stash -> foreach($repo, sub {
	my ($index, $msg, $id) = @_;
	push @stashes, { 'index' => $index, 'msg' => $msg, 'commit' => $commit };

	return 1 if (scalar(@stashes));
	0;
});

is scalar(@stashes), 1;

@stashes = ();
eval { Git::Raw::Stash -> foreach($repo, sub { die "Bad" }) };
ok ($@);

done_testing;
