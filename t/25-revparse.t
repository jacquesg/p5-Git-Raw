#!perl

use Test::More;

use Git::Raw;
use File::Spec::Functions qw(catfile rel2abs);

my $path = rel2abs(catfile('t', 'test_repo'));
my $repo = Git::Raw::Repository -> open($path);

$repo -> revparse ('HEAD'); # void context
is $repo -> revparse ('HEAD'), 1;
my @revs = $repo -> revparse ('HEAD');
is scalar(@revs), 1;
my $head = shift @revs;
isa_ok $head, 'Git::Raw::Commit';

is $repo -> revparse ('HEAD~..HEAD'), 2;
@revs = $repo -> revparse ('HEAD~..HEAD');
is scalar(@revs), 2;
isa_ok $revs[0], 'Git::Raw::Commit';
isa_ok $revs[1], 'Git::Raw::Commit';
is $revs[1] -> id, $head -> id;

my $prev_head = shift @revs;

@revs = $repo -> revparse('master~..master');
is scalar(@revs), 2;
is $revs[0] -> id, $prev_head -> id;
is $revs[1] -> id, $head -> id;

my @mb = $repo -> revparse('master~...master');
isa_ok $mb[0], 'Git::Raw::Commit';
isa_ok $mb[1], 'Git::Raw::Commit';

is $revs[0] -> id, $mb[0] -> id;
is $revs[1] -> id, $mb[1] -> id;

@revs = $repo -> revparse('@{1}');
is scalar(@revs), 1;
is $revs[0] -> id, $prev_head -> id;

@revs = $repo -> revparse('master@{1}');
is scalar(@revs), 1;
is $revs[0] -> id, $prev_head -> id;

my $nonexistent = eval { $repo -> revparse('nonexistent') };
is $nonexistent, undef;

done_testing;
