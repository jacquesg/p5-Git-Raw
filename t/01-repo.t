#!perl

use Test::More;

use Git::Raw;
use File::Spec;
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

is_deeply $repo -> status('ignore') -> {'ignore'}, ['ignored'];
is_deeply $repo -> status -> {'ignore'}, ['ignored'];

is $repo -> path_is_ignored('ignore'), 1;
is $repo -> path_is_ignored('test'), 0;

my $config = $repo -> config;

my $name  = 'Git::Raw author';
my $email = 'git-xs@example.com';

is $config -> bool('some.bool'), undef;
ok $config -> bool('some.bool', 1);
ok $config -> bool('some.bool');

is $config -> int('some.int'), undef;
is $config -> int('some.int', 42), 42;
is $config -> int('some.int'), 42;

is $config -> str('some.str'), undef;
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

is $repo -> state, "none";

my $commit_msg_file = File::Spec->catfile($repo -> path, 'MERGE_MSG');

ok (open HANDLE, ">$commit_msg_file");
ok (close HANDLE);

$repo -> state_cleanup;
isnt -f $commit_msg_file, 1;

done_testing;
