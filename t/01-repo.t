#!perl -T

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> init($path, 0);

is($repo -> path, "$path/.git/");
is($repo -> workdir, "$path/");
is($repo -> is_empty, 1);

my $config = $repo -> config;

my $name  = 'Git::Raw author';
my $email = 'git-xs@example.com';

is($config -> set_str('user.name', $name), $name);
is($config -> set_str('user.email', $email), $email);

is($config -> get_str('user.name'), $name);
is($config -> get_str('user.email'), $email);

done_testing;
