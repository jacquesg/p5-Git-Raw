#!perl

use Test::More;

use Git::Raw;

my $refspec = Git::Raw::RefSpec -> parse ("+refs/heads/*:refs/remotes/origin/*", 1);
isa_ok $refspec, "Git::Raw::RefSpec";

is $refspec -> src, "refs/heads/*";
is $refspec -> dst, "refs/remotes/origin/*";
is $refspec -> direction, "fetch";
is $refspec -> string, "+refs/heads/*:refs/remotes/origin/*";
is $refspec -> is_force, 1;

done_testing;

