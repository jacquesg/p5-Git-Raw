#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $walk = $repo -> walker;

$walk -> push($repo -> head);

my $snd = $walk -> next;
is $snd -> message, "second commit\n";

my $fst = $walk -> next;
is $fst -> message, "initial commit\n";

is $walk -> next, undef;

done_testing;
