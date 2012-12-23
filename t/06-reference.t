#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $head = $repo -> head;
isa_ok $head, 'Git::Raw::Reference';
is $head -> type, 'direct';
is $head -> name, 'refs/heads/master';
ok $head -> is_branch;

my $ref = Git::Raw::Reference -> lookup('refs/heads/master', $repo);

is $ref -> type, 'direct';
is $ref -> name, 'refs/heads/master';
ok $ref -> is_branch;
ok !$ref -> is_remote;

$head = $ref -> target;
isa_ok $head, 'Git::Raw::Commit';
is $head -> message, "second commit\n";

$ref = $repo -> branch('foobar06', $head);
$ref -> delete;

my $repo2 = $ref -> owner;
isa_ok $repo2, 'Git::Raw::Repository';
is $repo2 -> path, "$path/.git/";

done_testing;
