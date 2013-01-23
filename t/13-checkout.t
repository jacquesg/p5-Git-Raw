#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $fst = $repo -> head -> target -> parents -> [0];
is $fst -> message, "initial commit\n";

$repo -> checkout($fst, {
	'checkout_strategy' => { 'safe'  => 1, 'remove_untracked' => 1 }
});

is_deeply $repo -> status('test2'), ['index_deleted'];

done_testing;
