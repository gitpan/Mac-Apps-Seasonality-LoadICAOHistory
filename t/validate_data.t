use strict;
use warnings;

use Test::More;

# Figure out whether we can run.
eval 'use Test::Exception;';
if ($@) {
    plan skip_all => "because Test::Exception isn't installed.";

    return 0;
} # end if

# Do not modify the following line by hand.  Use Test::Count.
plan tests => 1858;


# Get all the stuff we need.
use Module::Build;
use File::Spec::Functions;


my $build;

BEGIN {
    $build = Module::Build->current();
} # end BEGIN

use lib catfile($build->base_dir(), 't', 'lib');

use Mac::Apps::Seasonality::Constants qw{ :all };
use Mac::Apps::Seasonality::LoadICAOHistory qw{ :validation };


my $line_number = 27;


# TEST:$validation_failure_tests=6
sub test_validation_fails {
    my (
        $attribute_name,
        $validation_sub_name,
        $validation_sub_ref,
        $main_test_description,
        $history_point_ref,
        $column_name,
        $column_number,
    )
        = @_;

    throws_ok(
        $validation_sub_ref,
        'Mac::Apps::Seasonality::InvalidDatumException',
        $main_test_description
    );

    my $exception =
        Mac::Apps::Seasonality::InvalidDatumException->caught();

    if ($exception) {
        cmp_ok(
            $exception->input_line_number,
            '==',
            $line_number,
            "exception should contain the line number passed into $validation_sub_name()"
        );

        ok(
            $exception->input_data_ref == $history_point_ref,
            "exception should contain identical input data array passed into $validation_sub_name()"
        );

        is(
            $exception->column_name,
            $column_name,
            "exception should contain the $attribute_name column name"
        );

        cmp_ok(
            $exception->column_number,
            '==',
            $column_number + 1,
            "exception should contain the one-based $attribute_name column number"
        );

        is(
            $exception->invalid_value,
            $history_point_ref->[$column_number],
            "exception should contain the invalid $attribute_name value"
        );
    } else {
        fail(
            "cannot check line number in exception because $validation_sub_name didn't properly throw an exception"
        );
        fail(
            "cannot check input data in exception because $validation_sub_name didn't properly throw an exception"
        );
        fail(
            "cannot check column name in exception because $validation_sub_name didn't properly throw an exception"
        );
        fail(
            "cannot check column number in exception because $validation_sub_name didn't properly throw an exception"
        );
        fail(
            "cannot check invalid value in exception because $validation_sub_name didn't properly throw an exception"
        );
    } # end if
} # end test_validation_fails()

# TEST:$base_integer_attribute_tests=5*$validation_failure_tests+1
sub test_integer_attribute {
    my $attribute_name      = shift;
    my $validation_sub_name = shift;
    my $column_name         = shift;
    my $minimum_value       = shift;
    my $maximum_value       = shift;

    my $validation_sub_ref  = \&{$validation_sub_name};
    my $history_point_ref   = [];
    my $column_number =
        $SEASONALITY_HISTORY_COLUMN_NUMBERS_BY_COLUMN_NAME_REF->{
            $column_name
        };

    # test * $validation_failure_tests
    test_validation_fails(
        $attribute_name,
        $validation_sub_name,
        sub { &$validation_sub_ref($history_point_ref, $line_number) },
        "$validation_sub_name() should not accept undef",
        $history_point_ref,
        $column_name,
        $column_number,
    );


    foreach my $value ($minimum_value..$maximum_value) {
        $history_point_ref->[$column_number] = $value;

        # test * $iterations  < Needs to be calculated by caller as
        #                       $maximum_value - $minimum_value + 1
        lives_ok(
            sub { &$validation_sub_ref($history_point_ref, $line_number) },
            "$value should be a valid $attribute_name"
        );
    } # end foreach


    $history_point_ref->[$column_number] = $minimum_value - 1;

    # test * $validation_failure_tests
    test_validation_fails(
        $attribute_name,
        $validation_sub_name,
        sub { &$validation_sub_ref($history_point_ref, $line_number) },
        "$validation_sub_name() should not accept anything less than the minimum",
        $history_point_ref,
        $column_name,
        $column_number,
    );


    $history_point_ref->[$column_number] = $maximum_value + 1;

    # test * $validation_failure_tests
    test_validation_fails(
        $attribute_name,
        $validation_sub_name,
        sub { &$validation_sub_ref($history_point_ref, $line_number) },
        "$validation_sub_name() should not accept anything greater than the maximum",
        $history_point_ref,
        $column_name,
        $column_number,
    );


    $history_point_ref->[$column_number] = $SEASONALITY_INVALID_DATA;

    # test
    lives_ok(
        sub { &$validation_sub_ref($history_point_ref, $line_number) },
        "$validation_sub_name() should accept the standard invalid data indicator",
    );


    $history_point_ref->[$column_number] = $minimum_value + 0.1;

    # test * $validation_failure_tests
    test_validation_fails(
        $attribute_name,
        $validation_sub_name,
        sub { &$validation_sub_ref($history_point_ref, $line_number) },
        "$validation_sub_name() should not accept floating point numbers",
        $history_point_ref,
        $column_name,
        $column_number,
    );


    $history_point_ref->[$column_number] = 'x';

    # test * $validation_failure_tests
    test_validation_fails(
        $attribute_name,
        $validation_sub_name,
        sub { &$validation_sub_ref($history_point_ref, $line_number) },
        "$validation_sub_name() should not accept non-numeric values",
        $history_point_ref,
        $column_name,
        $column_number,
    );
} # end test_integer_attribute()

# TEST:$floating_point_attribute_tests=4*$validation_failure_tests+3
sub test_floating_point_attribute {
    my $attribute_name      = shift;
    my $validation_sub_name = shift;
    my $column_name         = shift;
    my $minimum_value       = shift;
    my $maximum_value       = shift;

    my $validation_sub_ref  = \&{$validation_sub_name};
    my $history_point_ref   = [];
    my $column_number =
        $SEASONALITY_HISTORY_COLUMN_NUMBERS_BY_COLUMN_NAME_REF->{
            $column_name
        };

    # test * $validation_failure_tests
    test_validation_fails(
        $attribute_name,
        $validation_sub_name,
        sub { &$validation_sub_ref($history_point_ref, $line_number) },
        "$validation_sub_name() should not accept undef",
        $history_point_ref,
        $column_name,
        $column_number,
    );


    $history_point_ref->[$column_number] = $minimum_value - 1;

    # test * $validation_failure_tests
    test_validation_fails(
        $attribute_name,
        $validation_sub_name,
        sub { &$validation_sub_ref($history_point_ref, $line_number) },
        "$validation_sub_name() should not accept anything less than the minimum",
        $history_point_ref,
        $column_name,
        $column_number,
    );


    $history_point_ref->[$column_number] = $minimum_value;

    # test
    lives_ok(
        sub { &$validation_sub_ref($history_point_ref, $line_number) },
        "$validation_sub_name() should accept the minimum value",
    );


    $history_point_ref->[$column_number] = $maximum_value;

    # test
    lives_ok(
        sub { &$validation_sub_ref($history_point_ref, $line_number) },
        "$validation_sub_name() should accept the maximum value",
    );


    $history_point_ref->[$column_number] = $maximum_value + 1;

    # test * $validation_failure_tests
    test_validation_fails(
        $attribute_name,
        $validation_sub_name,
        sub { &$validation_sub_ref($history_point_ref, $line_number) },
        "$validation_sub_name() should not accept anything greater than the maximum",
        $history_point_ref,
        $column_name,
        $column_number,
    );


    $history_point_ref->[$column_number] = $SEASONALITY_INVALID_DATA;

    # test
    lives_ok(
        sub { &$validation_sub_ref($history_point_ref, $line_number) },
        "$validation_sub_name() should accept the standard invalid data indicator",
    );


    $history_point_ref->[$column_number] = 'x';

    # test * $validation_failure_tests
    test_validation_fails(
        $attribute_name,
        $validation_sub_name,
        sub { &$validation_sub_ref($history_point_ref, $line_number) },
        "$validation_sub_name() should not accept non-numeric values",
        $history_point_ref,
        $column_name,
        $column_number,
    );
} # end test_floating_point_attribute()


# ICAO validation.
{
    my $attribute_name          = 'ICAO';
    my $validation_sub_name     = 'validate_icao';
    my $history_point_ref       = [];
    my $column_number =
        $SEASONALITY_HISTORY_COLUMN_NUMBERS_BY_COLUMN_NAME_REF->{
            $SEASONALITY_HISTORY_COLUMN_ICAO
        };

    # TEST*$validation_failure_tests
    test_validation_fails(
        $attribute_name,
        $validation_sub_name,
        sub { validate_icao($history_point_ref, $line_number) },
        'validate_icao() should not accept undef',
        $history_point_ref,
        $SEASONALITY_HISTORY_COLUMN_ICAO,
        $column_number,
    );


    # GRRR... using constants is supposed to prevent repeated magic
    # numbers, but of course, Test::Count can't really access these.
    # Should probably get Build.PL to generate this file using
    # Constants.pm.
    #
    # TEST:$icao_iterations=32
    foreach my $icao_length (
        $SEASONALITY_ICAO_MINIMUM_LENGTH..$SEASONALITY_ICAO_MAXIMUM_LENGTH
    ) {
        $history_point_ref->[$column_number] = 'x' x $icao_length;

        # TEST*$icao_iterations
        lives_ok(
            sub { validate_icao($history_point_ref, $line_number) },
            "a string of $icao_length 'x's should be a valid ICAO"
        );
    } # end foreach


    $history_point_ref->[$column_number] =
            'x'
        x   ($SEASONALITY_ICAO_MINIMUM_LENGTH - 1);

    # TEST*$validation_failure_tests
    test_validation_fails(
        $attribute_name,
        $validation_sub_name,
        sub { validate_icao($history_point_ref, $line_number) },
        'validate_icao() should not accept anything shorter than the minimum',
        $history_point_ref,
        $SEASONALITY_HISTORY_COLUMN_ICAO,
        $column_number,
    );


    $history_point_ref->[$column_number] =
            'x'
        x   ($SEASONALITY_ICAO_MAXIMUM_LENGTH + 1);

    # TEST*$validation_failure_tests
    test_validation_fails(
        $attribute_name,
        $validation_sub_name,
        sub { validate_icao($history_point_ref, $line_number) },
        'validate_icao() should not accept anything longer than the maximum',
        $history_point_ref,
        $SEASONALITY_HISTORY_COLUMN_ICAO,
        $column_number,
    );


    $history_point_ref->[$column_number] = $SEASONALITY_INVALID_DATA;

    # TEST*$validation_failure_tests
    test_validation_fails(
        $attribute_name,
        $validation_sub_name,
        sub { validate_icao($history_point_ref, $line_number) },
        'validate_icao() should not accept the standard invalid data indicator',
        $history_point_ref,
        $SEASONALITY_HISTORY_COLUMN_ICAO,
        $column_number,
    );
} # end icao testing


# date validation.
{
    my $attribute_name          = 'date';
    my $validation_sub_name     = 'validate_date';
    my $history_point_ref       = [];
    my $column_number =
        $SEASONALITY_HISTORY_COLUMN_NUMBERS_BY_COLUMN_NAME_REF->{
            $SEASONALITY_HISTORY_COLUMN_DATE
        };

    # TEST*$validation_failure_tests
    test_validation_fails(
        $attribute_name,
        $validation_sub_name,
        sub { validate_date($history_point_ref, $line_number) },
        'validate_date() should not accept undef',
        $history_point_ref,
        $SEASONALITY_HISTORY_COLUMN_DATE,
        $column_number,
    );


    $history_point_ref->[$column_number] = '193705061825';
    # TEST
    lives_ok(
        sub { validate_date($history_point_ref, $line_number) },
        "the burning of the Hindenburg should be a valid date"
    );


    # The observant reader will note that only the correct number of digits
    # being checked, not that the value is a proper date.
    $history_point_ref->[$column_number] = '19370506182';

    # TEST*$validation_failure_tests
    test_validation_fails(
        $attribute_name,
        $validation_sub_name,
        sub { validate_date($history_point_ref, $line_number) },
        'validate_date() should not accept anything that is too short',
        $history_point_ref,
        $SEASONALITY_HISTORY_COLUMN_DATE,
        $column_number,
    );


    $history_point_ref->[$column_number] = '1937050618259';

    # TEST*$validation_failure_tests
    test_validation_fails(
        $attribute_name,
        $validation_sub_name,
        sub { validate_date($history_point_ref, $line_number) },
        'validate_date() should not accept anything that is too long',
        $history_point_ref,
        $SEASONALITY_HISTORY_COLUMN_DATE,
        $column_number,
    );


    $history_point_ref->[$column_number] = '19370506182x';

    # TEST*$validation_failure_tests
    test_validation_fails(
        $attribute_name,
        $validation_sub_name,
        sub { validate_date($history_point_ref, $line_number) },
        'validate_date() should not accept anything that is non-numeric',
        $history_point_ref,
        $SEASONALITY_HISTORY_COLUMN_DATE,
        $column_number,
    );


    $history_point_ref->[$column_number] = $SEASONALITY_INVALID_DATA;

    # TEST*$validation_failure_tests
    test_validation_fails(
        $attribute_name,
        $validation_sub_name,
        sub { validate_date($history_point_ref, $line_number) },
        'validate_date() should not accept the standard invalid data indicator',
        $history_point_ref,
        $SEASONALITY_HISTORY_COLUMN_DATE,
        $column_number,
    );
} # end date testing


# Wind direction validation.
{
    # TEST*$base_integer_attribute_tests
    # TEST*360
    # TEST*-(-1)
    # TEST*1
    test_integer_attribute(
        'wind direction',
        'validate_wind_direction',
        $SEASONALITY_HISTORY_COLUMN_WIND_DIRECTION,
        $SEASONALITY_WIND_DIRECTION_MINIMUM,
        $SEASONALITY_WIND_DIRECTION_MAXIMUM,
    );
} # end wind direction testing


# Wind speed in knots validation.
{
    # TEST*$base_integer_attribute_tests
    # TEST*300
    # TEST*-0
    # TEST*1
    test_integer_attribute(
        'wind speed in knots',
        'validate_wind_speed_knots',
        $SEASONALITY_HISTORY_COLUMN_WIND_SPEED_KNOTS,
        $SEASONALITY_WIND_SPEED_MINIMUM,
        $SEASONALITY_WIND_SPEED_MAXIMUM,
    );
} # end wind speed in knots testing


# Gust speed in knots validation.
{
    # TEST*$base_integer_attribute_tests
    # TEST*300
    # TEST*-0
    # TEST*1
    test_integer_attribute(
        'gust speed in knots',
        'validate_gust_speed_knots',
        $SEASONALITY_HISTORY_COLUMN_GUST_SPEED_KNOTS,
        $SEASONALITY_WIND_SPEED_MINIMUM,
        $SEASONALITY_WIND_SPEED_MAXIMUM,
    );
} # end gust speed in knots testing


# Visibility miles validation.
{
    # TEST*$floating_point_attribute_tests
    test_floating_point_attribute(
        'visibility miles',
        'validate_visibility_miles',
        $SEASONALITY_HISTORY_COLUMN_VISIBILITY_MILES,
        $SEASONALITY_VISIBILITY_MINIMUM,
        $SEASONALITY_VISIBILITY_MAXIMUM,
    );
} # end visibility miles testing


# Temperature validation.
{
    # TEST*$floating_point_attribute_tests
    test_floating_point_attribute(
        'temperature',
        'validate_temperature_c',
        $SEASONALITY_HISTORY_COLUMN_TEMPERATURE_C,
        $SEASONALITY_TEMPERATURE_MINIMUM,
        $SEASONALITY_TEMPERATURE_MAXIMUM,
    );
} # end temperature testing


# Dewpoint validation.
{
    # TEST*$floating_point_attribute_tests
    test_floating_point_attribute(
        'dewpoint',
        'validate_dewpoint_c',
        $SEASONALITY_HISTORY_COLUMN_DEWPOINT_C,
        $SEASONALITY_TEMPERATURE_MINIMUM,
        $SEASONALITY_TEMPERATURE_MAXIMUM,
    );
} # end dewpoint testing


# Pressure heptopascals validation.
{
    # TEST*$base_integer_attribute_tests
    # TEST*1200
    # TEST*-800
    # TEST*1
    test_integer_attribute(
        'pressure heptopascals',
        'validate_pressure_hpa',
        $SEASONALITY_HISTORY_COLUMN_PRESSURE_HPA,
        $SEASONALITY_PRESSURE_MINIMUM,
        $SEASONALITY_PRESSURE_MAXIMUM,
    );
} # end pressure heptopascals testing


# Relative humidity validation.
{
    # TEST*$base_integer_attribute_tests
    # TEST*100
    # TEST*-0
    # TEST*1
    test_integer_attribute(
        'relative humidity',
        'validate_relative_humidity',
        $SEASONALITY_HISTORY_COLUMN_RELATIVE_HUMIDITY,
        $SEASONALITY_RELATIVE_HUMIDITY_MINIMUM,
        $SEASONALITY_RELATIVE_HUMIDITY_MAXIMUM,
    );
} # end relative humidity testing

# Data point validation
{
    {
        # TEST
        throws_ok(
            sub { validate_icao_history_point(undef, $line_number) },
            'Mac::Apps::Seasonality::InvalidDataSizeException',
            'validate_icao_history_point() should not accept undef',
        );

        my $exception =
            Mac::Apps::Seasonality::InvalidDataSizeException->caught();

        if ($exception) {
            # TEST
            cmp_ok(
                $exception->input_line_number,
                '==',
                $line_number,
                'exception should contain the line number passed into validate_icao_history_point()'
            );

            # TEST
            ok(
                ! defined $exception->input_data_ref,
                'exception should not contain an input data array because none was passed into validate_icao_history_point()'
            );

            # TEST
            cmp_ok(
                $exception->expected_number_of_elements,
                '==',
                $SEASONALITY_HISTORY_COLUMNS_COUNT,
                'exception should contain the number of icao_history table columns'
            );

            # TEST
            cmp_ok(
                $exception->actual_number_of_elements,
                '==',
                0,
                'exception should contain 0 as the number of columns passed to validate_icao_history_point()'
            );
        } else {
            fail(
                "cannot check line number in exception because validate_icao_history_point() didn't properly throw an exception"
            );
            fail(
                "cannot check input data in exception because validate_icao_history_point() didn't properly throw an exception"
            );
            fail(
                "cannot check expected number of elements in exception because validate_icao_history_point() didn't properly throw an exception"
            );
            fail(
                "cannot check actual number of elements in exception because validate_icao_history_point() didn't properly throw an exception"
            );
        } # end if
    }

    # Grrr... gotta keep this in sync with $SEASONALITY_HISTORY_COLUMNS_COUNT.
    # TEST:$invalid_column_count_iterations=10+1
    foreach my $column_count (
        0..($SEASONALITY_HISTORY_COLUMNS_COUNT - 1),
        $SEASONALITY_HISTORY_COLUMNS_COUNT + 1,
    ) {
        my $history_point_ref   = [(undef) x $column_count];

        # TEST*$invalid_column_count_iterations
        throws_ok(
            sub { validate_icao_history_point($history_point_ref, $line_number) },
            'Mac::Apps::Seasonality::InvalidDataSizeException',
            'validate_icao_history_point() should not accept an invalid number of columns',
        );

        my $exception =
            Mac::Apps::Seasonality::InvalidDataSizeException->caught();

        if ($exception) {
            # TEST*$invalid_column_count_iterations
            cmp_ok(
                $exception->input_line_number,
                '==',
                $line_number,
                'exception should contain the line number passed into validate_icao_history_point()'
            );

            # TEST*$invalid_column_count_iterations
            ok(
                $exception->input_data_ref == $history_point_ref,
                'exception should contain identical input data array passed into validate_icao_history_point()'
            );

            # TEST*$invalid_column_count_iterations
            cmp_ok(
                $exception->expected_number_of_elements,
                '==',
                $SEASONALITY_HISTORY_COLUMNS_COUNT,
                'exception should contain the number of icao_history table columns'
            );

            # TEST*$invalid_column_count_iterations
            cmp_ok(
                $exception->actual_number_of_elements,
                '==',
                $column_count,
                'exception should contain the correct number of columns passed to validate_icao_history_point()'
            );
        } else {
            fail(
                "cannot check line number in exception because validate_icao_history_point() didn't properly throw an exception"
            );
            fail(
                "cannot check input data in exception because validate_icao_history_point() didn't properly throw an exception"
            );
            fail(
                "cannot check expected number of elements in exception because validate_icao_history_point() didn't properly throw an exception"
            );
            fail(
                "cannot check actual number of elements in exception because validate_icao_history_point() didn't properly throw an exception"
            );
        } # end if
    } # end foreach

    {
        my $history_point_ref   =
            [
                'FOOBIE_BLETCH',
                '193705061825',
                $SEASONALITY_WIND_DIRECTION_MAXIMUM,
                $SEASONALITY_WIND_SPEED_MAXIMUM,
                $SEASONALITY_WIND_SPEED_MAXIMUM,
                $SEASONALITY_VISIBILITY_MAXIMUM,
                $SEASONALITY_TEMPERATURE_MAXIMUM,
                $SEASONALITY_TEMPERATURE_MAXIMUM,
                $SEASONALITY_PRESSURE_MAXIMUM,
                $SEASONALITY_RELATIVE_HUMIDITY_MAXIMUM,
            ];

        # TEST
        lives_ok(
            sub { validate_icao_history_point($history_point_ref, $line_number) },
            'validate_icao_history_point() should accept a valid set of data',
        );
    }
} # end data point testing

# Data set validation
{
    {
        my $history_ref = [];

        # TEST
        lives_ok(
            sub { validate_icao_history_set($history_ref) },
            'validate_icao_history_set() should accept a zero data points',
        );
    }

    {
        my $history_ref =
            [
                [
                    'FOOBIE_BLETCH',
                    '193705061825',
                    $SEASONALITY_WIND_DIRECTION_MAXIMUM,
                    $SEASONALITY_WIND_SPEED_MAXIMUM,
                    $SEASONALITY_WIND_SPEED_MAXIMUM,
                    $SEASONALITY_VISIBILITY_MAXIMUM,
                    $SEASONALITY_TEMPERATURE_MAXIMUM,
                    $SEASONALITY_TEMPERATURE_MAXIMUM,
                    $SEASONALITY_PRESSURE_MAXIMUM,
                    $SEASONALITY_RELATIVE_HUMIDITY_MAXIMUM,
                ],
            ];

        # TEST
        lives_ok(
            sub { validate_icao_history_set($history_ref) },
            'validate_icao_history_point() should accept a valid set of one data point',
        );
    }

    {
        my $history_ref =
            [
                [
                    'EM_DAER',
                    '194603171200',
                    $SEASONALITY_WIND_DIRECTION_MINIMUM,
                    $SEASONALITY_WIND_SPEED_MINIMUM,
                    $SEASONALITY_WIND_SPEED_MINIMUM,
                    $SEASONALITY_VISIBILITY_MINIMUM,
                    $SEASONALITY_TEMPERATURE_MINIMUM,
                    $SEASONALITY_TEMPERATURE_MINIMUM,
                    $SEASONALITY_PRESSURE_MINIMUM,
                    $SEASONALITY_RELATIVE_HUMIDITY_MINIMUM,
                ],
                [
                    'FOOBIE_BLETCH',
                    '193705061825',
                    $SEASONALITY_WIND_DIRECTION_MAXIMUM,
                    $SEASONALITY_WIND_SPEED_MAXIMUM,
                    $SEASONALITY_WIND_SPEED_MAXIMUM,
                    $SEASONALITY_VISIBILITY_MAXIMUM,
                    $SEASONALITY_TEMPERATURE_MAXIMUM,
                    $SEASONALITY_TEMPERATURE_MAXIMUM,
                    $SEASONALITY_PRESSURE_MAXIMUM,
                    $SEASONALITY_RELATIVE_HUMIDITY_MAXIMUM,
                ],
            ];

        # TEST
        lives_ok(
            sub { validate_icao_history_set($history_ref) },
            'validate_icao_history_point() should accept a valid set of two data points',
        );
    }

    {
        my $history_ref =
            [
                [
                    'EM_DAER',
                    '194603171200',
                    $SEASONALITY_WIND_DIRECTION_MINIMUM,
                    $SEASONALITY_WIND_SPEED_MINIMUM,
                    $SEASONALITY_WIND_SPEED_MINIMUM,
                    $SEASONALITY_VISIBILITY_MINIMUM,
                    $SEASONALITY_TEMPERATURE_MINIMUM,
                    $SEASONALITY_TEMPERATURE_MINIMUM,
                    $SEASONALITY_PRESSURE_MINIMUM,
                    $SEASONALITY_RELATIVE_HUMIDITY_MINIMUM,
                ],
                [
                    'FOOBIE_BLETCH',
                    '193705061825',
                    $SEASONALITY_WIND_DIRECTION_MAXIMUM,
                    $SEASONALITY_WIND_SPEED_MAXIMUM,
                    $SEASONALITY_WIND_SPEED_MAXIMUM,
                    $SEASONALITY_VISIBILITY_MAXIMUM,
                    $SEASONALITY_TEMPERATURE_MAXIMUM,
                    $SEASONALITY_TEMPERATURE_MAXIMUM,
                    $SEASONALITY_PRESSURE_MAXIMUM,
                    $SEASONALITY_RELATIVE_HUMIDITY_MAXIMUM,
                ],
                [],
            ];

        # TEST
        throws_ok(
            sub { validate_icao_history_set($history_ref, $line_number) },
            'Mac::Apps::Seasonality::InvalidDataSizeException',
            'validate_icao_history_set() should not have accepted an empty third data point',
        );

        my $exception =
            Mac::Apps::Seasonality::InvalidDataSizeException->caught();

        if ($exception) {
            # TEST
            cmp_ok(
                $exception->input_line_number,
                '==',
                3,
                'exception should contain the one-based line number containing the invalid data passed into validate_icao_history_set()'
            );

            # TEST
            ok(
                $exception->input_data_ref == $history_ref->[2],
                'exception should contain invalid data point passed into validate_icao_history_set()'
            );

            # TEST
            cmp_ok(
                $exception->expected_number_of_elements,
                '==',
                $SEASONALITY_HISTORY_COLUMNS_COUNT,
                'exception should contain the number of icao_history table columns'
            );

            # TEST
            cmp_ok(
                $exception->actual_number_of_elements,
                '==',
                0,
                'exception should contain 0 as the number of columns in the invalid data point passed to validate_icao_history_set()'
            );
        } else {
            fail(
                "cannot check line number in exception because validate_icao_history_set() didn't properly throw an exception"
            );
            fail(
                "cannot check input data in exception because validate_icao_history_set() didn't properly throw an exception"
            );
            fail(
                "cannot check expected number of elements in exception because validate_icao_history_set() didn't properly throw an exception"
            );
            fail(
                "cannot check actual number of elements in exception because validate_icao_history_set() didn't properly throw an exception"
            );
        } # end if
    }
} # end data set testing

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=0 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
