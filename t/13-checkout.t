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

my $untracked_file = $repo -> workdir . 'untracked_file';
write_file($untracked_file, 'this is a checkout test');

my $files_expected = [ 'test2', 'untracked_file' ];
my $files_checked_out = [];
$repo -> checkout($fst, {
	'checkout_strategy' => { 'safe' => 1, 'remove_untracked' => 1 },
	'paths'     => $files_expected,
	'notify'    => [ 'all' ],
	'callbacks' => {
		'notify' => sub {
			my ($path, $flags) = @_;

			if ($path eq 'untracked_file') {
				is_deeply $flags, ['untracked'];
			} elsif ($path eq 'test2') {
				is_deeply $flags, ['updated'];
			}

			push @$files_checked_out, $path;

			return 0;
		},
		'progress' => sub {
			my ($path, $completed_steps, $total_steps) = @_;

			if (!defined $path) {
				is $completed_steps, 0;
				is $total_steps, scalar(@$files_expected);
			} else {
				ok $completed_steps <= $total_steps;
				is scalar(grep { $_ eq $path } @$files_expected), 1;
			}
		}
	}
});

is_deeply $files_checked_out, $files_expected;

is read_file($repo -> workdir . 'test'),  'this is a checkout test';
is read_file($repo -> workdir . 'test2'), 'this is a second test';

done_testing;
