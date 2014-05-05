#!perl

use Test::More;

use Git::Raw;

my %features;

ok (eval { %features = Git::Raw -> features });
is scalar(keys %features), 3;

diag("Build info:");
diag("Built with threads support: $features{threads}");
diag("Built with HTTPS support: $features{https}");
diag("Built with SSH support: $features{ssh}");

done_testing;
