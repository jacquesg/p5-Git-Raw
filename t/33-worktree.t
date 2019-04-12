#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);
use File::Spec::Functions qw(catfile rel2abs);

my $path = abs_path('t/test_repo');
my $worktree_path1 = rel2abs(catfile('t', 'test_repo_myworktree1'));
my $worktree_path2 = rel2abs(catfile('t', 'test_repo_myworktree2'));
my $repo = Git::Raw::Repository -> open($path);

my $worktree1 = Git::Raw::Worktree -> add($repo, 'myworktree1', $worktree_path1);
isa_ok $worktree1, 'Git::Raw::Worktree';
is $worktree1 -> name, 'myworktree1';
is $worktree1 -> path, $worktree_path1;

my $worktree2 = Git::Raw::Worktree -> add($repo, 'myworktree2', $worktree_path2);
isa_ok $worktree2, 'Git::Raw::Worktree';
is $worktree2 -> name, 'myworktree2';
is $worktree2 -> path, $worktree_path2;

my $worktree3 = Git::Raw::Worktree -> lookup($repo, 'myworktree1');
isa_ok $worktree3, 'Git::Raw::Worktree';

my $worktree4 = Git::Raw::Worktree -> lookup($repo, 'badworktree');
ok (!defined ($worktree4));

my $wtrepo = $worktree1 -> repository;
isa_ok $wtrepo, 'Git::Raw::Repository';
undef $wtrepo;

my $head = $repo -> head_for_worktree('myworktree1');
isa_ok $head, 'Git::Raw::Reference';

ok (!$worktree1 -> is_locked);

ok ($worktree1 -> lock("locking"));
my $r = $worktree1 -> is_locked;
is $r, 'locking';

ok (!eval { $worktree1 -> lock("locking again")});
$worktree1 -> unlock;
ok (!$worktree1 -> is_locked);

Git::Raw::Worktree -> list($repo);
my @list = Git::Raw::Worktree -> list($repo);
is scalar (@list), 2;
isnt $list[0], $list[1];
like $list[1], qr'myworktree\d+';
like $list[0], qr'myworktree\d+';

my $count = Git::Raw::Worktree -> list($repo);
is $count, 2;

my $worktree_repo = Git::Raw::Repository -> open($worktree_path2);
ok ($worktree_repo -> is_worktree);
is $worktree_repo -> commondir, $repo -> commondir;
isnt $worktree_repo -> path, $repo -> path;
isnt $worktree_repo -> workdir, $repo -> workdir;

ok ($worktree1 -> validate);

ok (!$worktree1 -> is_prunable ({}));
ok ($worktree1 -> is_prunable ({flags => {valid => 1}}));

ok ($worktree1 -> lock("locking"));
ok (!$worktree1 -> is_prunable ({flags => { valid => 1}}));
ok ($worktree1 -> is_prunable ({flags => { valid => 1, locked => 1}}));

$worktree1 -> prune ({flags => {valid => 1, locked => 1, working_tree => 1}});
$worktree2 -> prune ({flags => {valid => 1, locked => 1, working_tree => 1}});

ok (!$worktree1 -> validate);

done_testing;

