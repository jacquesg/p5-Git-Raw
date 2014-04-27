#!perl

use Test::More;

use Git::Raw;
use File::Copy;
use File::Slurp;
use Cwd qw(abs_path);
use File::Path 2.07 qw(make_path remove_tree);
use Time::Local;

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

done_testing;
