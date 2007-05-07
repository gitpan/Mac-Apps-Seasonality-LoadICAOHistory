use strict;
use warnings;

use English qw{ -no_match_vars };

BEGIN {
    eval 'use Test::DatabaseRow;';

    if ($EVAL_ERROR) {
        eval q/
            use Test::More skip_all => q{because Test::DatabaseRow isn't installed.};
        /;
    }
}

use Module::Build;
use File::Spec::Functions;
use Test::More tests => 10;

my $build;

BEGIN {
    $build = Module::Build->current();
} # end BEGIN

use lib catfile($build->base_dir(), 't', 'lib');

use Mac::Apps::Seasonality::TestUtilities qw{ :all };
use Mac::Apps::Seasonality::Constants qw{ :all };
use Mac::Apps::Seasonality::LoadICAOHistory qw{ &load_icao_history };

my $database_connection = create_test_database();

eval {
    # Split assignment in two to suppress 'Name "Test::DatabaseRow::dbh" used only once' warning.
    local $Test::DatabaseRow::dbh = undef;
    $Test::DatabaseRow::dbh = $database_connection;

    my $test_data_ref = build_test_data();

    load_icao_history($database_connection, $test_data_ref);

    # TEST*3
    foreach my $test_point_ref ( @{$test_data_ref} ) {
        test_point_ok( $test_point_ref );
    } # end foreach

    # TEST*2
    db_status_table_ok( scalar( @{$test_data_ref} ) );


    # Do an update of existing data.
    foreach my $x ( (0..$#{$test_data_ref}) ) {
        $test_data_ref->[$x][2] = $x * 23;  # Wind direction
    } # end foreach

    load_icao_history($database_connection, $test_data_ref);

    # TEST*3
    foreach my $test_point_ref (@{$test_data_ref}) {
        test_point_ok( $test_point_ref );
    } # end foreach

    # TEST*2
    db_status_table_ok( 2 * scalar( @{$test_data_ref} ) );
}; # end eval

$database_connection->disconnect();

if ($EVAL_ERROR) {
    die $EVAL_ERROR;
} # end if

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
