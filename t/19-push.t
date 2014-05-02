#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);
use File::Slurp;
use File::Basename qw(dirname);
use File::Path 2.07 qw(make_path remove_tree);

my $local_path = abs_path('t').'/local_bare_repo';
my $local_repo = Git::Raw::Repository -> init($local_path, 1);
is $local_repo -> is_bare, 1;

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $remote = Git::Raw::Remote -> create_anonymous($repo, $local_path, undef);
isa_ok $remote, 'Git::Raw::Remote';

my $total_packed = 0;
my $push = Git::Raw::Push -> new($remote);
$push -> add_refspec("refs/heads/master:");
$push -> callbacks({
	'pack_progress' => sub {
		my ($stage, $current, $total) = @_;

		is $stage, 0;
		is $total, 0;
		ok ($current > $total_packed);
		$total_packed++;
	}
});

$push -> finish;
is $push -> unpack_ok, 1;
ok ($total_packed > 0);

$push = undef;
$remote = undef;
$local_repo = undef;

remove_tree $local_path;
ok ! -e $local_path;

my $local_url;
if ($^O eq 'MSWin32') {
	$local_url = "file:///$local_path";
} else {
	$local_url = "file://$local_path";
}
$local_repo = Git::Raw::Repository -> init($local_path, 1);
$remote = Git::Raw::Remote -> create_anonymous($repo, $local_url, undef);

my $updated_ref;

$push = Git::Raw::Push -> new($remote);
$push -> add_refspec("refs/heads/master:");
$push -> callbacks({
	'pack_progress' => sub {
		my ($stage, $current, $total) = @_;

		is $stage, 0;
		is $total, 0;
		ok ($current > $total_packed);
		$total_packed++;
	},
	'status' => sub {
		my ($ref, $msg) = @_;

		ok (defined($ref));
		ok (!defined($msg));
		$updated_ref = $ref;
	}
});

$total_packed = 0;
$push -> finish;
is $push -> unpack_ok, 1;
ok ($total_packed > 0);
is $updated_ref, "refs/heads/master";

$push -> update_tips;

remove_tree $local_path;
ok ! -e $local_path;

unless ($ENV{NETWORK_TESTING} or $ENV{RELEASE_TESTING}) {
	diag('remote push tests require network');
	done_testing;
	exit;
}

my $remote_path = File::Spec -> rel2abs('t/test_repo');
my $remote_url = "ssh://$ENV{USER}\@localhost$remote_path";
$path = File::Spec -> rel2abs('t/test_repo_ssh');

my $credentials = sub {
	my ($url, $user) = @_;

	my $ssh_dir = File::Spec -> catfile($ENV{HOME}, '.ssh');
	ok -e $ssh_dir;

	my $public_key = File::Spec -> catfile($ssh_dir, 'id_rsa.pub');
	my $private_key = File::Spec -> catfile($ssh_dir, 'id_rsa');
	ok -f $public_key;
	ok -f $private_key;

	return Git::Raw::Cred -> sshkey($user, $public_key, $private_key);
};

$repo = Git::Raw::Repository -> clone($remote_url, $path, {
	'callbacks' => {
		'credentials' => $credentials
	}
});

ok !$repo -> is_empty;
@remotes = $repo -> remotes;

my $config = $repo -> config;
$config -> str('user.name', 'some user');
$config -> str('user.email', 'someuser@somewhere.com');

my $branch = Git::Raw::Branch -> create($repo, "ssh_branch", $repo -> head -> target);
isa_ok $branch, 'Git::Raw::Branch';

$repo -> checkout($repo -> head($branch), {
	'checkout_strategy' => {
		'safe_create' => 1
	}
});

my $file  = $repo -> workdir . 'file_on_ssh_branch';
write_file($file, 'this is a test');

my $index = $repo -> index;
$index -> add('file_on_ssh_branch');
$index -> write;

my $me = Git::Raw::Signature -> default($repo);
my $commit = $repo -> commit("commit on file_on_ssh_branch\n", $me, $me, [$branch -> target],
	$repo -> lookup($index -> write_tree));

is scalar(@remotes), 1;
$remote = shift @remotes;

my ($credentials_fired, $sideband_fired, $update_tips_fired) = (0, 0, 0);
$remote -> callbacks({
	'credentials' => sub {
		$credentials_fired = 1;
		return &{$credentials}(@_);
	},
	'sideband_progress' => sub {
		my ($msg) = @_;

		like $msg, qr/pre-receive hook/;
		$sideband_fired = 1;
	},
	'update_tips' => sub {
		my ($ref, $a, $b) = @_;

		is $ref, 'refs/remotes/origin/ssh_branch';
		is $a, '0' x 40;
		isnt $a, $b;
		$update_tips_fired = 1;
	}
});

$remote -> connect('push');

$push = Git::Raw::Push -> new($remote);
$push -> add_refspec("refs/heads/ssh_branch:");

my ($pack_progress_fired, $transfer_progress_fired, $status_fired) = (0, 0, 0);
$push -> callbacks({
	'pack_progress' => sub {
		my ($stage, $current, $total) = @_;

		$pack_progress_fired = 1;
	},
	'transfer_progress' => sub {
		my ($current, $total, $bytes) = @_;

		$transfer_progress_fired = 1;
	},
	'status' => sub {
		my ($ref, $msg) = @_;

		is $ref, 'refs/heads/ssh_branch';
		ok !defined($msg);
		$status_fired = 1;
	}
});

# setup a pre-receive hook that just print out a message
my $pre_receive_content = <<'EOS';
#!/usr/bin/env perl

$|++;

print STDERR "This is from the pre-receive hook!";
exit(0);
EOS

my $pre_receive_file = File::Spec->catfile ($remote_path, '.git', 'hooks', 'pre-receive');
make_path dirname($pre_receive_file);
ok -e dirname($pre_receive_file);

write_file($pre_receive_file, $pre_receive_content);

ok -e $pre_receive_file;
chmod 0755, $pre_receive_file;

$push -> finish;
is $push -> unpack_ok, 1;

is $sideband_fired, 1;
is $credentials_fired, 1;
is $pack_progress_fired, 1;
is $transfer_progress_fired, 1;
is $status_fired, 1;

is $update_tips_fired, 0;
$push -> update_tips;
is $update_tips_fired, 1;

@remotes = ();
$repo = undef;

remove_tree $path;
ok ! -e $path;

done_testing;
