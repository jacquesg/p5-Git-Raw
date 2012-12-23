#!perl

use Test::More;

use Git::Raw;
use File::Slurp;
use Cwd qw(abs_path);

my $path = abs_path('t').'/test_repo';
my $repo = Git::Raw::Repository -> init($path, 0);

mkdir "$path/subdir" or die "Can't create subdir: $!";
my $disc = Git::Raw::Repository -> discover("$path/subdir");

is $repo -> path, "$path/.git/";
is $disc -> path, "$path/.git/";

is $repo -> workdir, "$path/";
is $disc -> workdir, "$path/";

is $repo -> is_empty, 1;
is $disc -> is_empty, 1;

my $head = eval { $repo -> head };
is $head, undef;

my $file  = $repo -> workdir . 'ignore';
write_file($file, 'this file should be ignored');

$repo -> ignore("ignore\n");
ok eq_array($repo -> status('ignore'), ['ignored']);

my $config = $repo -> config;

my $name  = 'Git::Raw author';
my $email = 'git-xs@example.com';

ok $config -> bool('some.bool', 1);
ok $config -> bool('some.bool');

is $config -> int('some.int', 42), 42;
is $config -> int('some.int'), 42;

is $config -> str('some.str', 'hello'), 'hello';
is $config -> str('some.str'), 'hello';

is $config -> str('user.name', $name), $name;
is $config -> str('user.email', $email), $email;

is $config -> str('user.name'), $name;
is $config -> str('user.email'), $email;

$config -> foreach(sub {
	my ($entry_name, $entry_value, $entry_level) = @_;

	ok $entry_value          if $entry_name eq 'some.bool';
	is $entry_value, 42      if $entry_name eq 'some.int';
	is $entry_value, 'hello' if $entry_name eq 'some.str';

	0
});

done_testing;
