#!perl

use Test::More;

use Git::Raw;
use File::Slurp;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $old_head = $repo -> head;
my $branch_name = 'filter_branch';
my $branch = $repo -> branch($branch_name, $old_head -> target);

# switch to a new branch
$repo -> checkout($repo -> head($branch), {
	'checkout_strategy' => {
		'safe_create' => 1
	}
});

# odb filter
my $odb_filter = Git::Raw::Filter -> create ("odb", "text");

my $file = $repo -> workdir . 'filterfile';
write_file($file, 'X:filter me:X');

my $initialize = 0;
my $shutdown = 0;
my $cleanup = 0;
my $check = 0;
my $apply = 0;

ok (!eval { $odb_filter -> register(100) });

$odb_filter -> callbacks({
	'initialize' => sub {
		$initialize = 1;
		return Git::Raw::Error -> OK;
	},
	'shutdown' => sub {
		$shutdown = 1;
	},
	'cleanup' => sub {
		$cleanup = 1;
	},
	'check' => sub {
		my ($source) = @_;
		isa_ok $source, 'Git::Raw::Filter::Source';
		is $source -> id, '';
		is $source -> path, 'filterfile';
		is $source -> mode, 'to_odb';
		is $source -> file_mode, 0;

		$check = 1;
		return Git::Raw::Error -> OK;
	},
	'apply' => sub {
		my ($source, $from, $to) = @_;

		isa_ok $source, 'Git::Raw::Filter::Source';
		isa_ok $to, 'SCALAR';

		ok length ($from) > 0;

		$$to = (split (/:/, $from))[1];
		$apply = 1;
		return Git::Raw::Error -> OK;
	},
});

$odb_filter -> register(100);


my $index = $repo -> index;
$index -> add('filterfile');
$index -> write;

is $initialize, 1;
is $check, 1;
is $apply, 1;
is $cleanup, 1;
is $shutdown, 0;

my $content = '';
my $diff = $repo -> diff({ 'tree' => $repo -> head -> target -> tree });
$diff -> print ("patch", sub {
	my ($ctx, $line) = @_;

	$content .= $line if ($line =~ /filter me/);
});

is $content, "filter me";

$odb_filter = undef;
is $shutdown, 1;

$odb_filter = Git::Raw::Filter -> create ("odb", "text");

$odb_filter -> callbacks({
	'apply' => sub {
		return Git::Raw::Error -> ERROR;
	}
});

$odb_filter -> register(100);

write_file($file, 'X:filter me some more:X');

ok !eval { $index -> add('filterfile'); };

$content = '';
$diff = $repo -> diff({ 'tree' => $repo -> head -> target -> tree });
$diff -> print ("patch", sub {
	my ($ctx, $line) = @_;

	$content .= $line if ($line =~ /filter me/);
});

# calling die() should be safe
is $content, "filter me";

$odb_filter -> callbacks({
	'apply' => sub {
		$apply = 1;
		die "Throwing an exception here!\n";
	},
	'shutdown' => sub {
		$shutdown = 1;
	},
});

ok !eval { $index -> add('filterfile'); };
is $@, "Throwing an exception here!\n";

$shutdown = 0;
$odb_filter -> unregister;
is $shutdown, 1;

$apply = 0;
$index -> add('filterfile');
$index -> write;
is $apply, 0;

my $me = Git::Raw::Signature -> default($repo);
my $commit1 = $repo -> commit(
	"Filter commit1\n", $me, $me, [$repo -> head -> target], $repo -> lookup($index -> write_tree)
);

write_file($file, 'X:filter me some more and more:X');
$index -> add('filterfile');
$index -> write;

my $commit2 = $repo -> commit(
	"Filter commit2\n", $me, $me, [$commit1], $repo -> lookup($index -> write_tree)
);

my $worktree_filter = Git::Raw::Filter -> create ("worktree", "text");

$worktree_filter -> callbacks({
	'check' => sub {
		my ($source) = @_;
		is $source -> mode, 'to_worktree';

		$check = 1;
		0;
	},
	'apply' => sub {
		my ($source, $from, $to) = @_;

		$$to = (split (/:/, $from))[1];
		$apply = 1;
		0;
	},
});

$worktree_filter -> register(100);

$apply = 0;
$check = 0;

$repo -> checkout($commit1 -> tree, {
	'checkout_strategy' => {
		'force' => 1
	}
});

is $check, 1;
is $apply, 1;

is read_file($file), 'filter me some more';

$worktree_filter -> unregister;

my $passthrough_filter = Git::Raw::Filter -> create ("passthrough", "text");

$passthrough_filter -> callbacks({
	'check' => sub {
		$check = 1;
		return Git::Raw::Error -> PASSTHROUGH;
	},
	'apply' => sub {
		$apply = 1;
		return Git::Raw::Error -> PASSTHROUGH;
	},
});

$passthrough_filter -> register(100);

$apply = 0;
$check = 0;

$repo -> checkout($commit1 -> tree, {
	'checkout_strategy' => {
		'force' => 1
	}
});

is $check, 1;
is $apply, 0;
is read_file($file), 'X:filter me some more:X';

$passthrough_filter -> unregister;

# switch back to the previous branch
$repo -> checkout($repo -> head($old_head), {
	'checkout_strategy' => {
		'force' => 1
	}
});

done_testing;
