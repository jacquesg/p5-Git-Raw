#!perl

use Test::More;

use Git::Raw;
use File::Spec::Unix;
use File::Spec::Functions qw(catfile rel2abs);
use File::Slurp::Tiny qw(write_file);
use File::Path qw(make_path);

my $native_path = rel2abs(catfile('t', 'test_repo'));
my $path = File::Spec::Unix -> rel2abs(File::Spec::Unix -> catfile('t', 'test_repo'));
make_path($path);

my $repo = Git::Raw::Repository -> init($native_path, 0);
isa_ok $repo, 'Git::Raw::Repository';

mkdir catfile($native_path, 'subdir') or die "Can't create subdir: $!";
my $disc = Git::Raw::Repository -> discover(catfile($native_path, 'subdir'));

is $repo -> path, "$path/.git/";
is $disc -> path, "$path/.git/";

is $repo -> workdir, "$path/";
is $disc -> workdir, "$path/";

is $repo -> workdir($path), "$path/";
is $disc -> workdir($path), "$path/";

is $repo -> is_empty, 1;
is $disc -> is_empty, 1;

my $head = eval { $repo -> head };
is $head, undef;

my $odb = $repo -> odb;
isa_ok $odb, 'Git::Raw::Odb';

my $file  = $repo -> workdir . 'ignore';
write_file($file, 'this file should be ignored');

$file = $repo -> workdir . 'untracked';
write_file($file, 'this file should be untracked');

$repo -> ignore("ignore\n");

is_deeply $repo -> status({'flags' => {'include_ignored' => 1}}, 'ignore') -> {'ignore'},
	{'flags' => ['ignored']};

is_deeply $repo -> status({'flags' => {'include_untracked' => 1}}, 'untracked') -> {'untracked'},
	{'flags' => ['worktree_new']};

is_deeply $repo -> status({'flags' => {'include_untracked' => 1, 'include_ignored' => 1}}), {
	'ignore'    => {'flags' => ['ignored']},
	'untracked' => {'flags' => ['worktree_new']},
	'subdir/'   => {'flags' => ['ignored']}};

my $index = $repo -> index;
my $repo2 = $index -> owner;
isa_ok $repo2, 'Git::Raw::Repository';
is $repo2 -> path, $repo -> path;

is $index -> version, 2;
$index -> version(4);
is $index -> version, 4;

ok (eval { $index -> capabilities });

my $caps_count = $index -> capabilities;
is $caps_count, 3;

my %caps = $index -> capabilities;
is scalar (keys %caps), 3;

ok exists $caps{'ignore_case'};
ok exists $caps{'no_filemode'};
ok exists $caps{'no_symlinks'};

is $caps{ignore_case}, 1 if ($^O eq 'darwin' || $^O eq 'MSWin32');

my $triggered_add = 0;
$index -> add_all({
	'paths' => [ 'ign*' ],
	'flags' => {
		'force'                  => 1,
		'disable_pathspec_match' => 1
	},
	'notification' => sub {
		$triggered_add = 1;
		0;
	}
});
is $triggered_add, 0;

$index -> add_all({
	'paths' => [ 'ign*' ],
	'flags' => {
		'force'                  => 1,
		'disable_pathspec_match' => 1
	},
	'notification' => sub {
		$triggered_add = 1;
		0;
	}
});
is $triggered_add, 0;

$index -> add_all({
	'paths' => [ 'ign*' ],
	'flags' => {
		'force' => 1
	},
	'notification' => sub {
		my ($path, $spec) = @_;

		is $path, 'ignore';
		is $spec, 'ign*';

		$triggered_add = 1;
		0;
	}
});
is $triggered_add, 1;

is_deeply $repo -> status({}) -> {'ignore'},
	{'flags' => ['index_new']};

my $triggered_removed = 0;
$index -> remove_all({
	'paths' => [ 'ignore' ],
	'notification' => sub {
		$triggered_removed = 1;
		0;
	}
});

is $triggered_removed, 1;
is_deeply $repo -> status({'flags' => {'include_ignored' => 1}}) -> {'ignore'},
	{'flags' => ['ignored']};

$file = $repo -> workdir . 'subdir/' .'untracked';
write_file($file, 'this file should be untracked');
is_deeply $repo -> status({'flags' => {'include_untracked' => 1}}, 'subdir/') -> {'subdir/'},
	{'flags' => ['worktree_new']};

is $repo -> path_is_ignored('ignore'), 1;
is $repo -> path_is_ignored('test'), 0;
is $repo -> path_is_ignored('untracked'), 0;

my $config = $repo -> config;

my $name  = 'Git::Raw author';
my $email = 'git-xs@example.com';

is undef, $config -> bool('some.bool');
ok (!eval { $config -> bool('some.bool', 1, 1) });
ok (!eval { $config -> bool('some.bool', 'zzzz') });

my $error = $@;
ok ($error);
isa_ok($error, 'Git::Raw::Error');
is $error -> file, 't/01-repo.t';
is $error -> line, 157;
is "$error", "Invalid type for 'value', expected an integer at t/01-repo.t line 157";
is $error -> code, Git::Raw::Error -> USAGE;
like $error, qr/Invalid type/;
is $error -> category, Git::Raw::Error::Category -> INTERNAL;

ok $config -> bool('some.bool', 1);
ok $config -> bool('some.bool');

is undef, $config -> int('some.int');
is $config -> int('some.int', 42), 42;
is $config -> int('some.int'), 42;

is undef, $config -> str('some.str');
is $config -> str('some.str', 'hello'), 'hello';
is $config -> str('some.str'), 'hello';

is $config -> str('user.name', $name), $name;
is $config -> str('user.email', $email), $email;

is $config -> str('user.name'), $name;
is $config -> str('user.email'), $email;

eval { $config -> foreach(sub { 1; }) };
ok (!$@);

$config -> foreach(sub {
	my ($entry_name, $entry_value, $entry_level) = @_;

	ok $entry_value          if $entry_name eq 'some.bool';
	is $entry_value, 42      if $entry_name eq 'some.int';
	is $entry_value, 'hello' if $entry_name eq 'some.str';

	0
});

$config -> delete('some.bool');
is undef, $config -> bool('some.bool');
ok $config -> bool('some.bool', 1);
ok $config -> bool('some.bool');

my $default_config = Git::Raw::Config -> default;
isa_ok $default_config, 'Git::Raw::Config';

my $detached_config1 = Git::Raw::Config -> new;
isa_ok $detached_config1, 'Git::Raw::Config';
$detached_config1 -> add_file('.testconfig', 5);

my $detached_config2 = Git::Raw::Config -> new;
isa_ok $detached_config2, 'Git::Raw::Config';
$detached_config2 -> add_file('.testconfig', 5);

$detached_config1 -> str('some.str', 'hello');
is 'hello', $detached_config1 -> str('some.str');
is 'hello', $detached_config2 -> str('some.str');

$detached_config1 = undef;
$detached_config2 = undef;
unlink '.testconfig';
isnt -f '.testconfig', 1;

is $repo -> state, "none";
is $repo -> is_head_detached, 0;

my $commit_msg_file = catfile($repo -> path, 'MERGE_MSG');
ok (open HANDLE, ">$commit_msg_file");
ok (close HANDLE);

$repo -> state_cleanup;
isnt -f $commit_msg_file, 1;
is $repo -> state, "none";

my $revert_head_file = catfile($repo -> path, 'REVERT_HEAD');
ok (open HANDLE, ">$revert_head_file");
ok (close HANDLE);

is $repo -> state, "revert";
$repo -> state_cleanup;
isnt -f $revert_head_file, 1;
is $repo -> state, "none";

my $merge_head_file = catfile($repo -> path, 'MERGE_HEAD');
ok (open HANDLE, ">$merge_head_file");
ok (close HANDLE);

is $repo -> state, "merge";
$repo -> state_cleanup;
isnt -f $merge_head_file, 1;
is $repo -> state, "none";

my $cherry_pick_head_file = catfile($repo -> path, 'CHERRY_PICK_HEAD');
ok (open HANDLE, ">$cherry_pick_head_file");
ok (close HANDLE);

is $repo -> state, "cherry_pick";
$repo -> state_cleanup;
isnt -f $cherry_pick_head_file, 1;
is $repo -> state, "none";

my $bisect_log_file = catfile($repo -> path, 'BISECT_LOG');
ok (open HANDLE, ">$bisect_log_file");
ok (close HANDLE);

is $repo -> state, "bisect";
$repo -> state_cleanup;
isnt -f $bisect_log_file, 1;
is $repo -> state, "none";

my $rebase_merge_dir = catfile($repo -> path, 'rebase-merge');
my $rebase_apply_dir = catfile($repo -> path, 'rebase-apply');

make_path($rebase_merge_dir);
is $repo -> state, "rebase_merge";
$repo -> state_cleanup;
isnt -e $rebase_merge_dir, 1;
is $repo -> state, "none";

make_path($rebase_apply_dir);
is $repo -> state, "mailbox_or_rebase";
$repo -> state_cleanup;
isnt -e $rebase_apply_dir, 1;
is $repo -> state, "none";

my $rebase_rebasing_file = catfile($rebase_apply_dir, 'rebasing');
make_path($rebase_apply_dir);
ok (open HANDLE, ">$rebase_rebasing_file");
ok (close HANDLE);

is $repo -> state, "rebase";
$repo -> state_cleanup;
isnt -f $rebase_rebasing_file, 1;
is $repo -> state, "none";

my $rebase_applying_file = catfile($rebase_apply_dir, 'applying');
make_path($rebase_apply_dir);
ok (open HANDLE, ">$rebase_applying_file");
ok (close HANDLE);

is $repo -> state, "apply_mailbox";
$repo -> state_cleanup;
isnt -f $rebase_applying_file, 1;
is $repo -> state, "none";

my $rebase_interactive_file = catfile($rebase_merge_dir, 'interactive');
make_path($rebase_merge_dir);
ok (open HANDLE, ">$rebase_interactive_file");
ok (close HANDLE);

is $repo -> state, "rebase_interactive";
$repo -> state_cleanup;
isnt -f $rebase_interactive_file, 1;
is $repo -> state, "none";

my $message = q{Some message
# With comments
};

ok (!eval { Git::Raw -> message_prettify($message, 1, 'blah') });

my $clean = Git::Raw -> message_prettify($message, 1, '!');
is $clean, $message;

$clean = Git::Raw -> message_prettify($message, 0, '#');
is $clean, $message;

$clean = Git::Raw -> message_prettify($message, 1, '#');
is $clean, "Some message\n";

$message = q{Some message
! With comments
And more content
! With comments
};

$clean = Git::Raw -> message_prettify($message, 1, '!');
is $clean, q{Some message
And more content
};

done_testing;
