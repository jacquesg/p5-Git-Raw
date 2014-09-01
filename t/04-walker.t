#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $walk = $repo -> walker;
ok (!eval { $walk -> sorting (['blah']) });
ok (!eval { $walk -> sorting ([[], undef]) });

$walk -> sorting (['time']);
$walk -> push($repo -> head -> target);
is $walk -> next -> message, "third commit\n";
is $walk -> next -> message, "second commit\n";
is $walk -> next -> message, "initial commit\n";

is $walk -> next, undef;

# next after reset returns undef
is $walk -> next, undef;

$walk -> push($repo -> head -> target);
$walk -> hide(($repo -> head -> target -> parents())[0]);
is $walk -> next -> message, "third commit\n";
is $walk -> next, undef;

$walk -> push_glob('heads/*');
is $walk -> next -> message, "third commit\n";
is $walk -> next -> message, "second commit\n";
is $walk -> next -> message, "initial commit\n";
is $walk -> next, undef;

$walk -> push_head;
is $walk -> next -> message, "third commit\n";
is $walk -> next -> message, "second commit\n";
is $walk -> next -> message, "initial commit\n";
is $walk -> next, undef;


$walk -> push_head;
$walk -> sorting (['reverse', 'topological']);
is $walk -> next -> message, "initial commit\n";
is $walk -> next -> message, "second commit\n";
is $walk -> next -> message, "third commit\n";
is $walk -> next, undef;
$walk -> sorting (['none']);

$walk -> push_ref('refs/heads/master');
my $end = $walk -> next;
is $end -> message, "third commit\n";
is $walk -> next -> message, "second commit\n";

my $start = $walk -> next;
is $start -> message, "initial commit\n";
is $walk -> next, undef;

$walk -> push_head;

my $commit = $walk -> next;
isnt $commit, undef;
is   $commit -> message, "third commit\n";
isnt $commit -> tree, undef;
isnt $commit -> parents, undef;

$walk -> reset;
$walk -> push_head;
$walk -> hide_head;
is $walk -> next, undef;

$walk -> reset;
$walk -> push_head;
$walk -> hide_ref('refs/heads/master');
is $walk -> next, undef;

$walk -> reset;
$walk -> push_head;
$walk -> hide_ref('refs/heads/master');
is $walk -> next, undef;

$walk -> reset;
$walk -> push_head;
$walk -> hide_glob('refs/heads/notmaster');
isnt $walk -> next, undef;

$walk -> reset;
ok (!eval { $walk -> push_range('zzz', $end) });
ok (!eval { $walk -> push_range($start, 'zzz') });

$walk -> reset;
$walk -> push_range($start, $end);
is $walk -> next -> message, "third commit\n";
is $walk -> next -> message, "second commit\n";
is $walk -> next, undef;

$walk -> reset;
$walk -> push_range($start -> id . ".." . $end -> id);
is $walk -> next -> message, "third commit\n";
is $walk -> next -> message, "second commit\n";
is $walk -> next, undef;

$walk -> reset;
$walk -> push_range(substr($start -> id, 0, 8), substr($end -> id, 0, 8));
is $walk -> next -> message, "third commit\n";
is $walk -> next -> message, "second commit\n";
is $walk -> next, undef;

ok (!eval { $walk -> push_range(); });
ok (!eval { $walk -> push_range($start -> id . "." . $end -> id) });
ok (!eval { $walk -> push_range($start -> id . "..." . $end -> id) });

done_testing;
