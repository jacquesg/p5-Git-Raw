#!perl

use Test::More;

use Git::Raw;
use File::Slurp;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $config = $repo -> config;
my $name   = $config -> get_str('user.name');
my $email  = $config -> get_str('user.email');

my $time = time();
my $off  = 120;
my $me   = Git::Raw::Signature -> new($name, $email, $time, $off);

done_testing;
