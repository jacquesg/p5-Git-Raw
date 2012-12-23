#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $walk = $repo -> walker;

$walk -> push($repo -> head -> target);

my $snd = $walk -> next;
is $snd -> message, "second commit\n";

my $fst = $walk -> next;
is $fst -> message, "initial commit\n";

is $walk -> next, undef;

# next after reset returns undef
is $walk -> next, undef;

$walk -> push($repo -> head -> target);
$walk -> hide($repo -> head -> target -> parents -> [0]);
is $walk -> next -> message, "second commit\n";
is $walk -> next, undef;

$walk -> push_glob('heads/*');
is $walk -> next -> message, "second commit\n";
is $walk -> next -> message, "initial commit\n";
is $walk -> next, undef;

$walk -> push_head;
is $walk -> next -> message, "second commit\n";
is $walk -> next -> message, "initial commit\n";
is $walk -> next, undef;

$walk -> push_ref('refs/heads/master');
is $walk -> next -> message, "second commit\n";
is $walk -> next -> message, "initial commit\n";
is $walk -> next, undef;

done_testing;
