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
ok !$repo -> is_shallow;

is_deeply $repo -> status({}) -> {'master.txt'}, undef;

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

$path = File::Spec->rel2abs('t/test_repo_remote_name_die');
ok (!eval { $repo = Git::Raw::Repository -> clone($url, $path, {
	'callbacks' => {
		'remote_create' => sub {
			my ($repo, $name, $remote_url) = @_;
			die "Something goes bad!";
		}
	}
})});
rmtree $path if (-e $path);

$path = File::Spec->rel2abs('t/test_repo_remote_name_undef');
ok (!eval { $repo = Git::Raw::Repository -> clone($url, $path, {
	'callbacks' => {
		'remote_create' => sub {
			my ($repo, $name, $remote_url) = @_;
			undef;
		}
	}
})});
rmtree $path if (-e $path);

my $triggered_remote_create = 0;
$path = File::Spec->rel2abs('t/test_repo_remote_name');
$repo = Git::Raw::Repository -> clone($url, $path, {
	'callbacks' => {
		'remote_create' => sub {
			my ($repo, $name, $remote_url) = @_;
			$triggered_remote_create = 1;
			isa_ok $repo, 'Git::Raw::Repository';
			is $name, 'origin';
			is $remote_url, $url;
			return Git::Raw::Remote -> create($repo, 'github', $remote_url);
		}
	}
});

is $triggered_remote_create, 1;

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
				} elsif ($description =~ /Counting objects/) {
					$state = 'count';
				}
			}

			if ($state eq 'count') {
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
				} elsif ($description =~ /Total/) {
					push @$states, 'total';
					$state = 'total';
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


my %features = Git::Raw -> features;
if ($features{'https'} == 0) {
	diag("HTTPS support not available, skipping HTTPS clone tests");
	done_testing;
	exit;
}

$url = 'https://github.com/libgit2/TestGitRepository.git';
$path = File::Spec -> rel2abs('t/test_repo_clone');

my ($credentials_fired, $certificate_check_fired, $update_tips_fired) = (0, 0, 0);
$repo = Git::Raw::Repository -> clone($url, $path, {
	'callbacks' => {
		'certificate_check' => sub {
			my ($cert, $valid, $host) = @_;
			$certificate_check_fired = 1;

			isa_ok $cert, 'Git::Raw::Cert';
			isa_ok $cert, 'Git::Raw::Cert::X509';
			is $cert -> type, 'x509';

			my $data = $cert -> data;
			ok (length($data) > 0);

			is $valid, 1;
			is $host, 'github.com';

			1;
		},
		'update_tips' => sub {
			my ($ref, $a, $b) = @_;
			$update_tips_fired = 1;

			like $ref, qr/refs/;
			ok !defined($a);
			ok defined($b);
		}
	}
});

ok !$repo -> is_empty;

is $credentials_fired, 0;
is $certificate_check_fired, 1;
is $update_tips_fired, 1;

$repo = undef;

rmtree abs_path('t/test_repo_clone');


if ($^O eq 'MSWin32') {
	diag("Windows doesn't have a SSH server, skipping SSH clone tests");
	done_testing;
	exit;
}

if ($features{'ssh'} == 0) {
	diag("SSH support not available, skipping SSH clone tests");
	done_testing;
	exit;
}

my $remote_path = File::Spec -> rel2abs('t/test_repo');
my $remote_url = "ssh://$ENV{USER}\@localhost$remote_path";
$path = File::Spec -> rel2abs('t/test_repo_ssh');

# Not a CV for callback
ok (!eval { $repo = Git::Raw::Repository -> clone($remote_url, $path, {
		'callbacks' => {
			'credentials' => 'blah'
		}
	});
});
rmtree $path;
ok ! -e $path;

# Die'ing inside the callback
ok (!eval { $repo = Git::Raw::Repository -> clone($remote_url, $path, {
		'callbacks' => {
			'credentials' => sub { die "Shouldn't break!" }
		}
	});
});
rmtree $path;
ok ! -e $path;

# Returning undef inside the callback
ok (!eval { $repo = Git::Raw::Repository -> clone($remote_url, $path, {
		'callbacks' => {
			'credentials' => sub { return undef; }
		}
	});
});
rmtree $path;
ok ! -e $path;

# Invalid key files
ok (!eval { $repo = Git::Raw::Repository -> clone($remote_url, $path, {
		'callbacks' => {
			'credentials' => sub {
				my ($url, $user) = @_;
					return Git::Raw::Cred -> sshkey(
						$user, 'invalid', 'invalid', 'invalid');
			}
		}
	});
});
rmtree $path;
ok ! -e $path;

# Incorrect authentication type (username and password)
ok (!eval { $repo = Git::Raw::Repository -> clone($remote_url, $path, {
		'callbacks' => {
			'credentials' => sub {
				my ($url, $user) = @_;
					return Git::Raw::Cred -> userpass(
						$user, 'password');
			}
		}
	});
});
rmtree $path;
ok ! -e $path;

# Incorrect authentication type (SSH agent)
ok (!eval { $repo = Git::Raw::Repository -> clone($remote_url, $path, {
		'callbacks' => {
			'credentials' => sub {
				my ($url, $user) = @_;
					return Git::Raw::Cred -> sshagent($user);
			}
		}
	});
});
rmtree $path;
ok ! -e $path;

# Incorrect authentication type (SSH interactive)
ok (!eval { $repo = Git::Raw::Repository -> clone($remote_url, $path, {
		'callbacks' => {
			'credentials' => sub {
				my ($url, $user) = @_;
					return Git::Raw::Cred -> sshinteractive(
						'metheunknownuser', sub {
							return ('badpassword');
						});
			}
		}
	});
});
rmtree $path;
ok ! -e $path;

($credentials_fired, $certificate_check_fired, $update_tips_fired) = (0, 0, 0);
$repo = Git::Raw::Repository -> clone($remote_url, $path, {
	'checkout_branch' => 'master',
	'callbacks' => {
		'credentials' => sub {
			my ($url, $user) = @_;
			$credentials_fired = 1;

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
		},
		'certificate_check' => sub {
			my ($cert, $valid) = @_;
			$certificate_check_fired = 1;

			ok (defined($valid));

			isa_ok $cert, 'Git::Raw::Cert';
			isa_ok $cert, 'Git::Raw::Cert::HostKey';
			is $cert -> type, 'hostkey';

			$cert -> ssh_types;
			my $type_count = $cert -> ssh_types;
			is $type_count, 2;

			my @types = $cert -> ssh_types;
			is scalar(@types), 2;

			is $types[0], 'md5';
			is $types[1], 'sha1';

			my $md5 = $cert -> md5;
			is length($md5), 16;

			my $sha1 = $cert -> sha1;
			is length($sha1), 20;

			1;
		},
		'update_tips' => sub {
			my ($ref, $a, $b) = @_;
			$update_tips_fired = 1;

			like $ref, qr/refs/;
			ok !defined($a);
			ok defined($b);
		}
	}
});

ok !$repo -> is_empty;
is $credentials_fired, 1;
is $certificate_check_fired, 1;
is $update_tips_fired, 1;
@remotes = $repo -> remotes;

is $remotes[0] -> name, 'origin';
is $remotes[0] -> url, $remote_url;

@remotes = ();
$repo = undef;

rmtree $path;
ok ! -e $path;

done_testing;
