#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);
my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my @revs = $repo -> revparse ('HEAD');
is scalar(@revs), 1;
my $commit = shift @revs;
isa_ok $commit, 'Git::Raw::Commit';

my $annotated = $commit -> annotated;
isa_ok $annotated, 'Git::Raw::AnnotatedCommit';
is $commit -> id, $annotated -> id;
is $commit -> id , "$annotated";


my $head = $repo -> head;
isa_ok $head, 'Git::Raw::Reference';
$annotated = $head -> annotated_commit;
isa_ok $annotated, 'Git::Raw::AnnotatedCommit';
is $commit -> id, $annotated -> id;


my $annotated2 = Git::Raw::AnnotatedCommit -> lookup($repo, $commit -> id);
isa_ok $annotated2, 'Git::Raw::AnnotatedCommit';
is $annotated2 -> id, $annotated -> id;

done_testing;
