#!perl

use Test::More;

use Git::Raw;
use File::Copy;
use File::Slurp;
use Cwd qw(abs_path);
use File::Path 2.07 qw(make_path remove_tree);

my $path = abs_path('t/test_repo');
my $repo = Git::Raw::Repository -> open($path);

my @status = $repo->status();

ok (!eval { Git::Raw::PathSpec -> new });
my $error = $@;
isa_ok $error, 'Git::Raw::Error';
is $error -> code, Git::Raw::Error -> USAGE;
is $error -> category, Git::Raw::Error::Category -> INTERNAL;

ok (!eval { Git::Raw::PathSpec -> new($repo) });
$error = $@;
isa_ok $error, 'Git::Raw::Error';

my $spec = Git::Raw::PathSpec -> new('blah');
isa_ok $spec, 'Git::Raw::PathSpec';

my $list;

ok (!eval { $spec -> match('') });
$error = $@;
isa_ok $error, 'Git::Raw::Error';
is $error -> code, Git::Raw::Error -> USAGE;
is $error -> category, Git::Raw::Error::Category -> INTERNAL;

ok (!eval { $list = $spec -> match($repo, {
	'flags' => {
		'no_match_error' => 1
	}
}) });

$list = $spec -> match($repo);
isa_ok $list, 'Git::Raw::PathSpec::MatchList';

is $list -> count, 0;
is $list -> failed_count, 0;

$list = $spec -> match($repo, {
	'flags' => {
		'find_failures' => 1
	}
});

is $list -> count, 0;
is $list -> failed_count, 1;

my @failures = $list -> failed_entries;
is scalar(@failures), 1;
my $failure = shift @failures;
is $failure, 'blah';

$spec = Git::Raw::PathSpec -> new('t*');
$list = $spec -> match($repo);
is $list -> count, 2;

my @entries = $list -> entries;
is scalar(@entries), 2;
is_deeply [ @entries ], ['test', 'test2'];

$list = $spec -> match($repo -> index);
is $list -> count, 2;

$spec = Git::Raw::PathSpec -> new('t*', 'untra*');
$list = $spec -> match($repo, {
	'flags' => {
		'find_failures' => 1
	}
});

is $list -> count, 2;
is $list -> failed_count, 1;

$spec = Git::Raw::PathSpec -> new('T*');
$list = $spec -> match($repo, {
	'flags' => {
		'find_failures' => 1,
		'ignore_case'   => 1
	}
});

is $list -> count, 2;

my $filter_branch = Git::Raw::Branch -> lookup($repo, 'filter_branch', 1);
isa_ok $filter_branch, 'Git::Raw::Branch';

$spec = Git::Raw::PathSpec -> new('T*', 'f*');
$list = $spec -> match($filter_branch -> target -> tree, {
	'flags' => {
		'ignore_case'   => 1
	}
});

@entries = $list -> entries;
is $list -> count, 3;
is_deeply [ @entries ], ['filterfile', 'test', 'test2'];

my $some_branch = Git::Raw::Branch -> lookup($repo, 'some_branch', 1);
isa_ok $some_branch, 'Git::Raw::Branch';
isa_ok $some_branch, 'Git::Raw::Reference';
my $commit = $some_branch -> target;
isa_ok $commit, 'Git::Raw::Commit';

$list = $spec -> match($commit -> tree, {
	'flags' => {
		'ignore_case'   => 1
	}
});
is $list -> count, 3;

@entries = $list -> entries;
is_deeply [ @entries ], ['test', 'test2', 'test3/under/the/tree/test3'];

$spec = Git::Raw::PathSpec -> new('*test*');
$list = $spec -> match($commit -> tree);
is $list -> count, 3;

@entries = $list -> entries;
is_deeply [ @entries ], ['test', 'test2', 'test3/under/the/tree/test3'];

$spec = Git::Raw::PathSpec -> new('**/test*');
$list = $spec -> match($commit -> tree);
is $list -> count, 3;

@entries = $list -> entries;
is_deeply [ @entries ], ['test', 'test2', 'test3/under/the/tree/test3'];

done_testing;
