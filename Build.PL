use strict;
use warnings;

use English qw{ −no_match_vars };

use Module::Build;


BEGIN {

if ( $OSNAME ne 'darwin' ) {
    print {*STDERR} "This distribution can only be used under MacOS X.\nAborting.\n";
    exit 1;
} # end if ( $OSNAME ne 'darwin' )

eval "use Mac::Processes;";
if ($EVAL_ERROR) {
    print {*STDERR}
        "Cannot determine whether particular applications are installed or not (Mac::Processes is not available).\nAborting.\n";
    exit 1;
} # end if ($EVAL_ERROR)

} # end BEGIN


my $class;
my $builder;

BEGIN {

$class = Module::Build->subclass( code => <<'SUBCLASS' );

    sub ACTION_authortest {
        my $self = shift;

        $self->dispatch('build');
        $self->recursive_test_files(1);
        $self->dispatch('test');
    } # end ACTION_authortest()

SUBCLASS

$builder = $class->new(
    module_name     => 'Mac::Apps::Seasonality::LoadICAOHistory',
    license         => 'perl',
    dist_author     => 'Elliot Shank <perl@galumph.com>',
    dist_abstract   =>
        "Load historical data into Seasonality (http://gauchosoft.com/Software/Seasonality/) from sources that it cannot handle itself.",
    dynamic_config  => 1,
    build_requires  => {
        'version'                           => 0,
        'Mac::Processes'                    => 0,
        'Readonly'                          => 0,
        'Test::More'                        => 0,
        'Mac::Apps::Seasonality::Constants' => 0,
    },
    requires        => {
        'perl'                              => '5.8.6',
        'version'                           => 0,
        'DBD::SQLite2'                      => 0,
        'Exception::Class'                  => 0,
        'Getopt::Euclid'                    => 0,
        'Mac::Apps::Launch'                 => 0,
        'Mac::Processes'                    => 0,
        'Readonly'                          => 0,
        'Regexp::Common'                    => 0,
        'Text::CSV_XS'                      => 0,
        'Mac::Apps::Seasonality::Constants' => 0,
    },
    recommends      => {
        'File::Find::Rule'              => 0,
        'File::Slurp'                   => 0,
        'Mac::Growl'                    => 0,
        'Perl::Critic'                  => 0,
        'Pod::Coverage::CountParents'   => 0,
        'Test::DatabaseRow'             => 0,
        'Test::Distribution'            => 0,
        'Test::Exception'               => 0,
        'Test::Perl::Critic'            => 0,
        'Test::Pod'                     => 0,
        'Test::Pod::Coverage'           => 0,
        'Test::Spelling'                => 0,
    },
    script_files    => [ glob('script/*') ],
    create_packlist => 1,
    sign            => 0,
    add_to_cleanup  => [
        'Mac-Apps-Seasonality-LoadICAOHistory-*',
        '*.vim_backup',
        'pod2htm?.tmp',
    ],
);

} # end BEGIN


use lib $builder->base_dir() . '/lib';


BEGIN {

eval 'use Mac::Apps::Seasonality::Constants qw{ $SEASONALITY_NAME $SEASONALITY_CREATOR };';
if ($EVAL_ERROR) {
    print {*STDERR}
        "Cannot find application metadata.\nAborting.\n";
    exit 1;
} # end if ($EVAL_ERROR)

} # end BEGIN

if ( not LSFindApplicationForInfo($SEASONALITY_CREATOR) ) {
    print {*STDERR} "$SEASONALITY_NAME does not appear to be installed.\nAborting.\n";
    exit 1;
} # end if ( not LSFindApplicationForInfo...


$builder->create_build_script();

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=0 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
