#!perl

use Test::More;
use File::Spec::Functions qw(catfile rel2abs);
use Git::Raw;

my $path = rel2abs(catfile('t', 'test_repo'));
my $repo = Git::Raw::Repository -> open($path);

# in memory
my $index = Git::Raw::Index -> new;
isa_ok $index, 'Git::Raw::Index';

# no repository associated yet
ok(!eval {$index -> write_tree});

my $r = $index -> owner;
is $r, undef;

$r = $repo -> index(undef);
ok(!defined($r));

$repo -> index($index);

$r = $index -> owner;
isa_ok $r, 'Git::Raw::Repository';
is $index -> path, undef;

$index -> clear;
is $index -> entry_count, 0;

ok(!eval {$index -> add_frombuffer('blah', undef)});
is $index -> entry_count, 0;

$index -> add_frombuffer ('d.txt', 'content4');
is $index -> entry_count, 1;
$index -> add_frombuffer ('a/b.txt', 'content2');
is $index -> entry_count, 2;
$index -> add_frombuffer ('a.txt', 'content1');
is $index -> entry_count, 3;

my $content3 = 'content3';
my $blob_id = 'a2b32293aab475bf50798c7642f0fe0593c167f6';
my $entry = $index -> add_frombuffer ('a/b/c.txt', \$content3);
isa_ok $entry, 'Git::Raw::Index::Entry';
is $entry -> id, $blob_id;
is $entry -> path, 'a/b/c.txt';
is $entry -> size, length($content3);
is $entry -> stage, 0;
is $entry -> blob, $blob_id;
is $entry -> blob -> content, $content3;

$index -> add($entry);

$index -> write_tree;

my $tree = $index -> write_tree($repo);

my @entries = $tree -> entries;
is scalar(@entries), 3;

is $entries[0] -> name, 'a.txt';
is $entries[1] -> name, 'a';
is $entries[2] -> name, 'd.txt';

isa_ok $entries[0] -> object, 'Git::Raw::Blob';
isa_ok $entries[1] -> object, 'Git::Raw::Tree';
isa_ok $entries[2] -> object, 'Git::Raw::Blob';
is $entries[0] -> object -> content, 'content1';
is $entries[2] -> object -> content, 'content4';

my @entries2 = $entries[1] -> object -> entries;
is scalar(@entries2), 2;

is $entries2[0] -> name, 'b.txt';
is $entries2[1] -> name, 'b';
is $entries2[0] -> object -> content, 'content2';

my @entries3 = $entries2[1] -> object -> entries;
is scalar(@entries3), 1;

is $entries3[0] -> name, 'c.txt';
is $entries3[0] -> object -> content, 'content3';

done_testing;
