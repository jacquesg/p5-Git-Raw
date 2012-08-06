#!perl

use Test::More;

use Git::Raw;
use Cwd qw(abs_path);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $config = $repo -> config;
my $name   = $config -> string('user.name');
my $email  = $config -> string('user.email');

my $time = time();
my $off  = 120;
my $me   = Git::Raw::Signature -> new($name, $email, $time, $off);

my $commit = $repo -> head;

isa_ok($commit, 'Git::Raw::Commit');

my $tag_name = 'v0.1';
my $tag_msg  = 'Initial version';

my $tag = $repo -> tag($tag_name, $tag_msg, $me, $commit);

is($tag -> name, $tag_name);
is($tag -> message, "$tag_msg\n");

is($tag -> tagger -> name, $name);
is($tag -> tagger -> email, $email);
is($tag -> tagger -> time, $time);
is($tag -> tagger -> offset, $off);

my $target = $tag -> target;

is($target -> message, "second commit\n");

is($target -> author -> name, $name);
is($target -> author -> email, $email);

done_testing;
