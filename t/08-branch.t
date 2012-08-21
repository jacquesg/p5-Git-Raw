#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $config = $repo -> config;
my $name   = $config -> str('user.name');
my $email  = $config -> str('user.email');

my $time = time();
my $off  = 120;
my $me   = Git::Raw::Signature -> new($name, $email, $time, $off);

my $commit = $repo -> head;

isa_ok($commit, 'Git::Raw::Commit');

my $branch_name = 'some_branch';

my $branch = $repo -> branch($branch_name, $commit);

is($branch -> type, 'direct');
is($branch -> name, 'refs/heads/some_branch');

my $head = $branch -> target($repo);

isa_ok($head, 'Git::Raw::Commit');

is($head -> message, "second commit\n");

done_testing;
