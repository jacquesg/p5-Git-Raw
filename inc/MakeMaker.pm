package inc::MakeMaker;

use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
	my ($self) = @_;

	my $template  = <<'TEMPLATE';
chdir('xs/libgit2');
system('make', '-f', 'Makefile.embed');
chdir('../..');

TEMPLATE

	return $template.super();
};

override _build_WriteMakefile_args => sub {
	return +{
		%{ super() },
		INC	=> '-I. -Ixs/libgit2/include',
		OBJECT	=> '$(O_FILES) xs/libgit2/libgit2.a',
	}
};

__PACKAGE__ -> meta -> make_immutable;
