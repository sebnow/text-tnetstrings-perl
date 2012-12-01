use 5.006;
use strict;
use warnings;
use File::Spec;
use Module::Build;

my $builder = Module::Build->new(
	module_name          => 'Text::TNetstrings',
	license              => 'mit',
	extra_compiler_flags => qw(-Werror -Wall),
	extra_linker_flags   => ['-lm'],
	use_tap_harness      => 1,
	configure_requires => {
		'version' => '>=0.77',
		'Module::Build' => 0,
	},
	build_requires => {
		'Test::More'  => 0,
		'Test::Class' => 0,
	},
	requires => {
		'perl'         => 5.008,
		'version'      => '>=0.77',
		'Scalar::Util' => 0,
	},
	recommends => {
		'boolean' => 0,
	},
	add_to_cleanup     => [ 'Text-TNetstrings-*' ],
);

my $blib_dir = File::Spec->catdir($builder->base_dir, $builder->blib);
my $lib_dir = File::Spec->catdir($blib_dir, 'lib');
my $arch_dir = File::Spec->catdir($blib_dir, 'arch');
$builder->tap_harness_args('lib' => [$arch_dir, $lib_dir, 't/lib']);
$builder->create_build_script();
