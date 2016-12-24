#!perl

use Test::More;

use Git::Raw;
use File::Spec::Functions qw(catfile rel2abs);

my $path = rel2abs(catfile('t', 'test_repo'));
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

my $repo2 = $tag -> owner;
isa_ok $repo2, 'Git::Raw::Repository';
is $repo2 -> path, $repo -> path;

my $non_existent = Git::Raw::Tag -> lookup($repo, '123456789987654321');
is $non_existent, undef;

my $counter = 0;
eval { Git::Raw::Tag -> foreach($repo, sub { 1; }) };
ok (!$@);

Git::Raw::Tag -> foreach($repo, sub { $counter++; 0; });
is $counter, 1;

is length ($tag -> id), 40;
my $lookup_tag = Git::Raw::Tag -> lookup($repo, $tag -> id);
isa_ok $lookup_tag, 'Git::Raw::Tag';
is $lookup_tag -> id, $tag -> id;

is $tag -> tagger -> name, $name;
is $tag -> tagger -> email, $email;
is $tag -> tagger -> time, $time;
is $tag -> tagger -> offset, $off;

my $target = $tag -> target;

is $target -> summary, "third commit";

is $target -> author -> name, $name;
is $target -> author -> email, $email;

my @tags = $repo -> tags;

isa_ok $tags[0], 'Git::Raw::Tag';

is $tags[0] -> name, $tag_name;
is $tags[0] -> message, $tag_msg;
is $tags[1], undef;

ok (!eval { $repo -> tags('invalid') });

@tags = $repo -> tags('all');
is scalar(@tags), 1;

@tags = $repo -> tags('lightweight');
is scalar(@tags), 0;

@tags = $repo -> tags(undef);
is scalar(@tags), 1;

$tags[0] -> delete;

Git::Raw::Reference -> create("refs/tags/lightweight-tag", $repo, $commit);

@tags = $repo -> tags;

my $lw_tag = $tags[0];
isa_ok $lw_tag, 'Git::Raw::Reference';
is $lw_tag -> is_tag, 1;
is $lw_tag -> is_branch, 0;
$lw_tag = undef;

@tags = $repo -> tags('lightweight');
is scalar(@tags), 1;

@tags = $repo -> tags('annotated');
is scalar(@tags), 0;

Git::Raw::Reference -> lookup("refs/tags/lightweight-tag", $repo) -> delete();

is $repo -> tags, 0;

done_testing;
