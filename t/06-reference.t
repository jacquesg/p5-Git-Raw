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
ok !$ref -> is_note;
ok !$ref -> is_tag;

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
is $ref -> shorthand, 'test-ref';
ok !$ref -> is_branch;
ok !$ref -> is_remote;
ok !$ref -> is_note;
ok !$ref -> is_tag;

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
ok !$ref -> is_note;
ok !$ref -> is_tag;

my $tree = $head -> tree();
$ref = Git::Raw::Reference -> create('refs/test-ref', $repo, $tree, 1);

is $ref -> type, 'direct';
is $ref -> target -> id, $tree -> id;
is $ref -> name, 'refs/test-ref';
ok !$ref -> is_branch;
ok !$ref -> is_remote;
ok !$ref -> is_note;
ok !$ref -> is_tag;

$ref -> delete;

my @refs = $repo -> refs();

is scalar(grep { !$_ -> isa('Git::Raw::Reference') } @refs), 0, 'Everything returned by $repo->refs() should be a Git::Raw::Reference';

my @ref_names = sort map { $_ -> name() } @refs;

is_deeply \@ref_names, [ 'refs/commit-test-ref', 'refs/heads/master' ];

done_testing;
