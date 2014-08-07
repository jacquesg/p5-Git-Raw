#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $buffer = 'hello, world!';

my $blob = $repo -> blob($buffer);

is $blob -> content, $buffer;
is $blob -> size, length $buffer;
is $blob -> id, '30f51a3fba5274d53522d0f19748456974647b4f';

ok $blob -> is_blob;
ok !$blob -> is_tree;

my $non_existent = Git::Raw::Blob -> lookup($repo, '123456789987654321');
is $non_existent, undef;

my $blob2 = Git::Raw::Blob -> lookup($repo, $blob -> id);
ok ($blob2);
is $blob2 -> id, $blob -> id;

done_testing;
