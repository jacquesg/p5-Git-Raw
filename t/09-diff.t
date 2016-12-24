#!perl

use Test::More;

use Git::Raw;
use File::Copy;
use File::Slurp::Tiny qw(write_file);
use Cwd qw(abs_path);
use Capture::Tiny 'capture_stdout';

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

$repo -> config -> bool('diff.mnemonicprefix', 0);

if ($^O eq 'MSWin32') {
	$repo -> config -> str('core.autocrlf', "true");
}

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
	'context_lines'   => 3,
	'interhunk_lines' => 0,
	'paths'  => [
		undef,
		'diff'
	],
});

ok (!eval { $diff -> print('invalid_format', sub {}) });

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

$expected = <<'EOS';
file => diff
file => diff2
EOS

$output = capture_stdout { $diff -> print("name_only", $printer) };
is $output, $expected;

$expected = <<'EOS';
file => :000000 100644 0000000... 6afc8a6... A	diff
file => :000000 100644 0000000... e6ada20... A	diff2
EOS

$output = capture_stdout { $diff -> print("raw", $printer) };
is $output, $expected;

$expected = <<'EOS';
file => diff --git a/diff b/diff
new file mode 100644
index 0000000..6afc8a6
--- /dev/null
+++ b/diff
file => diff --git a/diff2 b/diff2
new file mode 100644
index 0000000..e6ada20
--- /dev/null
+++ b/diff2
EOS

$output = capture_stdout { $diff -> print("patch_header", $printer) };
is $output, $expected;

is $diff -> delta_count, 2;
$diff -> deltas; # void context
my @deltas = $diff -> deltas;
is scalar(@deltas), 2;

foreach my $delta (@deltas) {
	isa_ok $delta, 'Git::Raw::Diff::Delta';
	is $delta -> file_count, 1;
}

my $delta1 = $diff -> deltas(0);
isa_ok $delta1, 'Git::Raw::Diff::Delta';
my $delta2 = $diff -> deltas(1);
isa_ok $delta2, 'Git::Raw::Diff::Delta';

ok (!eval { $diff -> delta(2) });

$diff -> patches; # void context
my $patch_count = $diff -> patches;
is $patch_count, 2;
my @patches = $diff -> patches;
is scalar(@patches), 2;

foreach my $patch (@patches) {
	my @hunks = $patch -> hunks;
	ok (eval { $patch -> hunks(0) });
	ok (!eval { $patch -> hunks(1) });
	ok (!eval { $patch -> hunks($diff) });
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
is_deeply $old_file -> mode, 'unreadable';

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
my $tree1 = ($repo -> head -> target -> parents())[0] -> tree;

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
diff --git aaa/test3/under/the/tree/test3 bbb/test3/under/the/tree/test3
new file mode 100644
index 0000000..c7eaef2
--- /dev/null
+++ bbb/test3/under/the/tree/test3
@@ -0,0 +1 @@
+this is a third test
\ No newline at end of file
EOS

$output = $diff -> buffer('patch');
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


$index -> add('diff');
$index -> add('diff2');
my $index_tree1 = $index -> write_tree;

move($file, $file.'.moved');
$index -> remove('diff');
$index -> add('diff.moved');
my $index_tree2 = $index -> write_tree;

my $tree_diff = $index_tree1 -> diff({
	'tree'   => $index_tree2,
	'flags'  => {
		'force_binary' => 1,
		'show_binary'  => 1
	}
});

is $tree_diff -> delta_count, 2;
@patches = $tree_diff -> patches;

$expected =<<'EOS';
diff --git a/diff b/diff
deleted file mode 100644
index 6afc8a62bdc52dcf57a125667c48f16d674cf061..0000000000000000000000000000000000000000
GIT binary patch
literal 0
Hc$@<O00001

literal 16
Xc$`bgOiNS9P1R9I%1kUt&fo$7F2V&(

EOS

is $patches[0] -> buffer, $expected;

$tree_diff = $index_tree1 -> diff({
	'tree'   => $index_tree2,
});

@patches = $tree_diff -> patches;

$expected = <<'EOS';
diff --git a/diff b/diff
deleted file mode 100644
index 6afc8a6..0000000
--- a/diff
+++ /dev/null
@@ -1 +0,0 @@
-diff me, biatch
EOS

is $patches[0] -> buffer, $expected;

$expected = <<'EOS';
diff --git a/diff.moved b/diff.moved
new file mode 100644
index 0000000..6afc8a6
--- /dev/null
+++ b/diff.moved
@@ -0,0 +1 @@
+diff me, biatch
EOS

is $patches[1] -> buffer, $expected;

my $stats = $tree_diff -> stats;
isa_ok $stats, 'Git::Raw::Diff::Stats';
is $stats -> insertions, 1;
is $stats -> deletions, 1;
is $stats -> files_changed, 2;

$expected = <<'EOS';
 diff       | 1 -
 diff.moved | 1 +
 2 files changed, 1 insertion(+), 1 deletion(-)
 delete mode 100644 diff
 create mode 100644 diff.moved
EOS

is $stats -> buffer({
	'flags' => {
		'full'    => 1,
		'summary' => 1,
	}
}), $expected;

$expected = <<'EOS';
 2 files changed, 1 insertion(+), 1 deletion(-)
 delete mode 100644 diff
 create mode 100644 diff.moved
EOS

is $stats -> buffer({
	'flags' => {
		'short'    => 1,
		'summary'  => 1,
	}
}), $expected;

$tree_diff -> find_similar;
is $tree_diff -> delta_count, 1;
@patches = $tree_diff -> patches;

$expected = <<'EOS';
diff --git a/diff b/diff.moved
similarity index 100%
rename from diff
rename to diff.moved
EOS

is $patches[0] -> buffer, $expected;
$delta = $patches[0] -> delta;
isa_ok $delta, 'Git::Raw::Diff::Delta';
is $delta -> status, 'renamed';
is $delta -> similarity, 100;
is $delta -> new_file -> size, 16;

$stats = $tree_diff -> stats;
isa_ok $stats, 'Git::Raw::Diff::Stats';
is $stats -> insertions, 0;
is $stats -> deletions, 0;
is $stats -> files_changed, 1;

$expected = <<'EOS';
 diff => diff.moved | 0
 1 file changed, 0 insertions(+), 0 deletions(-)
EOS

is $stats -> buffer({
	'flags' => {
		'full'    => 1,
		'summary' => 1,
	}
}), $expected;

$expected = <<'EOS';
 1 file changed, 0 insertions(+), 0 deletions(-)
EOS

is $stats -> buffer({
	'flags' => {
		'short'    => 1,
		'summary' => 1,
	}
}), $expected;

my $content = <<'EOS';
AAAAAAAAAA
AAAAAAAAAA
AAAAAAAAAA
AAAAAAAAAA
AAAAAAAAAA
EOS

write_file("$file.moved", $content);
$index -> add('diff.moved');
$index_tree1 = $index -> write_tree;

move($file.'.moved', $file);
$index -> remove('diff.moved');

$content = <<'EOS';
AAAAAAAAAA
AAAAAAAAAA
AAAAZZAAAA
AAAAAAAAAA
AAAAAAAAAA
EOS

write_file($file, $content);
$index -> add('diff');
$index_tree2 = $index -> write_tree;

$tree_diff = $index_tree1 -> diff({
	'tree'   => $index_tree2,
	'flags'  => {
		'all' => 1
	},
	'context_lines'   => 3,
	'interhunk_lines' => 0,
	'paths' => [
		undef,
		'diff',
		'diff.moved'
	]
});

is $tree_diff -> delta_count, 2;
ok (!eval { $tree_diff -> find_similar([]) });
$tree_diff -> find_similar({
	'flags' => {
		'renames'                   => 1,
		'ignore_whitespace'         => 1,
		'ignore_leading_whitespace' => 1,
		'break_rewrites'            => 1,
	},
	'rename_threshold'              => 50,
	'rename_from_rewrite_threshold' => 50,
	'copy_threshold'                => 50,
	'break_rewrite_threshold'       => 60,
	'rename_limit'                  => 200,
});

is $tree_diff -> delta_count, 1;
@patches = $tree_diff -> patches;

$expected = <<'EOS';
diff --git a/diff.moved b/diff
similarity index 80%
rename from diff.moved
rename to diff
index 5b96873..f97fd8f 100644
--- a/diff.moved
+++ b/diff
@@ -1,5 +1,5 @@
 AAAAAAAAAA
 AAAAAAAAAA
-AAAAAAAAAA
+AAAAZZAAAA
 AAAAAAAAAA
 AAAAAAAAAA
EOS

is $patches[0] -> buffer, $expected;

$content = <<'EOS';
 AAAAAAAAAA
AAAAAAAAAA
AAAAZZAAAA
AAAAAAAAAA
 AAAAAAAAAA
EOS

write_file($file, $content);
$index -> add('diff');
$index_tree2 = $index -> write_tree;

$tree_diff = $index_tree1 -> diff({
	'tree'   => $index_tree2,
	'flags'  => {
		'all' => 1
	}
});

is $tree_diff -> delta_count, 2;
$tree_diff -> find_similar;
is $tree_diff -> delta_count, 1;
@patches = $tree_diff -> patches;

$content = <<'EOS';
From 5e3ed60de0985b4c6d1a049718930704077525ba Mon Sep 17 00:00:00 2001
From: Jacques Germishuys <jacquesg@striata.com>
Date: Sat, 24 Dec 2016 10:01:28 +0200
Subject: [PATCH] Second

---
 a.txt | 1 +
 b.txt | 1 +
 2 files changed, 2 insertions(+)
 create mode 100644 b.txt

diff --git a/a.txt b/a.txt
index 7898192..7e8a165 100644
--- a/a.txt
+++ b/a.txt
@@ -1 +1,2 @@
 a
+a
diff --git a/b.txt b/b.txt
new file mode 100644
index 0000000..6178079
--- /dev/null
+++ b/b.txt
@@ -0,0 +1 @@
+b
-- 
2.11.0

EOS

$diff = Git::Raw::Diff -> new($content);
isa_ok $diff, 'Git::Raw::Diff';

is $diff -> delta_count, 2;
$delta1 = $diff -> deltas(0);
isa_ok $delta1, 'Git::Raw::Diff::Delta';
is $delta1 -> new_file -> path, 'a.txt';
is $delta1 -> status, 'modified';

$delta2 = $diff -> deltas(1);
isa_ok $delta2, 'Git::Raw::Diff::Delta';
is $delta2 -> new_file -> path, 'b.txt';
is $delta2 -> status, 'added';

done_testing;
