#!perl

use Test::More;

use Git::Raw;
use File::Slurp;
use Cwd qw(abs_path);
use Capture::Tiny 'capture_stdout';

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my $file  = $repo -> workdir . 'diff';
write_file($file, "diff me, biatch\n");

my $index = $repo -> index;
my $tree  = $repo -> head -> target -> tree;

$index -> add('diff');

my $diff = $repo -> diff($tree);

my $printer = sub {
	my ($usage, $line) = @_;

	print ("$usage => $line");
};

my $expected = <<'EOS';
file => diff --git a/diff b/diff
new file mode 100644
index 0000000..6afc8a6
--- /dev/null
+++ b/diff
hunk => @@ -0,0 +1 @@
add => +diff me, biatch
EOS

my $output = capture_stdout { $diff -> patch($printer) };

is $output, $expected;

$expected = <<'EOS';
file => A	diff
EOS

$output = capture_stdout { $diff -> compact($printer) };

is $output, $expected;

my $tree2 = $repo -> head -> target -> tree;
my $tree1 = $repo -> head -> target -> parents -> [0] -> tree;

$diff = $tree1 -> diff($repo, $tree2);

$expected = <<'EOS';
file => diff --git a/test2 b/test2
new file mode 100644
index 0000000..7b79d2f
--- /dev/null
+++ b/test2
hunk => @@ -0,0 +1 @@
add => +this is a second testdel => 
\ No newline at end of file
EOS

$output = capture_stdout { $diff -> patch($printer) };

is $output, $expected;

$expected = <<'EOS';
file => A	test2
EOS

$output = capture_stdout { $diff -> compact($printer) };

is $output, $expected;

done_testing;
