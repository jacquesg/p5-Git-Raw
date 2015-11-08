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

# constants
is  0,  Git::Raw::Error->OK;
is -1,  Git::Raw::Error->ERROR;
is -3,  Git::Raw::Error->ENOTFOUND;
is -4,  Git::Raw::Error->EEXISTS;
is -5,  Git::Raw::Error->EAMBIGUOUS;
is -6,  Git::Raw::Error->EBUFS;
is -7,  Git::Raw::Error->EUSER;
is -8,  Git::Raw::Error->EBAREREPO;
is -9,  Git::Raw::Error->EUNBORNBRANCH;
is -10, Git::Raw::Error->EUNMERGED;
is -11, Git::Raw::Error->ENONFASTFORWARD;
is -12, Git::Raw::Error->EINVALIDSPEC;
is -13, Git::Raw::Error->ECONFLICT;
is -14, Git::Raw::Error->ELOCKED;
is -15, Git::Raw::Error->EMODIFIED;
is -30, Git::Raw::Error->PASSTHROUGH;
is -31, Git::Raw::Error->ITEROVER;

ok (!eval { Git::Raw::Error->RANDOM_CONSTANT });

done_testing;
