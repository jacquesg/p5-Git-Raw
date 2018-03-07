#!perl

use Test::More;

use Git::Raw;
use File::Slurp::Tiny qw(write_file);
use File::Spec::Functions qw(catfile rel2abs);
use File::Path qw(make_path);

is 0, Git::Raw::Rebase::Operation -> PICK;
is 1, Git::Raw::Rebase::Operation -> REWORD;
is 2, Git::Raw::Rebase::Operation -> EDIT;
is 3, Git::Raw::Rebase::Operation -> SQUASH;
is 4, Git::Raw::Rebase::Operation -> FIXUP;
is 5, Git::Raw::Rebase::Operation -> EXEC;

my $path = rel2abs(catfile('t', 'rebase_repo'));
make_path($path);

my $repo = Git::Raw::Repository -> init($path, 0);

my $config = $repo -> config;
my $name   = $config -> str('user.name');
my $email  = $config -> str('user.email');
my $me = Git::Raw::Signature -> new($name, $email, time(), 0);


my $file  = $repo -> workdir . 'test';
my $index = $repo -> index;

my $ignore_file = $repo -> workdir . '.gitignore';
write_file($ignore_file, '');
$index -> add('.gitignore');
$index -> write;

my $initial_commit = Git::Raw::Commit -> create($repo, "Initial commit\n", $me, $me, [], $index -> write_tree);
isa_ok $initial_commit, 'Git::Raw::Commit';

write_file($file, 'this is a test1');
$index -> add('test');
$index -> write;

my $commit1 = Git::Raw::Commit -> create($repo, "commit1\n", $me, $me, [$repo -> head -> target], $index -> write_tree);
isa_ok $commit1, 'Git::Raw::Commit';

write_file($file, 'this is a test2');
$index -> add('test');
$index -> write;

my $commit2 = Git::Raw::Commit -> create($repo, "commit2\n", $me, $me, [$repo -> head -> target], $index -> write_tree);
isa_ok $commit2, 'Git::Raw::Commit';

write_file($file, 'this is a test3');
$index -> add('test');
$index -> write;

my $commit3 = Git::Raw::Commit -> create($repo, "commit3\n", $me, $me, [$repo -> head -> target], $index -> write_tree);
isa_ok $commit3, 'Git::Raw::Commit';

# null rebase
my $branch = $initial_commit -> annotated;
my $upstream = $initial_commit -> annotated;
my $onto = $initial_commit -> annotated;

my $rebase = Git::Raw::Rebase -> new($repo, $branch, $upstream, $onto);
isa_ok $rebase, 'Git::Raw::Rebase';

$rebase -> operations;

my $count = $rebase -> operations;
is $count, 0;
is $rebase -> operation_count, 0;

my @operations = $rebase -> operations;
is scalar (@operations), 0;

ok (!eval {$rebase -> current_operation});

is $repo -> state, "rebase_merge";
is $repo -> is_head_detached, 1;

$rebase -> abort;
isnt $repo -> state, "rebase_merge";

# disk rebase
my $destination_branch = $repo -> branch('destination_branch', $initial_commit);
isa_ok $destination_branch, 'Git::Raw::Branch';

$branch = $commit3 -> annotated;
$upstream = $initial_commit -> annotated; $onto = $destination_branch -> annotated_commit;

my $rebase = Git::Raw::Rebase -> new($repo, $branch, $upstream, $onto, {
	'quiet' => 1,
	'merge_opts' => {},
	'checkout_opts' => {},
});
isa_ok $rebase, 'Git::Raw::Rebase';

is $repo -> state, "rebase_merge";
is $repo -> is_head_detached, 1;
is $rebase -> operation_count, 3;

@operations = $rebase -> operations;
is scalar(@operations), 3;

my $op = $rebase -> current_operation;
ok (!defined($op));

is $repo -> head -> target -> id, $onto -> id;

$op = $rebase -> next;
isa_ok $op, 'Git::Raw::Rebase::Operation';
is $op -> type, Git::Raw::Rebase::Operation->PICK;
is $op -> id, $commit1 -> id;

$op = $rebase -> current_operation;
is $op -> type, Git::Raw::Rebase::Operation->PICK;
is $op -> id, $commit1 -> id;

$me = Git::Raw::Signature -> new($name, $email, time()+60, 0);

my $commit1_ = $rebase -> commit($me, $me);
isnt $commit1 -> id, $commit1_ -> id;

$op = $rebase -> next;
isa_ok $op, 'Git::Raw::Rebase::Operation';
is $op -> type, Git::Raw::Rebase::Operation->PICK;
is $op -> id, $commit2 -> id;
ok (!defined($op -> exec));

my $commit2_ = $rebase -> commit($me, $me);
isnt $commit2 -> id, $commit2_ -> id;
$op = $rebase -> next;

$rebase = Git::Raw::Rebase -> open($repo, {});

$op = $rebase -> current_operation;
isa_ok $op, 'Git::Raw::Rebase::Operation';
is $op -> type, Git::Raw::Rebase::Operation->PICK;
is $op -> id, $commit3 -> id;

my $commit3_ = $rebase -> commit($me, $me);
isnt $commit3 -> id, $commit3_ -> id;

$op = $rebase -> next;
ok (!defined($op));

$rebase -> finish($me);
isnt $repo -> state, "rebase_merge";

is $repo -> is_head_detached, 1;
isnt $repo -> head -> target -> id, $onto -> id;
is $repo -> head -> target -> message, $commit3 -> message;

# in memory rebase
$branch = $commit3 -> annotated;
$upstream = $initial_commit -> annotated; $onto = $destination_branch -> annotated_commit;

my $rebase = Git::Raw::Rebase -> new($repo, $branch, $upstream, $onto, {
	'quiet' => 1,
	'inmemory' => 1,
	'merge_opts' => {},
	'checkout_opts' => {},
});
isa_ok $rebase, 'Git::Raw::Rebase';

isnt $repo -> state, "rebase_merge";

is $rebase -> operation_count, 3;
$op = $rebase -> next;

my $inmemory_index = $rebase -> inmemory_index;
isa_ok $inmemory_index, 'Git::Raw::Index';

done_testing;

