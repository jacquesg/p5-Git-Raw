package inc::MakeMaker;

use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
	my ($self) = @_;

	my $template  = <<'EOS';
use File::Which;

unless (which("cmake")) { print "Can't find cmake\n"; exit }

chdir("xs");
system(
	"cmake",
	"-D", "BUILD_SHARED_LIBS:BOOL=OFF",
	"-D", "BUILD_CLAR:BOOL=OFF",
	"libgit2"
);
system("make");
chdir("..");
EOS

	return $template.super();
};

override _build_WriteMakefile_args => sub {
	return +{
		%{ super() },
		INC	=> '-I. -Ixs/libgit2/include',
		OBJECT	=> '$(O_FILES) xs/libgit2.a',
	}
};

__PACKAGE__ -> meta -> make_immutable;
