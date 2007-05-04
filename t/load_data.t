use strict;
use warnings;

use Module::Build;
use File::Spec::Functions;
use Test::More tests => 10;

my $build;

BEGIN {
    $build = Module::Build->current();
} # end BEGIN

use lib catfile($build->base_dir(), 't', 'lib');

use Mac::Apps::Seasonality::TestUtilities;
use Mac::Apps::Seasonality::Constants qw{ :all };
use Mac::Apps::Seasonality::LoadICAOHistory qw{ load_icao_history };

SKIP: {
    eval 'use Test::DatabaseRow;';

    skip( "because Test::DatabaseRow isn't installed.", Test::More->builder->expected_tests() )
        if $@;

    sub db_status_table_ok {
        my $insert_count = shift;

        row_ok(
            sql     => "SELECT COUNT(*) AS count FROM $SEASONALITY_DB_STATUS_TABLE",
            tests   => [ count => 1 ],
            label   => "There should always be 1 and only 1 row in $SEASONALITY_DB_STATUS_TABLE.",
        );
        row_ok(
            sql     =>
                "SELECT $SEASONALITY_DB_STATUS_COLUMN_NEW_RECORDS_SINCE_VACUUM FROM $SEASONALITY_DB_STATUS_TABLE",
            tests   => [ $SEASONALITY_DB_STATUS_COLUMN_NEW_RECORDS_SINCE_VACUUM => $insert_count * 2 ],
            label   =>
                "The $SEASONALITY_DB_STATUS_COLUMN_NEW_RECORDS_SINCE_VACUUM column should be updated after an insert into $SEASONALITY_HISTORY_TABLE.",
        );
    } # end db_status_table_ok()

    {
        my $database_connection = createTestDatabase();

        eval {
            # Split assignment in two to suppress 'Name "Test::DatabaseRow::dbh" used only once' warning.
            local $Test::DatabaseRow::dbh = undef;
            $Test::DatabaseRow::dbh = $database_connection;

            my $test_data_ref =
                [
                    [
                        'blah_blah_blah',   # icao
                        '200609201751',     # date
                        330,                # wind_direction
                        8,                  # wind_speed_knots
                        0,                  # gust_speed_knots
                        10.000000,          # visibility_miles
                        16.000000,          # temperature_c
                        1.000000,           # dewpoint_c
                        1018,               # pressure_hpa
                        25,                 # relative_humidity
                    ],
                    [
                        'boing',            # icao
                        '200610150918',     # date
                        2,                  # wind_direction
                        57,                 # wind_speed_knots
                        59,                 # gust_speed_knots
                        0.000000,           # visibility_miles
                        31.5    ,           # temperature_c
                        15.000000,          # dewpoint_c
                        939,                # pressure_hpa
                        19,                 # relative_humidity
                    ],
                    [
                        'keep_music_evil',  # icao
                        '200512161530',     # date
                        -1,                 # wind_direction
                        -1000,              # wind_speed_knots
                        -1000,              # gust_speed_knots
                        -1000.000000,       # visibility_miles
                        -1000.000000,       # temperature_c
                        -1000.000000,       # dewpoint_c
                        -1000,              # pressure_hpa
                        -1000,              # relative_humidity
                    ],
                ];

            load_icao_history($database_connection, $test_data_ref);

            # TEST*3
            foreach my $test_point_ref (@{$test_data_ref}) {
                row_ok(
                    table   => $SEASONALITY_HISTORY_TABLE,
                    where   => [
                        $SEASONALITY_HISTORY_COLUMN_ICAO                => $test_point_ref->[0],
                        $SEASONALITY_HISTORY_COLUMN_DATE                => $test_point_ref->[1],
                    ],
                    results => 1,
                    tests   => [
                        $SEASONALITY_HISTORY_COLUMN_ICAO                => $test_point_ref->[0],
                        $SEASONALITY_HISTORY_COLUMN_DATE                => $test_point_ref->[1],
                        $SEASONALITY_HISTORY_COLUMN_WIND_DIRECTION      => $test_point_ref->[2],
                        $SEASONALITY_HISTORY_COLUMN_WIND_SPEED_KNOTS    => $test_point_ref->[3],
                        $SEASONALITY_HISTORY_COLUMN_GUST_SPEED_KNOTS    => $test_point_ref->[4],
                        $SEASONALITY_HISTORY_COLUMN_VISIBILITY_MILES    => $test_point_ref->[5],
                        $SEASONALITY_HISTORY_COLUMN_TEMPERATURE_C       => $test_point_ref->[6],
                        $SEASONALITY_HISTORY_COLUMN_DEWPOINT_C          => $test_point_ref->[7],
                        $SEASONALITY_HISTORY_COLUMN_PRESSURE_HPA        => $test_point_ref->[8],
                        $SEASONALITY_HISTORY_COLUMN_RELATIVE_HUMIDITY   => $test_point_ref->[9],
                    ],
                    label   => "$SEASONALITY_HISTORY_TABLE should have a row in it for $test_point_ref->[0].",
                );
            } # end foreach

            # TEST*2
            db_status_table_ok( scalar( @{$test_data_ref} ) );


            # Do an update of existing data.
            foreach my $x ((0..$#{$test_data_ref})) {
                $test_data_ref->[$x][2] = $x * 23;  # Wind direction
            } # end foreach

            load_icao_history($database_connection, $test_data_ref);

            # TEST*3
            foreach my $test_point_ref (@{$test_data_ref}) {
                row_ok(
                    table   => $SEASONALITY_HISTORY_TABLE,
                    where   => [
                        $SEASONALITY_HISTORY_COLUMN_ICAO                => $test_point_ref->[0],
                        $SEASONALITY_HISTORY_COLUMN_DATE                => $test_point_ref->[1],
                    ],
                    results => 1,
                    tests   => [
                        $SEASONALITY_HISTORY_COLUMN_ICAO                => $test_point_ref->[0],
                        $SEASONALITY_HISTORY_COLUMN_DATE                => $test_point_ref->[1],
                        $SEASONALITY_HISTORY_COLUMN_WIND_DIRECTION      => $test_point_ref->[2],
                        $SEASONALITY_HISTORY_COLUMN_WIND_SPEED_KNOTS    => $test_point_ref->[3],
                        $SEASONALITY_HISTORY_COLUMN_GUST_SPEED_KNOTS    => $test_point_ref->[4],
                        $SEASONALITY_HISTORY_COLUMN_VISIBILITY_MILES    => $test_point_ref->[5],
                        $SEASONALITY_HISTORY_COLUMN_TEMPERATURE_C       => $test_point_ref->[6],
                        $SEASONALITY_HISTORY_COLUMN_DEWPOINT_C          => $test_point_ref->[7],
                        $SEASONALITY_HISTORY_COLUMN_PRESSURE_HPA        => $test_point_ref->[8],
                        $SEASONALITY_HISTORY_COLUMN_RELATIVE_HUMIDITY   => $test_point_ref->[9],
                    ],
                    label   => "$SEASONALITY_HISTORY_TABLE should have a row in it for $test_point_ref->[0].",
                );
            } # end foreach

            # TEST*2
            db_status_table_ok( 2 * scalar( @{$test_data_ref} ) );
        }; # end eval

        $database_connection->disconnect();

        if ($@) {
            die $@;
        } # end if
    } # end anonymous block
} # end SKIP

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=0 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
