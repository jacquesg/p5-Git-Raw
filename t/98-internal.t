#!perl

use Test::More;

use Git::Raw;

eval { Git::Raw::Test->assert(); };

my $error = $@;

like $error, qr|Assertion failed|;
like $error, qr|Test.xs:11|;
ok index ($error, 'croaking: ') != -1;
ok index ($error, '12345') != -1;

done_testing;
