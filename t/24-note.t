#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $ref = Git::Raw::Note -> default_ref($repo);
is $ref, undef;

my $note = Git::Raw::Note -> create($repo, $repo -> head -> target, 'Some content');
isa_ok $note, 'Git::Raw::Note';
is length($note -> id), 40;
is $note -> message, 'Some content';

$note = eval { Git::Raw::Note -> create($repo, $repo -> head -> target, 'Some content') };
is $note, undef;

$note = Git::Raw::Note -> create($repo, $repo -> head -> target, 'Some content2!', undef, 1);

$ref = Git::Raw::Note -> default_ref($repo);
isa_ok $ref, 'Git::Raw::Reference';
is $ref -> name, 'refs/notes/commits';
is $ref -> is_note, 1;

my $note2 = Git::Raw::Note -> read($repo, $repo -> head -> target);
isa_ok $note2, 'Git::Raw::Note';
is $note2 -> id, $note -> id;
is $note2 -> message, $note -> message;

$note = eval { Git::Raw::Note -> create($repo, $repo -> head -> target, 'Some content', 'invalidref') };
is $note, undef;

$note = Git::Raw::Note -> create($repo, $repo -> head -> target, 'Some content', 'refs/notes/commits2');
isa_ok $note, 'Git::Raw::Note';

$note2 = Git::Raw::Note -> read($repo, $repo -> head -> target, 'refs/notes/commits2');
isa_ok $note2, 'Git::Raw::Note';

Git::Raw::Note -> remove($repo, $repo -> head -> target, 'refs/notes/commits2');
my $note3 = Git::Raw::Note -> read($repo, $repo -> head -> target, 'refs/notes/commits2');
is $note3, undef;
Git::Raw::Note -> remove($repo, $repo -> head -> target, 'refs/notes/commits2');

$note2 = Git::Raw::Note -> read($repo, $repo -> head -> target);
isa_ok $note2, 'Git::Raw::Note';

Git::Raw::Note -> remove($repo, $repo -> head -> target);
$note3 = Git::Raw::Note -> read($repo, $repo -> head -> target);
is $note3, undef;
Git::Raw::Note -> remove($repo, $repo -> head -> target);

done_testing;
