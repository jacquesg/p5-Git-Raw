#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $config = $repo -> config;
my $name   = $config -> str('user.name');
my $email  = $config -> str('user.email');

my $commit = $repo -> head -> target;

isa_ok $commit, 'Git::Raw::Commit';

my $branch_name = 'new_branch';

my $branch = $repo -> branch($branch_name, $commit);

is $branch -> type, 'direct';
is $branch -> name, "refs/heads/$branch_name";
is $branch -> shorthand, $branch_name;

ok !$branch -> is_head;
ok $branch -> is_branch;
ok !$branch -> is_remote;
is $branch -> upstream, undef;
is $branch -> upstream_name, undef;
is $branch -> remote_name, undef;

$branch_name = 'some_branch';

$branch -> move($branch_name, 0);
$branch = Git::Raw::Branch -> lookup($repo, $branch_name, 1);
is $branch -> name, "refs/heads/$branch_name";

my $head = $branch -> target;

isa_ok $head, 'Git::Raw::Commit';

is $head -> message, "third commit\n";

my $look = Git::Raw::Branch -> lookup($repo, $branch_name, 1);
ok !$look -> upstream;

is $look -> type, 'direct';
is $look -> name, 'refs/heads/some_branch';

my $reflog = $look -> reflog;
my @entries = $reflog -> entries;
is scalar(@entries), 2;

ok (!defined (Git::Raw::Branch -> lookup($repo, 'nonexistent_local', 1)));
ok (!defined (Git::Raw::Branch -> lookup($repo, 'nonexistent_remote', 0)));

# The time of the commit may be off by a second or two, as
# Git::Raw::Signature -> default() uses the current system time,
# and the commits referenced here may have been created
# a second or two ago.
my $signature = Git::Raw::Signature -> default($repo);

isa_ok $entries[0] -> committer, 'Git::Raw::Signature';
is $entries[0] -> committer -> name, $signature -> name;
is $entries[0] -> committer -> email, $signature -> email;
ok $entries[0] -> committer -> time <= $signature -> time;
ok $entries[0] -> committer -> time >= $signature -> time - 2;
is $entries[0] -> committer -> offset, $signature -> offset;
ok $entries[0] -> message =~ /^Branch: renamed/i;

isa_ok $entries[1] -> committer, 'Git::Raw::Signature';
is $entries[1] -> committer -> name, $signature -> name;
is $entries[1] -> committer -> email, $signature -> email;
ok $entries[1] -> committer -> time <= $signature -> time;
ok $entries[1] -> committer -> time >= $signature -> time - 2;
is $entries[1] -> committer -> offset, $signature -> offset;
ok $entries[1] -> message =~ /^Branch: created/i;

my $branches = [ $repo -> branches('local') ];
is scalar(@$branches), 2;

ok (!eval { $repo -> branches('invalid_type') });
$branches = [ sort { $a -> name cmp $b -> name } $repo -> branches ];

is $branches -> [0] -> type, 'direct';
is $branches -> [0] -> name, 'refs/heads/master';
is $branches -> [0] -> shorthand, 'master';

is $branches -> [1] -> type, 'direct';
is $branches -> [1] -> name, 'refs/heads/some_branch';
is $branches -> [1] -> shorthand, 'some_branch';

if ($ENV{NETWORK_TESTING} or $ENV{RELEASE_TESTING}) {
	is scalar(@$branches), 5;
	is $branches -> [3] -> type, 'direct';
	is $branches -> [3] -> name, 'refs/remotes/github/master';
	ok $branches -> [3] -> is_remote;

	$branches = [ $repo -> branches('all') ];
	is scalar(@$branches), 5;
	$branches = [ $repo -> branches('remote') ];
	is scalar(@$branches), 3;
}

done_testing;
