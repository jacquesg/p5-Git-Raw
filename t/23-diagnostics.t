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
is -8,  Git::Raw::Error->EBAREREPO;
is -9,  Git::Raw::Error->EUNBORNBRANCH;
is -10, Git::Raw::Error->EUNMERGED;
is -11, Git::Raw::Error->ENONFASTFORWARD;
is -12, Git::Raw::Error->EINVALIDSPEC;
is -13, Git::Raw::Error->ECONFLICT;
is -14, Git::Raw::Error->ELOCKED;
is -15, Git::Raw::Error->EMODIFIED;
is -16, Git::Raw::Error->EAUTH;
is -17, Git::Raw::Error->ECERTIFICATE;
is -18, Git::Raw::Error->EAPPLIED;
is -19, Git::Raw::Error->EPEEL;
is -20, Git::Raw::Error->EEOF;
is -21, Git::Raw::Error->EINVALID;
is -22, Git::Raw::Error->EUNCOMMITTED;
is -23, Git::Raw::Error->EDIRECTORY;
is -24, Git::Raw::Error->EMERGECONFLICT;

is -30, Git::Raw::Error->PASSTHROUGH;

ok (!eval { Git::Raw::Error->RANDOM_CONSTANT });

done_testing;
