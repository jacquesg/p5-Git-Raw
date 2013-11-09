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

done_testing;
