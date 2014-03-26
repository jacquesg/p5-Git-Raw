#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $config = $repo -> config;
my $name   = $config -> str('user.name');
my $email  = $config -> str('user.email');

my $time = time();
my $off  = 120;
my $me   = Git::Raw::Signature -> new($name, $email, $time, $off);

my $commit = $repo -> head -> target;

isa_ok $commit, 'Git::Raw::Commit';

my $tag_name = 'v0.1';
my $tag_msg  = 'Initial version';

my $tag = $repo -> tag($tag_name, $tag_msg, $me, $commit);

is $tag -> name, $tag_name;
is $tag -> message, $tag_msg;

is $tag -> tagger -> name, $name;
is $tag -> tagger -> email, $email;
is $tag -> tagger -> time, $time;
is $tag -> tagger -> offset, $off;

my $target = $tag -> target;

is $target -> message, "third commit\n";

is $target -> author -> name, $name;
is $target -> author -> email, $email;

my @tags = $repo -> tags;

isa_ok $tags[0], 'Git::Raw::Tag';

is $tags[0] -> name, $tag_name;
is $tags[0] -> message, $tag_msg;
is $tags[1], undef;

$tags[0] -> delete;

Git::Raw::Reference -> create("refs/tags/lightweight-tag", $repo, $commit);

@tags = $repo -> tags;

is $tags[0], undef;

Git::Raw::Reference -> lookup("refs/tags/lightweight-tag", $repo) -> delete();

is $repo -> tags, 0;

done_testing;
