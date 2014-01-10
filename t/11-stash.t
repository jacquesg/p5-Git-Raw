#!perl

use Test::More;

use Git::Raw;
use File::Slurp;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $file  = $repo -> workdir . 'test';
write_file($file, 'this is a test for stash');

is_deeply $repo -> status -> {'test'}, {'flags' => ['worktree_modified']};

my $config = $repo -> config;
my $name   = $config -> str('user.name');
my $email  = $config -> str('user.email');

my $me = Git::Raw::Signature -> now($name, $email);

$repo -> stash($me, 'some stash');

Git::Raw::Stash -> foreach($repo, sub {
	my ($i, $msg, $oid) = @_;

	is $i, 0;
	is $msg, 'On master: some stash';

	0;
});

Git::Raw::Stash -> drop($repo, 0);

Git::Raw::Stash -> foreach($repo, sub { die 'This should not be called' });

done_testing;
