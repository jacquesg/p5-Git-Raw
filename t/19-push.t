#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);
use File::Slurp::Tiny qw(write_file);
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
$remote -> callbacks({
	'pack_progress' => sub {
		my ($stage, $current, $total) = @_;

		is $stage, 0;
		is $total, 0;
		ok ($current > $total_packed);
		$total_packed++;
	}
});

is $remote -> upload(['refs/heads/master:refs/heads/master']), 1;
ok ($total_packed > 0);

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

$remote -> callbacks({
	'pack_progress' => sub {
		my ($stage, $current, $total) = @_;

		is $stage, 0;
		is $total, 0;
		ok ($current > $total_packed);
		$total_packed++;
	},
	'push_update_reference' => sub {
		my ($ref, $msg) = @_;

		ok (defined($ref));
		ok (!defined($msg));
		$updated_ref = $ref;
	}
});

$total_packed = 0;
is $remote -> upload(['refs/heads/master:refs/heads/master']), 1;
ok ($total_packed > 0);
is $updated_ref, "refs/heads/master";

remove_tree $local_path;
ok ! -e $local_path;

unless ($ENV{NETWORK_TESTING} or $ENV{RELEASE_TESTING}) {
	diag('remote push tests require network');
	done_testing;
	exit;
}

if ($^O eq 'MSWin32') {
	diag("Windows doesn't have a SSH server, skipping SSH push tests");
	done_testing;
	exit;
}

my %features = Git::Raw -> features;
if ($features{'ssh'} == 0) {
	diag("SSH support not available, skipping SSH push tests");
	done_testing;
	exit;
}

my $remote_path = File::Spec -> rel2abs('t/test_repo');
my $remote_url = "ssh://$ENV{USER}\@localhost$remote_path";
$path = File::Spec -> rel2abs('t/test_repo_ssh');

my $challenge = sub {
	my ($name, $instruction, @prompts) = @_;

	is scalar(@prompts), 1;
	my $prompt = shift @prompts;
	like $prompt->{text}, qr/Password/;
	is $prompt->{echo}, 0;
	return ('blah');
};

my $tried_interactive = 0;
my $credentials = sub {
	my ($url, $user, $types) = @_;

	is ref($types), 'ARRAY';
	is scalar(grep { $_ eq 'ssh_key' } @$types), 1;
	is scalar(grep { $_ eq 'ssh_custom' } @$types), 1;
	is scalar(grep { $_ eq 'ssh_interactive' } @$types), 1;

	if (!$tried_interactive) {
		$tried_interactive = 1;
		return Git::Raw::Cred -> sshinteractive($user, $challenge);
	}

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
	$index -> write_tree);

is scalar(@remotes), 1;
$remote = shift @remotes;

my ($credentials_fired, $sideband_fired, $update_tips_fired) = (0, 0, 0);
my ($pack_progress_fired, $transfer_progress_fired, $status_fired) = (0, 0, 0);

$remote -> callbacks({
	'credentials' => sub {
		$credentials_fired = 1;
		return &{$credentials}(@_);
	},
	'sideband_progress' => sub {
		my ($msg) = @_;

		diag("Remote message (sideband): $msg");
		is $msg, "This is from the pre-receive hook! (Disallowing it)";
		$sideband_fired = 1;
	},
	'pack_progress' => sub {
		my ($stage, $current, $total) = @_;

		$pack_progress_fired = 1;
	},
	'push_transfer_progress' => sub {
		my ($current, $total, $bytes) = @_;

		$transfer_progress_fired = 1;
	},
	'push_update_reference' => sub {
		my ($ref, $msg) = @_;

		is $ref, 'refs/heads/ssh_branch';
		ok defined($msg);
		like $msg, qr/pre-receive hook/;
		$status_fired = 1;
	},
	'update_tips' => sub {
		my ($ref, $a, $b) = @_;
		$update_tips_fired = 1;
	},
});

# setup a pre-receive hook that fails
my $pre_receive_content = <<'EOS';
#!/usr/bin/env perl

$|++;

print STDERR "This is from the pre-receive hook! (Disallowing it)";
exit(1);
EOS

my $pre_receive_file = File::Spec->catfile ($remote_path, '.git', 'hooks', 'pre-receive');
make_path dirname($pre_receive_file);
ok -e dirname($pre_receive_file);

write_file($pre_receive_file, $pre_receive_content);

ok -e $pre_receive_file;
chmod 0755, $pre_receive_file;

# pre-receive hook kick
$remote -> connect('push');
is $remote -> push(["refs/heads/ssh_branch:refs/heads/ssh_branch"]), 0;
diag("Pre-receive hook (successfully) declined the push");
#$remote -> disconnect;

is $sideband_fired, 1;
is $credentials_fired, 1;
is $pack_progress_fired, 1;
is $transfer_progress_fired, 1;
is $status_fired, 1;
is $update_tips_fired, 0;

# setup a pre-receive hook that succeeds
$pre_receive_content = <<'EOS';
#!/usr/bin/env perl

$|++;

print STDERR "This is from the pre-receive hook! (Allowing it)";
exit(0);
EOS

write_file($pre_receive_file, $pre_receive_content);

$remote -> callbacks({
	'credentials' => sub {
		$credentials_fired = 1;
		return &{$credentials}(@_);
	},
	'sideband_progress' => sub {
		my ($msg) = @_;

		diag("Remote message (sideband): $msg");
		is $msg, "This is from the pre-receive hook! (Allowing it)";
		$sideband_fired = 1;
	},
	'update_tips' => sub {
		my ($ref, $a, $b) = @_;

		is $ref, 'refs/remotes/origin/ssh_branch';
		ok !defined($a);
		ok defined($b);
		isnt $a, $b;
		$update_tips_fired = 1;
	},
	'push_update_reference' => sub {
		my ($ref, $msg) = @_;

		is $ref, 'refs/heads/ssh_branch';
		ok !defined($msg);
		$status_fired = 1;
	}
});

$sideband_fired = 0;
$update_tips_fired = 0;
$status_fired = 0;
is $remote -> push(["refs/heads/ssh_branch:refs/heads/ssh_branch"]), 1;
is $sideband_fired, 1;
is $status_fired, 1;
is $update_tips_fired, 1;

@remotes = ();
$repo = undef;

remove_tree $path;
ok ! -e $path;

done_testing;
