#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $master = Git::Raw::Branch -> lookup($repo, 'master', 1);
my $head = $master -> target;
isa_ok $head, 'Git::Raw::Commit';

my $branch_name = 'reflog_branch';

my $branch = $repo -> branch($branch_name, $head);
is $branch -> type, 'direct';
is $branch -> name, "refs/heads/$branch_name";

my $reflog = $branch -> reflog;
my @entries = $reflog -> entries;
is scalar(@entries), 1;

my $message = 'My entry';
$reflog -> append ($message);
$reflog -> write;
@entries = $reflog -> entries;
is scalar(@entries), 2;

is $entries[0] -> {'message'}, $message;
is $entries[0] -> {'new_id'}, $entries[0] -> {'old_id'};
is $entries[0] -> {'old_id'}, $entries[1] -> {'new_id'};
is $entries[0] -> {'committer'} -> name, $entries[1] -> {'committer'} -> name;
is $entries[0] -> {'committer'} -> email, $entries[1] -> {'committer'} -> email;
is $entries[0] -> {'committer'} -> time, $entries[1] -> {'committer'} -> time;
is $entries[0] -> {'committer'} -> offset, $entries[1] -> {'committer'} -> offset;

my $name  = 'Committer';
my $email = 'committer@example.com';

my $time = time();
my $off  = 120;
my $me   = Git::Raw::Signature -> new($name, $email, $time, $off);

$reflog -> append ($message, $me);
$reflog -> write;
@entries = $reflog -> entries;
is scalar(@entries), 3;
is $entries[0] -> {'committer'} -> name, $name;
is $entries[0] -> {'committer'} -> email, $email;
is $entries[0] -> {'committer'} -> time, $time;
is $entries[0] -> {'committer'} -> offset, $off;

$reflog -> drop (1);
$reflog -> write;
@entries = $reflog -> entries;
is scalar(@entries), 2;
is $entries[0] -> {'old_id'}, $entries[1] -> {'new_id'};

$reflog -> delete;
$reflog = $branch -> reflog;
@entries = $reflog -> entries;
is scalar(@entries), 0;

$reflog = Git::Raw::Reflog -> open($branch);
@entries = $reflog -> entries;
is scalar(@entries), 0;

$reflog -> append ($message, $me);
$reflog -> write;
@entries = $reflog -> entries;
is scalar(@entries), 1;

done_testing;
