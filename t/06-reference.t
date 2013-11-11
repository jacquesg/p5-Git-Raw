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
is $head -> message, "third commit\n";

$ref = $repo -> branch('foobar06', $head);
$ref -> delete;

my $repo2 = $ref -> owner;
isa_ok $repo2, 'Git::Raw::Repository';
is $repo2 -> path, "$path/.git/";

$ref = Git::Raw::Reference -> create('refs/test-ref', $repo, $head);

isa_ok $ref, 'Git::Raw::Reference';

is $ref -> type, 'direct';
is $ref -> target -> id, $head -> id;
is $ref -> name, 'refs/test-ref';
ok !$ref -> is_branch;
ok !$ref -> is_remote;

eval {
	Git::Raw::Reference -> create('refs/test-ref', $repo, $head);
	fail q{Should've raised an error!};
} or do {
	like $@, qr/Failed to write reference/;
};

# shouldn't die with force argument
Git::Raw::Reference -> create('refs/test-ref', $repo, $head, 1);

my $empty_blob = $repo -> blob('');
$ref = Git::Raw::Reference -> create('refs/test-ref', $repo, $empty_blob, 1);

is $ref -> type, 'direct';
is $ref -> target -> id, $empty_blob -> id;
is $ref -> name, 'refs/test-ref';
ok !$ref -> is_branch;
ok !$ref -> is_remote;

my $tree = $head -> tree();
$ref = Git::Raw::Reference -> create('refs/test-ref', $repo, $tree, 1);

is $ref -> type, 'direct';
is $ref -> target -> id, $tree -> id;
is $ref -> name, 'refs/test-ref';
ok !$ref -> is_branch;
ok !$ref -> is_remote;

$ref -> delete;

done_testing;
