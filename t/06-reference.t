#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $ref = Git::Raw::Reference -> lookup('refs/heads/master', $repo);

is $ref -> type, 'direct';
is $ref -> name, 'refs/heads/master';
ok $ref -> is_branch;
ok !$ref -> is_remote;

my $head = $ref -> target($repo);

isa_ok $head, 'Git::Raw::Commit';

is $head -> message, "second commit\n";

done_testing;
