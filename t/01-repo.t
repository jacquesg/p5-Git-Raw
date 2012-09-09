#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> init($path, 0);

mkdir "$path/subdir" or die "Can't create subdir: $!";
my $disc = Git::Raw::Repository -> discover("$path/subdir");

is $repo -> path, "$path/.git/";
is $disc -> path, "$path/.git/";

is $repo -> workdir, "$path/";
is $disc -> workdir, "$path/";

is $repo -> is_empty, 1;
is $disc -> is_empty, 1;

my $config = $repo -> config;

my $name  = 'Git::Raw author';
my $email = 'git-xs@example.com';

ok $config -> bool('some.bool', 1);
ok $config -> bool('some.bool');

is $config -> int('some.int', 42), 42;
is $config -> int('some.int'), 42;

is $config -> str('user.name', $name), $name;
is $config -> str('user.email', $email), $email;

is $config -> str('user.name'), $name;
is $config -> str('user.email'), $email;

done_testing;
