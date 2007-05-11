package Mac::Apps::Seasonality::TestUtilities;

use strict;
use warnings;

use version; our $VERSION = qv('v0.0.6');

use English qw{ -no_match_vars };
use Fatal qw{ :void close };
use Readonly;
use File::Temp qw{ tempfile };
use DBI;

use Exporter qw( import );

use Mac::Apps::Seasonality::Constants qw{ :all };

our @EXPORT         = qw{ };
our @EXPORT_OK      = qw{
    $EMPTY_STRING $SPACE

    &create_test_database
    &build_test_data
    &db_status_table_ok
    &test_point_ok
};
our %EXPORT_TAGS    = ( all => [ @EXPORT, @EXPORT_OK ] );

Readonly our $EMPTY_STRING  => q{};
Readonly our $SPACE         => q{ };

sub create_test_database {
    my ( $filehandle, $filename ) =
        tempfile(
            'test_seasonality_weather.db_XXXXXXXX',
            UNLINK  => 1,
            DIR     => '/tmp',
            SUFFIX  => '.db'
        );
    close $filehandle;  # Have to close it to allow DBI to open the file.

    my $db_connection;
    $db_connection =
        DBI->connect(
            "dbi:SQLite2:$filename",
            $EMPTY_STRING,
            $EMPTY_STRING,
            {
                AutoCommit => 0,
                RaiseError => 1,
            }
        );

    $db_connection->do(<<'END_DDL');
        CREATE TABLE db_status (
            new_records_since_vacuum int
        );
END_DDL

    $db_connection->do(<<'END_DDL');
        CREATE TABLE icao_history (
            icao                varchar(32),
            date                date,
            wind_direction      int,
            wind_speed_knots    int,
            gust_speed_knots    int,
            visibility_miles    float,
            temperature_c       float,
            dewpoint_c          float,
            pressure_hpa        int,
            relative_humidity   int
        );
END_DDL

    $db_connection->do(<<'END_DDL');
        create index history_index on icao_history(icao, date);
END_DDL

    $db_connection->do(
        'INSERT INTO db_status (new_records_since_vacuum) VALUES (0)'
    );

    return $db_connection;
} # end create_test_database()

sub build_test_data {
    return
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
} # end build_test_data()

BEGIN {
    eval 'use Test::DatabaseRow;';

    if (not $EVAL_ERROR) {
        eval {
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

            sub test_point_ok {
                my $test_point_ref = shift;

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
            } # end test_point_ok()
        }; # end eval
    } # end if
} # end BEGIN

1;  # Magic true value required at end of module

__END__

=encoding utf8

=head1 NAME

Mac::Apps::Seasonality::TestUtilities - Various helper subroutines for testing
loading data into Seasonality's weather.db.


=head1 VERSION

This document describes Mac::Apps::Seasonality::TestUtilities version 0.0.6.


=head1 SYNOPSIS

    use Mac::Apps::Seasonality::TestUtilities;

    $db_connection = create_test_database();

    $test_data = build_test_data();

    # do some data manipulation...

    db_status_table_ok( $number_of_rows_inserted_updated_and_deleted );

    test_point_ok( $test_data->[0] );


=head1 INTERFACE

=over

=item C<$EMPTY_STRING>

Empty string constant.


=item C<$SPACE>

Single space constant.


=item C<create_test_database()>

Creates a temporary database with the Seasonality weather.db schema.  This
database will automatically be deleted upon program termination.


=item C<build_test_data()>

Assemble a set of data that can be passed to
L<Mac::Apps::Seasonality::LoadICAOHistory/"load_icao_history">.


=item C<db_status_table_ok( $insert_count )>

Checks whether the Seasonality vacuum scheduling table looks OK, i.e. there is
one and only one row in it and the count in it is twice the number of inserts
that have been done.


=item C<test_point_ok( $test_point_ref )>

Checks that there is a row in the database that matches the parameter.


=back


=head1 AUTHOR

Elliot Shank  C<<perl@galumph.com>>


=head1 LICENCE AND COPYRIGHT

Copyright ©2006-2007, Elliot Shank C<< <perl@galumph.com> >>. All rights
reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
