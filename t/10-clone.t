#!perl

BEGIN {
  unless ($ENV{NETWORK_TESTING} or $ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'remote clone tests require network');
  }
}

use Test::More;

use File::Spec;
use Git::Raw;
use Cwd qw(abs_path);
use File::Path qw(rmtree);

my $path;
my $url = 'git://github.com/ghedo/p5-Git-Raw.git';

$path = abs_path('t/test_repo_clone_bare');
my $bare = Git::Raw::Repository -> clone($url, $path, { bare => 1 });

ok $bare -> is_bare;
ok !$bare -> is_empty;

$path = abs_path('t/test_repo_clone');
my $repo = Git::Raw::Repository -> clone($url, $path, { });

ok !$repo -> is_bare;
ok !$repo -> is_empty;

is_deeply $repo -> status -> {'Changes'}, undef;

my @remotes = $repo -> remotes;

is $remotes[0] -> name, 'origin';
is $remotes[0] -> url, $url;
is $remotes[1], undef;

my $ref = Git::Raw::Branch -> lookup($repo, 'master', 1);

is $ref -> upstream -> name, 'refs/remotes/origin/master';
is $ref -> type, 'direct';

my $head = $ref -> target;
isa_ok $head, 'Git::Raw::Commit';

is $head -> author -> name, 'Alessandro Ghedini';

$path = abs_path('t/test_repo_remote_name');
$repo = Git::Raw::Repository -> clone($url, $path, {'remote_name' => 'github' });

@remotes = $repo -> remotes;

is $remotes[0] -> name, 'github';
is $remotes[0] -> url, $url;
is $remotes[1], undef;

$path = abs_path('t/test_repo_disable_checkout');
$repo = Git::Raw::Repository -> clone($url, $path, {'disable_checkout' => 1 });

isnt -f File::Spec->catfile($repo -> workdir, 'Raw.xs'), 1;

my $state = undef;
my $total_objects = 0;
my $received_objects = 0;
my $local_objects = 0;
my $total_deltas = 0;
my $indexed_deltas = 0;
my $received_bytes = 0;

my $expected_states = ['pack', 'count', 'compress', 'total'];
my $states = [];

$path = abs_path('t/test_repo_clone_callbacks');
$repo = Git::Raw::Repository -> clone($url, $path, {
	'callbacks' => {
		'progress' => sub {
			my $description = shift;

			if (!defined ($state)) {
				if ($description =~ /pack/) {
					if ($description =~ /done/) {
						push @$states, 'pack';
						$state = 'count';
					}
				}
			} elsif ($state eq 'count') {
				if ($description =~ /Counting objects/) {
					if ($description =~ /done/) {
						push @$states, 'count';
						$state = 'compress';
					}
				}
			} elsif ($state eq 'compress') {
				if ($description =~ /Compressing/) {
					if ($description =~ /done/) {
						push @$states, 'compress';
						$state = 'total';
					}
				}
			} elsif ($state eq 'total') {
				if ($description =~ /Total/) {
					push @$states, 'total';
				}
			}
		},
		'transfer_progress' => sub {
			my ($to, $ro, $lo, $td, $id, $rb) = @_;

			if ($total_objects == 0) {
				$total_objects = $to;
			} else {
				if ($received_objects < $total_objects) {
					ok $ro >= $received_objects;
					$received_objects = $ro;
				} else {
					if ($total_deltas == 0) {
						$total_deltas = $td;
					} else {
						is $td, $total_deltas;
						ok $id >= $indexed_deltas;
						$indexed_deltas = $id;
					}
				}
			}

			ok $rb >= $received_bytes;
			$received_bytes = $rb;
		}
	}
});

ok ($received_bytes > 0);
is $received_objects, $total_objects;
is_deeply $states, $expected_states;

rmtree abs_path('t/test_repo_clone');
rmtree abs_path('t/test_repo_clone_bare');
rmtree abs_path('t/test_repo_clone_callbacks');
rmtree abs_path('t/test_repo_disable_checkout');
rmtree abs_path('t/test_repo_remote_name');

done_testing;
