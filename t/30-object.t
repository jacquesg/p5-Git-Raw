#!perl

use Test::More;
use Git::Raw;

is -2, Git::Raw::Object -> ANY;
is -1, Git::Raw::Object -> BAD;
is 1, Git::Raw::Object -> COMMIT;
is 2, Git::Raw::Object -> TREE;
is 3, Git::Raw::Object -> BLOB;
is 4, Git::Raw::Object -> TAG;

done_testing;

