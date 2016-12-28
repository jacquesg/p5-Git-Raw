#!perl

use Test::More;
use File::Slurp::Tiny qw(write_file);
use File::Spec::Functions qw(catfile rel2abs);
use File::Path qw(make_path);
use Git::Raw;

my $path = rel2abs(catfile('t', 'test_repo'));
my $repo = Git::Raw::Repository -> open($path);

my $mempack = Git::Raw::Mempack -> new;
isa_ok $mempack, 'Git::Raw::Odb::Backend';

my $odb = $repo -> odb;
$odb -> add_backend($mempack, 99);

my $file  = $repo -> workdir . 'test_mempack';
write_file($file, 'going into the mempack file');

my $index = $repo -> index;
$index -> add('test_mempack');
$index -> write;

my $time = 1482678859;
my $me = Git::Raw::Signature -> new('me', 'me@home', $time, 0);

my $commit = Git::Raw::Commit -> create($repo, "in memory commit1\n", $me, $me, [], $index -> write_tree, undef);
my $commit_id = $commit -> id;

my $commit1_content = $mempack -> dump($repo);
is length ($commit1_content), 330;

write_file($file, 'going into the mempack file, delta');
$index -> add('test_mempack');
$index -> write;

$commit = Git::Raw::Commit -> create($repo, "in memory commit2\n", $me, $me, [], $index -> write_tree, undef);
my $commit2_content = $mempack -> dump($repo);
is length ($commit2_content), 540;

$mempack -> reset;
my $packfile_content = $mempack -> dump($repo);
is length ($packfile_content), 32;

my $tp = Git::Raw::TransferProgress -> new;
isa_ok $tp, 'Git::Raw::TransferProgress';
is $tp -> total_objects, 0;
is $tp -> indexed_objects, 0;
is $tp -> received_objects, 0;
is $tp -> local_objects, 0;
is $tp -> total_deltas, 0;
is $tp -> indexed_deltas, 0;
is $tp -> received_bytes, 0;


my $hash = 'c0c0ff26d385a8bbf312d7511c06ccbde6254507';
my $odb_path = rel2abs(catfile('t', 'odb'));
my $pack_file = catfile($odb_path, "pack-$hash.pack");
my $pack_index = catfile($odb_path, "pack-$hash.idx");
ok(!-e $pack_file);
ok(!-e $pack_index);

my $indexer = Git::Raw::Indexer -> new($odb_path, $odb);
isa_ok $indexer, 'Git::Raw::Indexer';

$indexer -> append($commit1_content, $tp);
is $tp -> total_objects, 5;
is $tp -> indexed_objects, 5;

$indexer -> commit($tp);
is $indexer -> hash, $hash;

ok(-e $pack_file);
ok(-e $pack_index);

$repo = Git::Raw::Repository -> open($path);
$odb = Git::Raw::Odb -> open(catfile($repo -> path, 'objects'));
$repo -> odb($odb);
is $odb -> backend_count, 2;

$commit = Git::Raw::Commit -> lookup($repo, $commit_id);
ok(!defined($commit));

my $one_pack = Git::Raw::Odb::Backend::OnePack -> new($pack_file);
$odb -> add_alternate($one_pack, 1);
is $odb -> backend_count, 3;

$commit = Git::Raw::Commit -> lookup($repo, $commit_id);
ok(defined($commit));

done_testing;

