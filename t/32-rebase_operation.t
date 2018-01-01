#!perl

use Test::More;

use Git::Raw;

is 0, Git::Raw::Rebase::Operation -> PICK;
is 1, Git::Raw::Rebase::Operation -> REWORD;
is 2, Git::Raw::Rebase::Operation -> EDIT;
is 3, Git::Raw::Rebase::Operation -> SQUASH;
is 4, Git::Raw::Rebase::Operation -> FIXUP;
is 5, Git::Raw::Rebase::Operation -> EXEC;

done_testing;
