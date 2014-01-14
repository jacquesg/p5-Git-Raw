#!perl

use Test::More;

use Git::Raw;
use File::Slurp;
use Cwd qw(abs_path);
use Capture::Tiny 'capture_stdout';

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

$repo -> config -> bool('diff.mnemonicprefix', 0);

my $file  = $repo -> workdir . 'diff';
write_file($file, "diff me, biatch\n");

my $file2  = $repo -> workdir . 'diff2';
write_file($file2, "diff me too, biatch\n");

my $file3  = $repo -> workdir . 'diff3';
write_file($file3, "diff me also, biatch, i have some whitespace    \r\n");

my $index = $repo -> index;
my $tree  = $repo -> head -> target -> tree;

$index -> add('diff');
$index -> add('diff2');

my $printer = sub {
	my ($usage, $line) = @_;

	print ("$usage => $line");
};

my $diff = $repo -> diff({
	'tree'   => $tree,
	'prefix' => { 'a' => 'aaa', 'b' => 'bbb' },
	'paths'  => [ 'diff' ]
});

my $expected = <<'EOS';
file => diff --git aaa/diff bbb/diff
new file mode 100644
index 0000000..6afc8a6
--- /dev/null
+++ bbb/diff
hunk => @@ -0,0 +1 @@
add => diff me, biatch
EOS

my $output = capture_stdout { $diff -> print("patch", $printer) };
is $output, $expected;

$diff = $repo -> diff({
	'tree'   => $tree,
	'prefix' => { 'a' => 'aaa', 'b' => 'bbb' },
	'paths'  => [ 'diff' ],
	'flags'  => {
		'reverse' => 1
	}
});

$expected = <<'EOS';
file => diff --git bbb/diff aaa/diff
deleted file mode 100644
index 6afc8a6..0000000
--- bbb/diff
+++ /dev/null
hunk => @@ -1 +0,0 @@
del => diff me, biatch
EOS

$output = capture_stdout { $diff -> print("patch", $printer) };
is $output, $expected;

$diff = $repo -> diff({
	'tree'   => $tree,
	'paths'  => [ 'diff2' ]
});

$expected = <<'EOS';
file => diff --git a/diff2 b/diff2
new file mode 100644
index 0000000..e6ada20
--- /dev/null
+++ b/diff2
hunk => @@ -0,0 +1 @@
add => diff me too, biatch
EOS

$output = capture_stdout { $diff -> print("patch", $printer) };
is $output, $expected;

$diff = $repo -> diff({
	'tree'   => $tree,
	'paths'  => [ 'diff3' ],
	'flags'  => {
		'ignore_whitespace' => 1,
		'ignore_whitespace_eol' => 1
	}
});

$expected = '';

$output = capture_stdout { $diff -> print("patch", $printer) };
is $output, $expected;

$diff = $repo -> diff({
	'tree'   => $tree
});

$expected = <<'EOS';
file => A	diff
file => A	diff2
EOS

$output = capture_stdout { $diff -> print("name_status", $printer) };
is $output, $expected;

my $tree2 = $repo -> head -> target -> tree;
my $tree1 = $repo -> head -> target -> parents -> [0] -> tree;

$diff = $tree1 -> diff({
	'tree' => $tree2,
	'prefix' => { 'a' => 'aaa', 'b' => 'bbb' },
});

$expected = <<'EOS';
file => diff --git aaa/test3/under/the/tree/test3 bbb/test3/under/the/tree/test3
new file mode 100644
index 0000000..c7eaef2
--- /dev/null
+++ bbb/test3/under/the/tree/test3
hunk => @@ -0,0 +1 @@
add => this is a third testdel => 
\ No newline at end of file
EOS

$output = capture_stdout { $diff -> print("patch", $printer) };

is $output, $expected;

$expected = <<'EOS';
file => A	test3/under/the/tree/test3
EOS

$output = capture_stdout { $diff -> print("name_status", $printer) };

is $output, $expected;

done_testing;
