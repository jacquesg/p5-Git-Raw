#!perl

use Test::More;
use File::Slurp::Tiny qw(write_file);
use File::Spec::Functions qw(catfile rel2abs);
use File::Path qw(make_path);
use Git::Raw;

my $path = rel2abs(catfile('t', 'test_repo'));
my $repo = Git::Raw::Repository -> open($path);

my $file  = $repo -> workdir . 'test';
write_file($file, 'this is a test');

my $index = $repo -> index;
$index -> add('test');
$index -> write;

my $time = 1482678859;
my $me = Git::Raw::Signature -> new('me', 'me@home', $time, 0);
my $commit = Git::Raw::Commit -> create($repo, "initial commit\n", $me, $me, [], $index -> write_tree, undef);


my $pb = Git::Raw::Packbuilder -> new($repo);
isa_ok $pb, 'Git::Raw::Packbuilder';
ok(!eval { $pb -> threads (-1) });

is $pb -> written, 0;
is $pb -> object_count, 0;


ok(!eval { $pb -> insert ('blah') });
ok(!eval { $pb -> insert ($repo) });

$pb -> insert($commit, 0);
is $pb -> object_count, 1;

$pb -> insert($commit);
is $pb -> written, 0;
is $pb -> object_count, 4;

my $odb_path = rel2abs(catfile('t', 'odb'));
make_path($odb_path);
ok(-d $odb_path);

my $transfer_progress_count = 0;
my $pack_progress_count = 0;
my $callbacks = {
	'transfer_progress' => sub { ++$transfer_progress_count; },
	'pack_progress' => sub { ++$pack_progress_count },
};
$pb -> callbacks($callbacks);

$pb -> write($odb_path);
is $pb -> written, 4;
is $pb -> object_count, 4;
is $transfer_progress_count, $pb -> written + 1;
is $pack_progress_count, 3;

is $pb -> hash, '4ec0baa806411548c1051dbd4620bd8447045d9e';

my $walker = Git::Raw::Walker -> create($repo);
$walker -> push($commit);

$pb = Git::Raw::Packbuilder -> new($repo);
$pb -> threads(0);
$pb -> insert($walker);
is $pb -> object_count, 4;

$pb -> write($odb_path);
is $pb -> hash, '4ec0baa806411548c1051dbd4620bd8447045d9e';

done_testing;

