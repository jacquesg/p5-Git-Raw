package inc::MakeMaker;

use Moose;
use Config;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
	my ($self) = @_;

	my $template = <<'TEMPLATE';
use strict;
use warnings;
use Config;
use Getopt::Long;
use File::Basename qw(basename dirname);

use Devel::CheckLib;

# compiler detection
my $is_gcc = length($Config{gccversion});
my $is_msvc = $Config{cc} eq 'cl' ? 1 : 0;
my $is_sunpro = (length($Config{ccversion}) && !$is_msvc) ? 1 : 0;

# os detection
my $is_solaris = ($^O =~ /(sun|solaris)/i) ? 1 : 0;
my $is_windows = ($^O =~ /MSWin32/i) ? 1 : 0;
my $is_linux = ($^O =~ /linux/i) ? 1 : 0;
my $is_osx = ($^O =~ /darwin/i) ? 1 : 0;

# allow the user to override/specify the locations of OpenSSL and libssh2
our $opt = {};

Getopt::Long::GetOptions(
	"help" => \&usage,
	'with-openssl-include=s' => \$opt->{'ssl'}->{'incdir'},
	'with-openssl-libs=s@'   => \$opt->{'ssl'}->{'libs'},
	'with-libssh2-include=s' => \$opt->{'ssh2'}->{'incdir'},
	'with-libssh2-lib=s@'    => \$opt->{'ssh2'}->{'libs'},
) || die &usage();

my $def = '';
my $lib = '';
my $inc = '';
my $ccflags = '';

my %os_specific = (
	'darwin' => {
		'ssh2' => {
			'inc' => ['/opt/local/include'],
			'lib' => ['/opt/local/lib']
		}
	},
	'freebsd' => {
		'ssh2' => {
			'inc' => ['/usr/local/include'],
			'lib' => ['/usr/local/lib']
		}
	}
);

my $ssh2_libpath;
my $ssh2_incpath;
if (my $os_params = $os_specific{$^O}) {
	if (my $ssh2 = $os_params -> {'ssh2'}) {
		$ssh2_libpath = $ssh2 -> {'lib'};
		$ssh2_incpath = $ssh2 -> {'inc'};
	}
}

my %library_tests = (
	'ssl' => {
		'lib'     => 'ssl',
		'header'  => 'openssl/opensslconf.h',
	},
	'ssh2' => {
		'lib'     => 'ssh2',
		'libpath' => $ssh2_libpath,
		'incpath' => $ssh2_incpath,
		'header'  => 'libssh2.h',
	}
);

my %library_opts = (
	'ssl' => {
		'defines' => ' -DGIT_SSL',
		'libs'    => ' -lssl -lcrypto',
	},
	'ssh2' => {
		'defines' => ' -DGIT_SSH',
		'libs'    => ' -lssh2',
	}
);

# check for optional libraries
while (my ($library, $test) = each %library_tests) {
	my $user_library_opt = $opt->{$library};
	my $user_incpath = $user_library_opt->{'incdir'};
	my $user_libs = $user_library_opt->{'libs'};

	if ($user_incpath && $user_libs) {
		$inc .= " -I$user_incpath";

		# perform some magic
		foreach my $user_lib (@$user_libs) {
			my ($link_dir, $link_lib) = (dirname($user_lib), basename($user_lib));

			if (!$is_msvc) {
				my @tokens = grep { $_ } split(/(lib|.)/, $link_lib);
				shift @tokens if ($tokens[0] eq 'lib');
				$link_lib = shift @tokens;
			}
			$lib .= " -L$link_dir -l$link_lib";
		}

		my $opts = $library_opts{$library};
		$def .= $opts->{'defines'};

		print uc($library), " support enabled (user provided)", "\n";
	} elsif (check_lib(%$test)) {
		if (exists($test->{'incpath'})) {
			if (my $incpath = $test->{'incpath'}) {
				$inc .= ' -I'.join (' -I', @$incpath);
			}
		}

		if (exists($test->{'libpath'})) {
			if (my $libpath = $test->{'libpath'}) {
				$lib .= ' -L'.join (' -L', @$libpath);
			}
		}

		my $opts = $library_opts{$library};
		$def .= $opts->{'defines'};
		$lib .= $opts->{'libs'};

		print uc($library), " support enabled", "\n";
	} else {
		print uc($library), " support disabled", "\n";
	}
}

# universally supported
$def .= ' -DNO_VIZ -DSTDC -DNO_GZIP -D_FILE_OFFSET_BITS=64 -D_GNU_SOURCE';

# supported on Solaris
if ($is_solaris) {
	$def .= ' -D_POSIX_C_SOURCE=200112L -D__EXTENSIONS__ -D_POSIX_PTHREAD_SEMANTICS';
}

if ($is_gcc) {
	# gcc-like compiler
	$ccflags .= ' -Wall -Wno-unused-variable -Wdeclaration-after-statement';

	# clang compiler is pedantic!
	if ($is_osx) {
		$ccflags .= ' -Wno-deprecated-declarations -Wno-unused-const-variable -Wno-unused-function';
	}

	if ($is_solaris) {
		$ccflags .= ' -std=c99';
	}
} elsif ($is_sunpro) {
	# probably the SunPro compiler
	$def .= ' -D_STDC_C99';

	$ccflags .= ' -errtags=yes -erroff=E_EMPTY_TRANSLATION_UNIT -erroff=E_ZERO_OR_NEGATIVE_SUBSCRIPT';
	$ccflags .= ' -erroff=E_EMPTY_DECLARATION -erroff=E_STATEMENT_NOT_REACHED';
}

# building with a 32-bit perl on a 64-bit OS may require this (supported by cc and gcc-like compilers)
if ($Config{gccversion} || $Config{gccversion}) {
	if ($Config{ptrsize} == 4) {
		$ccflags .= ' -m32';
	}
}

if ($Config{usethreads}) {
	if (check_lib(lib => 'pthread')) {
		$def .= ' -DGIT_THREADS';
		$lib .= ' -lpthread';

		print "Threads support enabled\n";
	} else {
		if ($is_windows) {
			$def .= ' -DGIT_THREADS';
		} else {
			print "Threads support disabled\n";
		}
	}
}

my @deps = glob 'deps/libgit2/deps/{http-parser,zlib}/*.c';
my @srcs = glob 'deps/libgit2/src/{*.c,transports/*.c,xdiff/*.c}';
push @srcs, 'deps/libgit2/src/hash/hash_generic.c';

# the system regex is broken on Solaris, not available on Windows
if ($is_windows || $is_solaris) {
	push @srcs, 'deps/libgit2/deps/regex/regex.c';
	$inc .= ' -Ideps/libgit2/deps/regex';
}

if ($is_windows) {
	push @srcs, glob 'deps/libgit2/src/{win32,compat}/*.c';

	$def .= ' -DWIN32 -DGIT_WIN32';

	if ($is_msvc) {
		# visual studio compiler
		$def .= ' -D_CRT_SECURE_NO_WARNINGS';
	} else {
		# mingw/cygwin
		$def .= ' -D_WIN32_WINNT=0x0501 -D__USE_MINGW_ANSI_STDIO=1';
	}
} else {
	push @srcs, glob 'deps/libgit2/src/unix/*.c'
}

# real-time library is required for Solaris and Linux
if ($is_linux || $is_solaris) {
	$lib .= ' -lrt';
}

my @objs = map { substr ($_, 0, -1) . 'o' } (@deps, @srcs);

sub MY::c_o {
	my $out_switch = '-o ';

	if ($is_msvc) {
		$out_switch = '/Fo';
	}

	my $line = qq{
.c\$(OBJ_EXT):
	\$(CCCMD) \$(CCCDLFLAGS) "-I\$(PERL_INC)" \$(PASTHRU_DEFINE) \$(DEFINE) \$*.c $out_switch\$@
};
	return $line;
}

# This Makefile.PL for {{ $distname }} was generated by Dist::Zilla.
# Don't edit it but the dist.ini used to construct it.
{{ $perl_prereq ? qq[BEGIN { require $perl_prereq; }] : ''; }}
use strict;
use warnings;
use ExtUtils::MakeMaker {{ $eumm_version }};
{{ $share_dir_block[0] }}
my {{ $WriteMakefileArgs }}

$WriteMakefileArgs{DEFINE}  .= $def;
$WriteMakefileArgs{LIBS}    .= $lib;
$WriteMakefileArgs{INC}     .= $inc;
$WriteMakefileArgs{CCFLAGS} .= $ccflags;
$WriteMakefileArgs{OBJECT}  .= ' ' . join ' ', @objs;

unless (eval { ExtUtils::MakeMaker->VERSION(6.56) }) {
	my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
	my $pp = $WriteMakefileArgs{PREREQ_PM};

	for my $mod (keys %$br) {
		if (exists $pp -> {$mod}) {
			$pp -> {$mod} = $br -> {$mod}
				if $br -> {$mod} > $pp -> {$mod};
		} else {
			$pp -> {$mod} = $br -> {$mod};
		}
	}
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
	unless eval { ExtUtils::MakeMaker -> VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
exit(0);

sub usage {
	print STDERR << "USAGE";
Usage: perl $0 [options]

Possible options are:
  --with-openssl-include=<path>    Specify <path> for the root of the OpenSSL installation.
  --with-openssl-libs=<libs>       Specify <libs> for the OpenSSL libraries.
  --with-libssh2-include=<path>    Specify <path> for the root of the libssh2 installation.
  --with-libssh2-lib=<lib>         Specify <lib> for the libssh2 library.
USAGE

	exit(1);
}

{{ $share_dir_block[1] }}
TEMPLATE

	return $template;
};

override _build_WriteMakefile_args => sub {
	return +{
		%{ super() },
		INC	    => '-I. -Ideps/libgit2 -Ideps/libgit2/src -Ideps/libgit2/include -Ideps/libgit2/deps/http-parser -Ideps/libgit2/deps/zlib',
		OBJECT	=> '$(O_FILES)',
	}
};

__PACKAGE__ -> meta -> make_immutable;
