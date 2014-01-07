#!perl

use Test::More;

use Git::Raw;
use File::Slurp;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);
my $file = 'test3/under/the/tree/test3';
my $file2 = 'test2';

my $fst = $repo -> head -> target -> parents -> [0];
is $fst -> message, "second commit\n";

$repo -> checkout($fst, {
	'checkout_strategy' => { 'safe' => 1, 'remove_untracked' => 1 }
});

is_deeply $repo -> status($file), ['index_deleted'];

$repo -> checkout($repo -> head -> target, {
	'checkout_strategy' => { 'safe_create' => 1, 'force' => 1 }
});

is $repo -> head -> target -> message, "third commit\n";

is_deeply $repo -> status($file), [];

write_file($repo-> workdir . $file, 'content modified in work tree');
write_file($repo-> workdir . $file2, 'content modified in work tree');

is_deeply $repo -> status($file), ['worktree_modified'];
is_deeply $repo -> status($file2), ['worktree_modified'];

$repo -> checkout($repo -> head -> target, {
	'checkout_strategy' => { 'safe_create' => 1, 'force' => 1 },
	'paths' => [ $file2 ]
});

is_deeply $repo -> status($file), ['worktree_modified'];
is_deeply $repo -> status($file2), [];

done_testing;
