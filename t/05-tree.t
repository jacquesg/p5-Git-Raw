#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $head_id = $repo -> head -> target -> id;

my $head = $repo -> lookup($head_id);
my @entries = $head -> tree -> entries;

ok $entries [0] -> object;
$head = $repo -> lookup(substr($head_id, 0, 7));

@entries = $head -> tree -> entries;
ok $entries [0] -> object;

$head = $repo -> head -> target;

$tree = $head -> tree;

ok $tree -> is_tree;
ok !$tree -> is_blob;

my $repo2 = $tree -> owner;
isa_ok $repo2, 'Git::Raw::Repository';
is $repo2 -> path, $repo -> path;

my $bad_tree = Git::Raw::Tree -> lookup($repo, '123456789987654321');
is $bad_tree, undef;

my $lookup_tree = Git::Raw::Tree -> lookup($repo, $tree -> id);
isa_ok $lookup_tree, 'Git::Raw::Tree';
$lookup_tree = Git::Raw::Tree -> lookup($repo, substr($tree -> id, 0, 7));
isa_ok $lookup_tree, 'Git::Raw::Tree';

$tree -> entries; # void context
my $entry_count = $tree -> entries;
is $entry_count, 3;
@entries = $tree -> entries;
is scalar(@entries), 3;

is $entries [0] -> name, 'test';
is $entries [1] -> name, 'test2';
is $entries [2] -> name, 'test3';

is length($entries [0] -> id), 40;
is length($entries [1] -> id), 40;
is length($entries [2] -> id), 40;

is $entries [0] -> file_mode, 0100644;
is $entries [2] -> file_mode, 0040000;

my $obj0 = $entries [0] -> object;

isa_ok $obj0, 'Git::Raw::Blob';
is $obj0 -> is_binary, 0;
is $obj0 -> is_blob, 1;
is $obj0 -> content, 'this is a test';
is $obj0 -> size, '14';

my $repo3 = $obj0 -> owner;
isa_ok $repo3, 'Git::Raw::Repository';
is $repo3 -> path, $repo -> path;
is $repo2 -> path, $repo2 -> path;

my $blob_obj0 = Git::Raw::Blob -> lookup($repo, $obj0 -> id);
isa_ok $blob_obj0, 'Git::Raw::Blob';
is $blob_obj0 -> is_blob, 1;
is $obj0 -> content, $blob_obj0 -> content;
is $obj0 -> size, $blob_obj0 -> size;

my $obj1 = $entries [1] -> object;

isa_ok $obj1, 'Git::Raw::Blob';
is $obj1 -> content, 'this is a second test';
is $obj1 -> size, '21';

my $obj2 = $entries [2] -> object;

isa_ok $obj2, 'Git::Raw::Tree';

is $entries [3], undef;

my $non_existent_entry = $tree -> entry_byname('unknownfile');
is $non_existent_entry, undef;

my $entry = $tree -> entry_byname('test3');
isa_ok $entry, 'Git::Raw::Tree::Entry';
isa_ok $entry -> object, 'Git::Raw::Tree';

$non_existent_entry = $tree -> entry_bypath('test3/under/the/tree/nonexistent');
is $non_existent_entry, undef;

$entry = $tree -> entry_bypath('test3/under/the/tree/test3');

isa_ok $entry, 'Git::Raw::Tree::Entry';

my $obj4 = $entry -> object;

isa_ok $obj4, 'Git::Raw::Blob';
is $obj4 -> content, 'this is a third test';
is $obj4 -> size, '20';

done_testing;
