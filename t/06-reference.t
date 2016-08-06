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

my $ref = Git::Raw::Reference -> lookup('HEAD', $repo);
is $ref -> type, 'symbolic';
isa_ok $ref -> target, 'Git::Raw::Reference';

$ref = Git::Raw::Reference -> lookup('refs/heads/master', $repo);
isa_ok $ref, 'Git::Raw::Reference';

my $non_existent_ref = Git::Raw::Reference -> lookup('refs/heads/non-existent', $repo);
is $non_existent_ref, undef;

is $ref -> type, 'direct';
is $ref -> name, 'refs/heads/master';
ok $ref -> is_branch;
ok !$ref -> is_remote;
ok !$ref -> is_note;
ok !$ref -> is_tag;

$head = $ref -> target;
isa_ok $head, 'Git::Raw::Commit';
is $head -> summary, "third commit";

ok(!eval { $ref -> peel('any') });

my $peeled_commit = $ref -> peel('commit');
isa_ok $peeled_commit, 'Git::Raw::Commit';
is $peeled_commit -> id, $head -> id;

my $peeled_tree = $ref -> peel('tree');
isa_ok $peeled_tree, 'Git::Raw::Tree';
is $peeled_tree -> id, $head -> tree -> id;

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

my $symbolic = 1;
my $symbolic_ref = Git::Raw::Reference -> create('refs/test-symbolic-ref', $repo, 'refs/heads/master', 0, $symbolic);

my $master_ref = Git::Raw::Reference->lookup('refs/heads/master', $repo);

is $symbolic_ref -> type, 'symbolic';
is $symbolic_ref -> name, 'refs/test-symbolic-ref';
is $symbolic_ref -> target -> name, $master_ref -> name;
ok !$symbolic_ref -> is_branch;
ok !$symbolic_ref -> is_remote;
ok !$symbolic_ref -> is_note;
ok !$symbolic_ref -> is_tag;

# should fail to overwrite existing ref is overwrite is falsy
eval {
	Git::Raw::Reference -> create('refs/test-symbolic-ref', $repo, 'refs/heads/master', 0, $symbolic);
	fail q{Should've raised an error!};
} or do {
	like $@, qr/Failed to write reference/;
};

# shouldn't die with force argument
$symbolic_ref = Git::Raw::Reference -> create('refs/test-symbolic-ref', $repo, 'refs/heads/master', 1, $symbolic);

# should still reject Git::Raw::Reference as object when creating direct ref
eval {
	Git::Raw::Reference -> create('refs/test-ref', $repo, $master_ref, not $symbolic);
	fail q{Should've raised an error!};
} or do {
	like $@, qr/Argument is not of type/;
};

# should reject Git::Raw::Blob as target for symbolic ref
eval {
	Git::Raw::Reference -> create('refs/test-symbolic-ref', $repo, $empty_blob, 1, $symbolic);
	fail q{Should've raised an error!};
} or do {
	like $@, qr/Argument is not of type Git::Raw::Reference/;
};

# should reject Git::Raw::Commit as target for symbolic ref
eval {
	Git::Raw::Reference -> create('refs/test-symbolic-ref', $repo, $master_ref -> target, 1, $symbolic);
	fail q{Should've raised an error!};
} or do {
	like $@, qr/Argument is not of type Git::Raw::Reference/;
};

# should reject Git::Raw::Tree as target for symbolic ref
eval {
	Git::Raw::Reference -> create('refs/test-symbolic-ref', $repo, $tree, 1, $symbolic);
	fail q{Should've raised an error!};
} or do {
	like $@, qr/Argument is not of type Git::Raw::Reference/;
};

# and we can also use an existing Git::Raw::Reference object as the target
$symbolic_ref -> delete;
$symbolic_ref = Git::Raw::Reference -> create('refs/test-symbolic-ref', $repo, $master_ref, 0, $symbolic);

is $symbolic_ref -> type, 'symbolic';
is $symbolic_ref -> name, 'refs/test-symbolic-ref';
is $symbolic_ref -> target -> name, $master_ref -> name;
ok !$symbolic_ref -> is_branch;
ok !$symbolic_ref -> is_remote;
ok !$symbolic_ref -> is_note;
ok !$symbolic_ref -> is_tag;

$symbolic_ref -> delete;

done_testing;
