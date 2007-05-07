use strict;
use warnings;

use Test::More;

# Do not modify the following line by hand.  Use Test::Count.
plan tests => 4770;


use Mac::Apps::Seasonality::Constants qw{ :all };
use Mac::Apps::Seasonality::LoadICAOHistory qw{ :cleaning };


my $line_number = 27;


# TEST:$cleaning_missing_or_invalid_value_tests=6
sub test_cleaning_missing_or_invalid_value {
    my (
        $cleaning_sub_name,
        $cleaning_sub_ref,
        $history_point_ref,
        $column_name,
        $column_number,
        $value,
        $value_string,
    )
        = @_;

    is(
        $history_point_ref->[$column_number],
        $value,
        "point should have contained $value_string as the value for $column_name before invoking $cleaning_sub_name()"
    );

    my @messages = $cleaning_sub_ref->();

    is(
        scalar @messages,
        1,
        "$cleaning_sub_name() should have returned a single message when cleaning a value of $value_string"
    );

    if (1 == scalar @messages) {
        my $message = $messages[0];

        like(
            $message,
            qr/$column_name/,
            "message returned by $cleaning_sub_name($value_string) should have contained the column name."
        );

        like(
            $message,
            qr/line $line_number/,
            "message returned by $cleaning_sub_name($value_string) should have contained the line number."
        );

        my $display_column_number = $column_number + 1;
        like(
            $message,
            qr/column number $display_column_number/,
            "message returned by $cleaning_sub_name($value_string) should have contained the column number."
        );
    } else {
        fail("can't check for column name because $cleaning_sub_name() didn't return one and only one message.");
        fail("can't check for line number because $cleaning_sub_name() didn't return one and only one message.");
        fail("can't check for column number because $cleaning_sub_name() didn't return one and only one message.");
    } # end if

    is(
        $history_point_ref->[$column_number],
        $SEASONALITY_INVALID_DATA,
        "point should have contained \$SEASONALITY_INVALID_DATA as the value for $column_name after invoking $cleaning_sub_name()"
    );
} # end test_cleaning_missing_or_invalid_value()

# TEST:$cleaning_valid_value_tests=3
sub test_cleaning_valid_value {
    my (
        $cleaning_sub_name,
        $cleaning_sub_ref,
        $history_point_ref,
        $column_name,
        $column_number,
        $value,
        $value_string,
    )
        = @_;

    is(
        $history_point_ref->[$column_number],
        $value,
        "point should have contained $value_string as the value for $column_name before invoking $cleaning_sub_name()"
    );

    my @messages = $cleaning_sub_ref->();

    is(
        scalar @messages,
        0,
        "$cleaning_sub_name() should not have returned any messages when cleaning a value of $value_string"
    );

    is(
        $history_point_ref->[$column_number],
        $value,
        "point should have contained $value_string as the value for $column_name after invoking $cleaning_sub_name()"
    );
} # end test_cleaning_valid_value()

# TEST:$rounding_integer_tests=6
sub test_rounding_integer {
    my (
        $cleaning_sub_name,
        $cleaning_sub_ref,
        $history_point_ref,
        $column_name,
        $column_number,
        $base_value,
        $rounded_value,
    )
        = @_;

    is(
        $history_point_ref->[$column_number],
        $base_value,
        "point should have contained $base_value as the value for $column_name before invoking $cleaning_sub_name()"
    );

    my @messages = $cleaning_sub_ref->();

    is(
        scalar @messages,
        1,
        "$cleaning_sub_name() should have returned a single message when cleaning a value of $base_value"
    );

    if (1 == scalar @messages) {
        my $message = $messages[0];

        like(
            $message,
            qr/$column_name/,
            "message returned by $cleaning_sub_name($base_value) should have contained the column name."
        );

        like(
            $message,
            qr/line $line_number/,
            "message returned by $cleaning_sub_name($base_value) should have contained the line number."
        );

        my $display_column_number = $column_number + 1;
        like(
            $message,
            qr/column number $display_column_number/,
            "message returned by $cleaning_sub_name($base_value) should have contained the column number."
        );
    } else {
        fail("can't check for column name because $cleaning_sub_name() didn't return one and only one message.");
        fail("can't check for line number because $cleaning_sub_name() didn't return one and only one message.");
        fail("can't check for column number because $cleaning_sub_name() didn't return one and only one message.");
    } # end if


    is(
        $history_point_ref->[$column_number],
        $rounded_value,
        "point should have contained $rounded_value as the rounded value for $base_value for $column_name after invoking $cleaning_sub_name()"
    );
} # end test_rounding_integer()


# TEST:$base_integer_attribute_tests=5*$cleaning_missing_or_invalid_value_tests+$cleaning_valid_value_tests+3*$rounding_integer_tests
sub test_integer_attribute {
    my $cleaning_sub_name = shift;
    my $column_name       = shift;
    my $minimum_value     = shift;
    my $maximum_value     = shift;

    my $cleaning_sub_ref  = \&{$cleaning_sub_name};
    my $history_point_ref   = [];
    my $column_number =
        $SEASONALITY_HISTORY_COLUMN_NUMBERS_BY_COLUMN_NAME_REF->{
            $column_name
        };

    my %invalid_values = (
        'q{}' => q{},
        'undef' => undef,
        ($minimum_value - 1) => ($minimum_value - 1),
        ($maximum_value + 1) => ($maximum_value + 1),
        xxx => 'xxx'
    );
    # test * invalid_values * $cleaning_missing_or_invalid_value_tests
    while (my ($value_string, $value) = each %invalid_values) {
        $history_point_ref->[$column_number] = $value;
        test_cleaning_missing_or_invalid_value(
            $cleaning_sub_name,
            sub { &$cleaning_sub_ref($history_point_ref, $line_number) },
            $history_point_ref,
            $column_name,
            $column_number,
            $value,
            $value_string,
        );
    } # end while


    # test * $cleaning_valid_value_tests
    $history_point_ref->[$column_number] = $SEASONALITY_INVALID_DATA;
    test_cleaning_valid_value(
        $cleaning_sub_name,
        sub { &$cleaning_sub_ref($history_point_ref, $line_number) },
        $history_point_ref,
        $column_name,
        $column_number,
        $SEASONALITY_INVALID_DATA,
        '$SEASONALITY_INVALID_DATA',
    );

    foreach my $value ($minimum_value..$maximum_value) {
        $history_point_ref->[$column_number] = $value;

        # test * $cleaning_valid_value_tests * $iterations  < Needs to be calculated by caller as
        #                                                     $maximum_value - $minimum_value + 1
        test_cleaning_valid_value(
            $cleaning_sub_name,
            sub { &$cleaning_sub_ref($history_point_ref, $line_number) },
            $history_point_ref,
            $column_name,
            $column_number,
            $value,
            $value,
        );
    } # end foreach


    my %rounding_values = (
        $maximum_value - 0.2 => $maximum_value,
        $maximum_value - 0.5 => $maximum_value,
        $maximum_value - 0.7 => $maximum_value - 1,
    );
    # test * invalid_values * $rounding_integer_tests
    while (my ($base_value, $rounded_value) = each %rounding_values) {
        $history_point_ref->[$column_number] = $base_value;
        test_rounding_integer(
            $cleaning_sub_name,
            sub { &$cleaning_sub_ref($history_point_ref, $line_number) },
            $history_point_ref,
            $column_name,
            $column_number,
            $base_value,
            $rounded_value,
        );
    } # end while
} # end test_integer_attribute()

# TEST:$floating_point_attribute_tests=5*$cleaning_missing_or_invalid_value_tests+$cleaning_valid_value_tests*3
sub test_floating_point_attribute {
    my $cleaning_sub_name = shift;
    my $column_name       = shift;
    my $minimum_value     = shift;
    my $maximum_value     = shift;

    my $cleaning_sub_ref  = \&{$cleaning_sub_name};
    my $history_point_ref   = [];
    my $column_number =
        $SEASONALITY_HISTORY_COLUMN_NUMBERS_BY_COLUMN_NAME_REF->{
            $column_name
        };

    my %invalid_values = (
        'q{}' => q{},
        'undef' => undef,
        ($minimum_value - 1) => ($minimum_value - 1),
        ($maximum_value + 1) => ($maximum_value + 1),
        xxx => 'xxx'
    );
    # test * invalid_values * $cleaning_missing_or_invalid_value_tests
    while (my ($value_string, $value) = each %invalid_values) {
        $history_point_ref->[$column_number] = $value;
        test_cleaning_missing_or_invalid_value(
            $cleaning_sub_name,
            sub { &$cleaning_sub_ref($history_point_ref, $line_number) },
            $history_point_ref,
            $column_name,
            $column_number,
            $value,
            $value_string,
        );
    } # end while


    # test * $cleaning_valid_value_tests
    $history_point_ref->[$column_number] = $SEASONALITY_INVALID_DATA;
    test_cleaning_valid_value(
        $cleaning_sub_name,
        sub { &$cleaning_sub_ref($history_point_ref, $line_number) },
        $history_point_ref,
        $column_name,
        $column_number,
        $SEASONALITY_INVALID_DATA,
        '$SEASONALITY_INVALID_DATA',
    );

    foreach my $value ($minimum_value, $maximum_value) {
        $history_point_ref->[$column_number] = $value;

        # test * $cleaning_valid_value_tests * 2
        test_cleaning_valid_value(
            $cleaning_sub_name,
            sub { &$cleaning_sub_ref($history_point_ref, $line_number) },
            $history_point_ref,
            $column_name,
            $column_number,
            $value,
            $value,
        );
    } # end foreach
} # end test_floating_point_attribute()


# Wind direction cleaning.
{
    # TEST*$base_integer_attribute_tests
    # TEST*360*$cleaning_valid_value_tests
    # TEST*1*$cleaning_valid_value_tests
    test_integer_attribute(
        'clean_wind_direction',
        $SEASONALITY_HISTORY_COLUMN_WIND_DIRECTION,
        $SEASONALITY_WIND_DIRECTION_MINIMUM,
        $SEASONALITY_WIND_DIRECTION_MAXIMUM,
    );
} # end wind direction testing


# Wind speed in knots cleaning.
{
    # TEST*$base_integer_attribute_tests
    # TEST*300*$cleaning_valid_value_tests
    # TEST*1*$cleaning_valid_value_tests
    test_integer_attribute(
        'clean_wind_speed_knots',
        $SEASONALITY_HISTORY_COLUMN_WIND_SPEED_KNOTS,
        $SEASONALITY_WIND_SPEED_MINIMUM,
        $SEASONALITY_WIND_SPEED_MAXIMUM,
    );
} # end wind speed in knots testing


# Gust speed in knots cleaning.
{
    # TEST*$base_integer_attribute_tests
    # TEST*300*$cleaning_valid_value_tests
    # TEST*1*$cleaning_valid_value_tests
    test_integer_attribute(
        'clean_gust_speed_knots',
        $SEASONALITY_HISTORY_COLUMN_GUST_SPEED_KNOTS,
        $SEASONALITY_WIND_SPEED_MINIMUM,
        $SEASONALITY_WIND_SPEED_MAXIMUM,
    );
} # end gust speed in knots testing


# Visibility miles cleaning.
{
    # TEST*$floating_point_attribute_tests
    test_floating_point_attribute(
        'clean_visibility_miles',
        $SEASONALITY_HISTORY_COLUMN_VISIBILITY_MILES,
        $SEASONALITY_VISIBILITY_MINIMUM,
        $SEASONALITY_VISIBILITY_MAXIMUM,
    );
} # end visibility miles testing


# Temperature cleaning.
{
    # TEST*$floating_point_attribute_tests
    test_floating_point_attribute(
        'clean_temperature_c',
        $SEASONALITY_HISTORY_COLUMN_TEMPERATURE_C,
        $SEASONALITY_TEMPERATURE_MINIMUM,
        $SEASONALITY_TEMPERATURE_MAXIMUM,
    );
} # end temperature testing


# Dewpoint cleaning.
{
    # TEST*$floating_point_attribute_tests
    test_floating_point_attribute(
        'clean_dewpoint_c',
        $SEASONALITY_HISTORY_COLUMN_DEWPOINT_C,
        $SEASONALITY_TEMPERATURE_MINIMUM,
        $SEASONALITY_TEMPERATURE_MAXIMUM,
    );
} # end dewpoint testing


# Pressure heptopascals cleaning.
{
    # TEST*$base_integer_attribute_tests
    # TEST*1200*$cleaning_valid_value_tests
    # TEST*-800*$cleaning_valid_value_tests
    # TEST*1*$cleaning_valid_value_tests
    test_integer_attribute(
        'clean_pressure_hpa',
        $SEASONALITY_HISTORY_COLUMN_PRESSURE_HPA,
        $SEASONALITY_PRESSURE_MINIMUM,
        $SEASONALITY_PRESSURE_MAXIMUM,
    );
} # end pressure heptopascals testing


# Relative humidity cleaning.
{
    # TEST*$base_integer_attribute_tests
    # TEST*101*$cleaning_valid_value_tests
    # TEST*1*$cleaning_valid_value_tests
    test_integer_attribute(
        'clean_relative_humidity',
        $SEASONALITY_HISTORY_COLUMN_RELATIVE_HUMIDITY,
        $SEASONALITY_RELATIVE_HUMIDITY_MINIMUM,
        $SEASONALITY_RELATIVE_HUMIDITY_MAXIMUM,
    );
} # end relative humidity testing

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
