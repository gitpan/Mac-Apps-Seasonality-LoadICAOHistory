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

    eval 'use IO::Scalar;';

    if ($EVAL_ERROR) {
        eval q/
            use Test::More skip_all => q{because IO::Scalar isn't installed.};
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
use Mac::Apps::Seasonality::LoadICAOHistoryFromCSV qw{ load_icao_history_from_csv_handle };

my $database_connection = create_test_database();

eval {
    # Split assignment in two to suppress 'Name "Test::DatabaseRow::dbh" used only once' warning.
    local $Test::DatabaseRow::dbh = undef;
    $Test::DatabaseRow::dbh = $database_connection;

    my $test_data_ref = build_test_data();
    my $io_handle = create_io_scalar_from_test_data($test_data_ref);

    load_icao_history_from_csv_handle($database_connection, $io_handle);

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

    $io_handle = create_io_scalar_from_test_data($test_data_ref);
    load_icao_history_from_csv_handle($database_connection, $io_handle);

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

sub create_io_scalar_from_test_data {
    my $test_data_ref = shift;
    my $csv_string;

    foreach my $test_point_ref ( @{$test_data_ref} ) {
        $csv_string .= join ',', @{$test_point_ref};
        $csv_string .= "\n";
    } # end foreach

    return IO::Scalar->new(\$csv_string);
} # end create_io_scalar_from_test_data()

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
