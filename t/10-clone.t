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
my $url = 'git://github.com/libgit2/TestGitRepository.git';

$path = File::Spec -> rel2abs('t/test_repo_clone_bare');
my $bare = Git::Raw::Repository -> clone($url, $path, { bare => 1 });

ok $bare -> is_bare;
ok !$bare -> is_empty;
$bare = undef;

$path = File::Spec -> rel2abs('t/test_repo_clone');
my $repo = Git::Raw::Repository -> clone($url, $path, { });

ok !$repo -> is_bare;
ok !$repo -> is_empty;

is_deeply $repo -> status -> {'master.txt'}, undef;

my @remotes = $repo -> remotes;

is $remotes[0] -> name, 'origin';
is $remotes[0] -> url, $url;
is $remotes[1], undef;

my $ref = Git::Raw::Branch -> lookup($repo, 'master', 1);

is $ref -> upstream -> name, 'refs/remotes/origin/master';
is $ref -> upstream_name, 'refs/remotes/origin/master';
is $ref -> remote_name, 'origin';
is $ref -> type, 'direct';

my $head = $ref -> target;
isa_ok $head, 'Git::Raw::Commit';

is $head -> author -> name, 'A U Thor';

$head = undef;
$ref = undef;

$path = File::Spec->rel2abs('t/test_repo_remote_name');
$repo = Git::Raw::Repository -> clone($url, $path, {'remote_name' => 'github' });

@remotes = $repo -> remotes;

is $remotes[0] -> name, 'github';
is $remotes[0] -> url, $url;
is $remotes[1], undef;

@remotes = ();

$path = File::Spec->rel2abs('t/test_repo_disable_checkout');
$repo = Git::Raw::Repository -> clone($url, $path, {'disable_checkout' => 1 });

isnt -f File::Spec->catfile($repo -> workdir, 'Raw.xs'), 1;

my $state = undef;
my $total_objects = 0;
my $received_objects = 0;
my $local_objects = 0;
my $total_deltas = 0;
my $indexed_deltas = 0;
my $received_bytes = 0;

my $states = [];

$path = File::Spec -> rel2abs('t/test_repo_clone_callbacks');
$repo = Git::Raw::Repository -> clone($url, $path, {
	'callbacks' => {
		'sideband_progress' => sub {
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
ok scalar(@$states) > 0;

$repo = undef;

rmtree abs_path('t/test_repo_clone');
rmtree abs_path('t/test_repo_clone_bare');
rmtree abs_path('t/test_repo_clone_callbacks');
rmtree abs_path('t/test_repo_disable_checkout');
rmtree abs_path('t/test_repo_remote_name');

my $remote_path = File::Spec -> rel2abs('t/test_repo');
my $remote_url = "ssh://$ENV{USER}\@localhost$remote_path";
$path = File::Spec -> rel2abs('t/test_repo_ssh');

# Die'ing inside the callback
ok (!eval { $repo = Git::Raw::Repository -> clone($remote_url, $path, {
		'callbacks' => {
			'credentials' => sub { die "Shouldn't break!" }
		}
	});
});
rmtree abs_path('t/test_repo_ssh');

# Returning undef inside the callback
ok (!eval { $repo = Git::Raw::Repository -> clone($remote_url, $path, {
		'callbacks' => {
			'credentials' => sub { return undef; }
		}
	});
});
rmtree abs_path('t/test_repo_ssh');

# Invalid key files
ok (!eval { $repo = Git::Raw::Repository -> clone($remote_url, $path, {
		'callbacks' => {
			'credentials' => sub {
				my ($url, $user) = @_;
					return Git::Raw::Cred -> sshkey(
						$user, 'invalid', 'invalid');
			}
		}
	});
});
rmtree abs_path('t/test_repo_ssh');

$repo = Git::Raw::Repository -> clone($remote_url, $path, {
	'callbacks' => {
		'credentials' => sub {
			my ($url, $user) = @_;

			my $ssh_dir = File::Spec -> catfile($ENV{HOME}, '.ssh');
			ok -e $ssh_dir;

			my $public_key = File::Spec -> catfile($ssh_dir, 'id_rsa.pub');
			my $private_key = File::Spec -> catfile($ssh_dir, 'id_rsa');
			ok -f $public_key;
			ok -f $private_key;

			is $user, $ENV{USER};
			is $url, $remote_url;

			return Git::Raw::Cred -> sshkey(
				$user,
				$public_key,
				$private_key
			);
		}
	}
});

ok !$repo -> is_empty;
@remotes = $repo -> remotes;

is $remotes[0] -> name, 'origin';
is $remotes[0] -> url, $remote_url;

@remotes = ();
$repo = undef;

rmtree abs_path('t/test_repo_ssh');

done_testing;
