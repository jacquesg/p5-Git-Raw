#!perl

use strict;
use warnings;

use Test::More;
use Git::Raw;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $empty_blob = $repo -> blob('');
my $builder    = Git::Raw::Tree::Builder -> new($repo);

is $builder -> entry_count, 0;

my $entry = $builder -> insert('one.txt', $empty_blob, 0100644);
$builder -> insert('two.txt', $empty_blob, 0100644);
$builder -> insert('three.txt', $empty_blob, 0100644);

isa_ok $entry, 'Git::Raw::Tree::Entry';
is $entry -> name, 'one.txt';

is $builder -> entry_count, 3;

$entry = $builder -> get('one.txt');
is $entry -> name, 'one.txt';
is $entry -> object -> id(), $empty_blob -> id ();

$entry = $builder -> get('two.txt');
is $entry -> name, 'two.txt';
is $entry -> object -> id(), $empty_blob -> id ();

$entry = $builder -> get('three.txt');
is $entry -> name, 'three.txt';
is $entry -> object -> id(), $empty_blob -> id ();

$entry = $builder -> get('four.txt');
ok !defined($entry);

my $tree = $builder -> write();

isa_ok $tree, 'Git::Raw::Tree';
is $tree -> id(), '228c738569c82d9906ea1801f698a7c2a70e56b1';
ok ('228c738569c82d9906ea1801f698a7c2a70e56b1' eq $tree);
ok ($tree eq $tree);
ok ($tree eq $tree -> id);
ok ($tree -> id eq $tree);
ok ($tree ne undef);
ok ($tree ne $builder);

my @entries = $tree -> entries();

is_deeply [ sort map { $_ -> name() } @entries ],
	[ qw/one.txt three.txt two.txt/ ];

is_deeply [ map { $_ -> object -> id() } @entries ],
	[ map { $empty_blob -> id() } (1..3) ];

$builder -> clear();

is $builder -> entry_count, 0;

$builder = Git::Raw::Tree::Builder -> new($repo, $tree);

is $builder -> entry_count, 3;

$builder -> remove('two.txt');

is $builder -> entry_count, 2;

$tree    = $builder -> write();
@entries = $tree -> entries();

is_deeply [ sort map { $_ -> name() } @entries ],
	[ qw/one.txt three.txt/ ];

is_deeply [ map { $_ -> object -> id() } @entries ],
	[ map { $empty_blob -> id() } (1..2) ];

eval {
	$builder -> insert('four.txt', $empty_blob, 0100754);
	fail q{Should've raised an error!};
} or do {
	like $@, qr/Failed to insert entry/;
};

eval {
	$builder -> insert('four/five.txt', $empty_blob, 0100755);
	fail q{Should've raised an error!};
} or do {
	like $@, qr/Failed to insert entry/;
};

eval {
	$builder -> remove('two.txt');
	fail q{Should've raised an error!};
} or do {
	like $@, qr/Failed to remove entry/;
};

my $subtree = $tree;

$builder -> insert('subdir', $subtree, 0040000);
is $builder -> entry_count, 3;

$tree    = $builder -> write();
@entries = $tree -> entries();

@entries = sort { $a -> name() cmp $b -> name() } @entries;

is_deeply [ map { $_ -> name() } @entries ],
	[ qw/one.txt subdir three.txt/ ];

is_deeply [ map { $_ -> object -> id() } @entries ],
	[ $empty_blob -> id(), $subtree -> id(), $empty_blob -> id() ];

done_testing;
