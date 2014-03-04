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

is $diff -> delta_count, 2;
my @patches = $diff -> patches;
is scalar(@patches), 2;

foreach my $patch (@patches) {
	my @hunks = $patch -> hunks;
	is $patch -> hunk_count, 1;
	is scalar(@hunks), 1;

	my $hunk = $hunks[0];
	isa_ok $hunk, 'Git::Raw::Diff::Hunk';
	is $hunk -> new_start, 1;
	is $hunk -> new_lines, 1;
	is $hunk -> old_start, 0;
	is $hunk -> old_lines, 0;
	is $hunk -> header, '@@ -0,0 +1 @@';
}

$expected = <<'EOS';
diff --git a/diff b/diff
new file mode 100644
index 0000000..6afc8a6
--- /dev/null
+++ b/diff
@@ -0,0 +1 @@
+diff me, biatch
EOS

is $patches[0] -> buffer, $expected;
is_deeply $patches[0] -> line_stats, {
	'context' => 0, 'additions' => 1, 'deletions' => 0
};

my $delta = $patches[0] -> delta;
isa_ok $delta, 'Git::Raw::Diff::Delta';
is $delta -> file_count, 1;
is $delta -> status, "added";
is_deeply $delta -> flags, [];

my $old_file = $delta -> old_file;
isa_ok $old_file, 'Git::Raw::Diff::File';
is $old_file -> id, '0' x 40;
is $old_file -> path, 'diff';
is_deeply $old_file -> flags, ['valid_id'];
is_deeply $old_file -> mode, 'new';

my $new_file = $delta -> new_file;
isa_ok $new_file, 'Git::Raw::Diff::File';
is substr($new_file -> id, 0, 7), '6afc8a6';
is $new_file -> path, 'diff';
is_deeply $new_file -> flags, ['valid_id'];
is_deeply $new_file -> mode, 'blob';

$expected = <<'EOS';
diff --git a/diff2 b/diff2
new file mode 100644
index 0000000..e6ada20
--- /dev/null
+++ b/diff2
@@ -0,0 +1 @@
+diff me too, biatch
EOS

is $patches[1] -> buffer, $expected;
is_deeply $patches[1] -> line_stats, {
	'context' => 0, 'additions' => 1, 'deletions' => 0
};

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

is $diff -> delta_count, 1;
@patches = $diff -> patches;
is scalar(@patches), 1;

$delta = $patches[0] -> delta;
is $delta -> old_file -> id, '0' x 40;
is substr($delta -> new_file -> id, 0, 7), 'c7eaef2';

done_testing;
