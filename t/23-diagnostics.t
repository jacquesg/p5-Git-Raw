#!perl

use Test::More;

use Git::Raw;

my $count;
my %features;

ok (eval { Git::Raw -> features });

ok (eval { $count = Git::Raw -> features });
is $count, 3;

ok (eval { %features = Git::Raw -> features });
is scalar(keys %features), 3;

ok exists $features{'threads'};
ok exists $features{'https'};
ok exists $features{'ssh'};

diag("Build info:");
diag("Built with threads support: $features{'threads'}");
diag("Built with HTTPS support: $features{'https'}");
diag("Built with SSH support: $features{'ssh'}");

done_testing;
