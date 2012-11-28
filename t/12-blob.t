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

done_testing;
