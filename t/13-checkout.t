#!perl

use Test::More;

use Git::Raw;
use File::Slurp;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $fst = $repo -> head -> target -> parents -> [0];
is $fst -> message, "second commit\n";

$repo -> checkout($fst, {});

is_deeply $repo -> status -> {'test3/under/the/tree/test3'}, undef;

$repo -> checkout($repo -> head, {});

$repo -> checkout($fst, {
	'checkout_strategy' => { 'safe' => 1, 'remove_untracked' => 1 }
});

is_deeply $repo -> status -> {'test3/under/the/tree/test3'}, ['index_deleted'];

$repo -> checkout($repo -> head, {});

my $file  = $repo -> workdir . 'test';
write_file($file, 'this is a checkout test');

$file  = $repo -> workdir . 'test2';
write_file($file, 'this is a checkout test');

$repo -> index -> add('test');
$repo -> index -> add('test2');
$repo -> index -> write;

my $tree = $repo -> lookup($repo -> index -> write_tree);

my $name   = $repo -> config -> str('user.name');
my $email  = $repo -> config -> str('user.email');
my $me   = Git::Raw::Signature -> now($name, $email);

my $commit = $repo -> commit(
	"checkout commit\n", $me, $me, [$repo -> head -> target], $tree
);

is read_file($repo -> workdir . 'test'),  'this is a checkout test';
is read_file($repo -> workdir . 'test2'), 'this is a checkout test';

$repo -> checkout($fst, {
	'checkout_strategy' => { 'safe' => 1, 'remove_untracked' => 1 },
	'paths' => [ 'test2' ]
});

is read_file($repo -> workdir . 'test'),  'this is a checkout test';
is read_file($repo -> workdir . 'test2'), 'this is a second test';

done_testing;
