package Mac::Apps::Seasonality::LoadICAOHistory;

use utf8;
use 5.008006;
use strict;
use warnings;
use Carp;

use version; our $VERSION = qv('v0.0.5');

use Exporter qw( import );

our @EXPORT_OK =
    qw{
        &convert_from_fahrenheit_to_celsius
        &convert_from_inches_of_mercury_to_hectopascals
        &convert_from_miles_per_hour_to_knots

        &clean_icao_history_set
        &clean_icao_history_point
        &clean_wind_direction
        &clean_wind_speed_knots
        &clean_gust_speed_knots
        &clean_visibility_miles
        &clean_temperature_c
        &clean_dewpoint_c
        &clean_pressure_hpa
        &clean_relative_humidity

        &load_icao_history

        &validate_icao_history_set
        &validate_icao_history_point
        &validate_icao
        &validate_date
        &validate_wind_direction
        &validate_wind_speed_knots
        &validate_gust_speed_knots
        &validate_visibility_miles
        &validate_temperature_c
        &validate_dewpoint_c
        &validate_pressure_hpa
        &validate_relative_humidity
    };
our %EXPORT_TAGS    = (
    all => [@EXPORT_OK],
    conversion => [
        qw{
            &convert_from_fahrenheit_to_celsius
            &convert_from_inches_of_mercury_to_hectopascals
            &convert_from_miles_per_hour_to_knots
        }
    ],
    cleaning => [
        qw{
            &clean_icao_history_set
            &clean_icao_history_point
            &clean_wind_direction
            &clean_wind_speed_knots
            &clean_gust_speed_knots
            &clean_visibility_miles
            &clean_temperature_c
            &clean_dewpoint_c
            &clean_pressure_hpa
            &clean_relative_humidity
        }
    ],
    validation => [
        qw{
            &validate_icao_history_set
            &validate_icao_history_point
            &validate_icao
            &validate_date
            &validate_wind_direction
            &validate_wind_speed_knots
            &validate_gust_speed_knots
            &validate_visibility_miles
            &validate_temperature_c
            &validate_dewpoint_c
            &validate_pressure_hpa
            &validate_relative_humidity
        }
    ],
);

use DBI qw{ :sql_types };
use Regexp::Common;

use Mac::Apps::Seasonality::Constants qw{ :database :data };
use Mac::Apps::Seasonality::LoadICAOHistoryExceptions;


sub convert_from_fahrenheit_to_celsius {
    my ($fahrenheit) = @_;

    return $fahrenheit if not defined $fahrenheit;
    return $fahrenheit if q{} eq $fahrenheit;
    return $fahrenheit if $SEASONALITY_INVALID_DATA == $fahrenheit;

    return ($fahrenheit - 32.0) * 5.0 / 9.0;
} # end convert_from_fahrenheit_to_celsius()

sub convert_from_inches_of_mercury_to_hectopascals {
    my ($inches) = @_;

    return $inches if not defined $inches;
    return $inches if q{} eq $inches;
    return $inches if $SEASONALITY_INVALID_DATA == $inches;

    return $inches * 33.863886667;
} # end convert_from_inches_of_mercury_to_hectopascals()

sub convert_from_miles_per_hour_to_knots {
    my ($mph) = @_;

    return $mph if not defined $mph;
    return $mph if q{} eq $mph;
    return $mph if $SEASONALITY_INVALID_DATA == $mph;

    return $mph * 0.868976242;
} # end convert_from_miles_per_hour_to_knots()

sub clean_icao_history_set {
    my $icao_history_ref = shift;
    my $line_number = 1;
    my @clean_messages;

    foreach my $icao_history_point_ref (@{$icao_history_ref}) {
        push
            @clean_messages,
            clean_icao_history_point($icao_history_point_ref, $line_number);

        $line_number++;
    } # end foreach

    return @clean_messages;
} # end clean_icao_history_set()

sub clean_icao_history_point {
    my ($icao_history_point_ref, $line_number) = @_;
    my @clean_messages;

    _check_basic_history_point_validity(
        $icao_history_point_ref,
        $line_number,
        'clean_icao_history_point()'
    );

    push @clean_messages, clean_wind_direction(    $icao_history_point_ref, $line_number);
    push @clean_messages, clean_wind_speed_knots(  $icao_history_point_ref, $line_number);
    push @clean_messages, clean_gust_speed_knots(  $icao_history_point_ref, $line_number);
    push @clean_messages, clean_visibility_miles(  $icao_history_point_ref, $line_number);
    push @clean_messages, clean_temperature_c(     $icao_history_point_ref, $line_number);
    push @clean_messages, clean_dewpoint_c(        $icao_history_point_ref, $line_number);
    push @clean_messages, clean_pressure_hpa(      $icao_history_point_ref, $line_number);
    push @clean_messages, clean_relative_humidity( $icao_history_point_ref, $line_number);

    return @clean_messages;
} # end clean_icao_history_point()

sub clean_wind_direction {
    my ($icao_history_point_ref, $line_number) = @_;

    return
        _clean_integer(
            $icao_history_point_ref,
            $line_number,
            $SEASONALITY_HISTORY_COLUMN_WIND_DIRECTION,
            $SEASONALITY_WIND_DIRECTION_MINIMUM,
            $SEASONALITY_WIND_DIRECTION_MAXIMUM,
        );
} # end clean_wind_direction()

sub clean_wind_speed_knots {
    my ($icao_history_point_ref, $line_number) = @_;

    return
        _clean_integer(
            $icao_history_point_ref,
            $line_number,
            $SEASONALITY_HISTORY_COLUMN_WIND_SPEED_KNOTS,
            $SEASONALITY_WIND_SPEED_MINIMUM,
            $SEASONALITY_WIND_SPEED_MAXIMUM,
        );
} # end clean_wind_speed_knots()

sub clean_gust_speed_knots {
    my ($icao_history_point_ref, $line_number) = @_;

    return
        _clean_integer(
            $icao_history_point_ref,
            $line_number,
            $SEASONALITY_HISTORY_COLUMN_GUST_SPEED_KNOTS,
            $SEASONALITY_WIND_SPEED_MINIMUM,
            $SEASONALITY_WIND_SPEED_MAXIMUM,
        );
} # end clean_gust_speed_knots()

sub clean_visibility_miles {
    my ($icao_history_point_ref, $line_number) = @_;

    return
        _clean_floating_point(
            $icao_history_point_ref,
            $line_number,
            $SEASONALITY_HISTORY_COLUMN_VISIBILITY_MILES,
            $SEASONALITY_VISIBILITY_MINIMUM,
            $SEASONALITY_VISIBILITY_MAXIMUM,
        );
} # end clean_visibility_miles()

sub clean_temperature_c {
    my ($icao_history_point_ref, $line_number) = @_;

    return
        _clean_floating_point(
            $icao_history_point_ref,
            $line_number,
            $SEASONALITY_HISTORY_COLUMN_TEMPERATURE_C,
            $SEASONALITY_TEMPERATURE_MINIMUM,
            $SEASONALITY_TEMPERATURE_MAXIMUM,
        );
} # end clean_temperature_c()

sub clean_dewpoint_c {
    my ($icao_history_point_ref, $line_number) = @_;

    return
        _clean_floating_point(
            $icao_history_point_ref,
            $line_number,
            $SEASONALITY_HISTORY_COLUMN_DEWPOINT_C,
            $SEASONALITY_TEMPERATURE_MINIMUM,
            $SEASONALITY_TEMPERATURE_MAXIMUM,
        );
} # end clean_dewpoint_c()

sub clean_pressure_hpa {
    my ($icao_history_point_ref, $line_number) = @_;

    return
        _clean_integer(
            $icao_history_point_ref,
            $line_number,
            $SEASONALITY_HISTORY_COLUMN_PRESSURE_HPA,
            $SEASONALITY_PRESSURE_MINIMUM,
            $SEASONALITY_PRESSURE_MAXIMUM,
        );
} # end clean_pressure_hpa()

sub clean_relative_humidity {
    my ($icao_history_point_ref, $line_number) = @_;

    return
        _clean_integer(
            $icao_history_point_ref,
            $line_number,
            $SEASONALITY_HISTORY_COLUMN_RELATIVE_HUMIDITY,
            $SEASONALITY_RELATIVE_HUMIDITY_MINIMUM,
            $SEASONALITY_RELATIVE_HUMIDITY_MAXIMUM,
        );
} # end clean_relative_humidity()

sub load_icao_history {
    my ($database_connection, $icao_history_ref) = @_;

    validate_icao_history_set($icao_history_ref);

    my $delete_statement = _prepare_icao_history_delete_statement($database_connection);
    my $insert_statement = _prepare_icao_history_insert_statement($database_connection);
    my $db_status_statement = _prepare_db_status_update_statement($database_connection);

    foreach my $icao_history_point_ref (@{$icao_history_ref}) {
        _load_icao_history_row(
            $delete_statement,
            $insert_statement,
            $db_status_statement,
            $icao_history_point_ref,
        );
    } # end foreach

    $database_connection->commit();

    return;
} # end load_icao_history()

sub validate_icao_history_set {
    my $icao_history_ref = shift;
    my $line_number = 1;

    foreach my $icao_history_point_ref (@{$icao_history_ref}) {
        validate_icao_history_point($icao_history_point_ref, $line_number);

        $line_number++;
    } # end foreach

    return;
} # end validate_icao_history_set()

sub validate_icao_history_point {
    my ($icao_history_point_ref, $line_number) = @_;

    _check_basic_history_point_validity(
        $icao_history_point_ref,
        $line_number,
        'clean_icao_history_point()'
    );

    validate_icao(              $icao_history_point_ref, $line_number);
    validate_date(              $icao_history_point_ref, $line_number);
    validate_wind_direction(    $icao_history_point_ref, $line_number);
    validate_wind_speed_knots(  $icao_history_point_ref, $line_number);
    validate_gust_speed_knots(  $icao_history_point_ref, $line_number);
    validate_visibility_miles(  $icao_history_point_ref, $line_number);
    validate_temperature_c(     $icao_history_point_ref, $line_number);
    validate_dewpoint_c(        $icao_history_point_ref, $line_number);
    validate_pressure_hpa(      $icao_history_point_ref, $line_number);
    validate_relative_humidity( $icao_history_point_ref, $line_number);

    return;
} # end validate_icao_history_point()

sub validate_icao {
    my ($icao_history_point_ref, $line_number) = @_;

    my ($icao, $column_number) =
        _get_value_and_column_number_and_validate_defined(
            $icao_history_point_ref,
            $line_number,
            $SEASONALITY_HISTORY_COLUMN_ICAO
        );

    if (
            $icao
        !~  m{
                \A
                \w {$SEASONALITY_ICAO_MINIMUM_LENGTH,$SEASONALITY_ICAO_MAXIMUM_LENGTH}
                \z
            }xmso
    ) {
        Mac::Apps::Seasonality::InvalidDatumException->throw(
            message =>
                "Value for $SEASONALITY_HISTORY_COLUMN_ICAO ('$icao') on line"
                    . " $line_number, column number $column_number, does not"
                    . " consist of $SEASONALITY_ICAO_MINIMUM_LENGTH to"
                    . " $SEASONALITY_ICAO_MAXIMUM_LENGTH alphanumeric"
                    . ' characters.',
            input_line_number => $line_number,
            input_data_ref => $icao_history_point_ref,
            column_name => $SEASONALITY_HISTORY_COLUMN_ICAO,
            column_number => $column_number,
            invalid_value => $icao,
        );
    } # end if

    return;
} # end validate_icao()

sub validate_date {
    my ($icao_history_point_ref, $line_number) = @_;

    my ($date, $column_number) =
        _get_value_and_column_number_and_validate_defined(
            $icao_history_point_ref,
            $line_number,
            $SEASONALITY_HISTORY_COLUMN_DATE
        );

    if ($date !~ m{ \A \d{12} \z }xms) {
        Mac::Apps::Seasonality::InvalidDatumException->throw(
            message =>
                "Value given for $SEASONALITY_HISTORY_COLUMN_DATE ('$date') on"
                    . " line $line_number, column number, $column_number, is"
                    . ' not 12 digits.',
            input_line_number => $line_number,
            input_data_ref => $icao_history_point_ref,
            column_name => $SEASONALITY_HISTORY_COLUMN_DATE,
            column_number => $column_number,
            invalid_value => $date,
        );
    } # end if

    return;
} # end validate_date()

sub validate_wind_direction {
    my ($icao_history_point_ref, $line_number) = @_;

    _validate_integer(
        $icao_history_point_ref,
        $line_number,
        $SEASONALITY_HISTORY_COLUMN_WIND_DIRECTION,
        $SEASONALITY_WIND_DIRECTION_MINIMUM,
        $SEASONALITY_WIND_DIRECTION_MAXIMUM,
    );

    return;
} # end validate_wind_direction()

sub validate_wind_speed_knots {
    my ($icao_history_point_ref, $line_number) = @_;

    _validate_integer(
        $icao_history_point_ref,
        $line_number,
        $SEASONALITY_HISTORY_COLUMN_WIND_SPEED_KNOTS,
        $SEASONALITY_WIND_SPEED_MINIMUM,
        $SEASONALITY_WIND_SPEED_MAXIMUM,
    );

    return;
} # end validate_wind_speed_knots()

sub validate_gust_speed_knots {
    my ($icao_history_point_ref, $line_number) = @_;

    _validate_integer(
        $icao_history_point_ref,
        $line_number,
        $SEASONALITY_HISTORY_COLUMN_GUST_SPEED_KNOTS,
        $SEASONALITY_WIND_SPEED_MINIMUM,
        $SEASONALITY_WIND_SPEED_MAXIMUM,
    );

    return;
} # end validate_gust_speed_knots()

sub validate_visibility_miles {
    my ($icao_history_point_ref, $line_number) = @_;

    _validate_floating_point(
        $icao_history_point_ref,
        $line_number,
        $SEASONALITY_HISTORY_COLUMN_VISIBILITY_MILES,
        $SEASONALITY_VISIBILITY_MINIMUM,
        $SEASONALITY_VISIBILITY_MAXIMUM,
    );

    return;
} # end validate_visibility_miles()

sub validate_temperature_c {
    my ($icao_history_point_ref, $line_number) = @_;

    _validate_floating_point(
        $icao_history_point_ref,
        $line_number,
        $SEASONALITY_HISTORY_COLUMN_TEMPERATURE_C,
        $SEASONALITY_TEMPERATURE_MINIMUM,
        $SEASONALITY_TEMPERATURE_MAXIMUM,
    );

    return;
} # end validate_temperature_c()

sub validate_dewpoint_c {
    my ($icao_history_point_ref, $line_number) = @_;

    _validate_floating_point(
        $icao_history_point_ref,
        $line_number,
        $SEASONALITY_HISTORY_COLUMN_DEWPOINT_C,
        $SEASONALITY_TEMPERATURE_MINIMUM,
        $SEASONALITY_TEMPERATURE_MAXIMUM,
    );

    return;
} # end validate_dewpoint_c()

sub validate_pressure_hpa {
    my ($icao_history_point_ref, $line_number) = @_;

    _validate_integer(
        $icao_history_point_ref,
        $line_number,
        $SEASONALITY_HISTORY_COLUMN_PRESSURE_HPA,
        $SEASONALITY_PRESSURE_MINIMUM,
        $SEASONALITY_PRESSURE_MAXIMUM,
    );

    return;
} # end validate_pressure_hpa()

sub validate_relative_humidity {
    my ($icao_history_point_ref, $line_number) = @_;

    _validate_integer(
        $icao_history_point_ref,
        $line_number,
        $SEASONALITY_HISTORY_COLUMN_RELATIVE_HUMIDITY,
        $SEASONALITY_RELATIVE_HUMIDITY_MINIMUM,
        $SEASONALITY_RELATIVE_HUMIDITY_MAXIMUM,
    );

    return;
} # end validate_relative_humidity()

sub _check_basic_history_point_validity {
    # Don't want to mess with caller(), so explicit subroutine name is used.
    my ($icao_history_point_ref, $line_number, $subroutine) = @_;

    if (! defined $icao_history_point_ref) {
        ## no critic (RequireInterpolationOfMetachars)
        Mac::Apps::Seasonality::InvalidDataSizeException->throw(
            message =>
                'INTERNAL ERROR: please report this to the maintainer--'
                    . ' undefined $icao_history_point_ref passed to'
                    . " $subroutine.",
            input_line_number => $line_number,
            input_data_ref => $icao_history_point_ref,
            expected_number_of_elements => $SEASONALITY_HISTORY_COLUMNS_COUNT,
            actual_number_of_elements => 0,
        );
        ## use critic
    } # end if

    my $column_count = scalar @{$icao_history_point_ref};
    my $incorrect_quantity_qualifier =
        $SEASONALITY_HISTORY_COLUMNS_COUNT > $column_count
            ? 'Insufficient'
            : $SEASONALITY_HISTORY_COLUMNS_COUNT < $column_count
                ? 'Excess'
                : undef;
    if ($incorrect_quantity_qualifier) {
        Mac::Apps::Seasonality::InvalidDataSizeException->throw(
            message =>
                "$incorrect_quantity_qualifier data found on line $line_number;"
                    . " expected $SEASONALITY_HISTORY_COLUMNS_COUNT columns,"
                    . " but found $column_count columns.",
            input_line_number => $line_number,
            input_data_ref => $icao_history_point_ref,
            expected_number_of_elements => $SEASONALITY_HISTORY_COLUMNS_COUNT,
            actual_number_of_elements => $column_count,
        );
    } # end if

    return;
} # end _check_basic_history_point_validity()

sub _clean_integer {
    my (
        $icao_history_point_ref,
        $line_number,
        $column_name,
        $minimum_value,
        $maximum_value
    )
        = @_;

    my ($metric_value, $column_number, $defined_message) =
        _get_value_and_column_number_and_clean_undefined(
            $icao_history_point_ref,
            $line_number,
            $column_name,
        );
    my @clean_messages = $defined_message ? ( $defined_message ) : ( );

    if ($metric_value !~ m/\A $RE{num}{int} \z/xms) {
        my $real_column_number = $column_number - 1;

        if ($metric_value =~ m/\A $RE{num}{real} \z/xms) {
            my $int_value = int $metric_value + 0.5;
            $icao_history_point_ref->[ $real_column_number ] = $int_value;

            push
                @clean_messages,
                "Value given for $column_name ('$metric_value') on line"
                    . " $line_number, column number $column_number, was"
                    . " rounded to $int_value.";
        } else {
            $icao_history_point_ref->[ $real_column_number ] = $SEASONALITY_INVALID_DATA;

            push
                @clean_messages,
                "Value given for $column_name ('$metric_value') on line"
                    . " $line_number, column number $column_number, does not"
                    . ' look like an integer. Will be treated as missing.';
        };
    } # end if

    push
        @clean_messages,
        _clean_number_range(
            $icao_history_point_ref,
            $line_number,
            $column_name,
            $column_number,
            $minimum_value,
            $maximum_value
        );

    return @clean_messages;
} # end _clean_integer()

sub _clean_floating_point {
    my (
        $icao_history_point_ref,
        $line_number,
        $column_name,
        $minimum_value,
        $maximum_value
    )
        = @_;

    my ($metric_value, $column_number, $defined_message) =
        _get_value_and_column_number_and_clean_undefined(
            $icao_history_point_ref,
            $line_number,
            $column_name,
        );
    my @clean_messages = $defined_message ? ( $defined_message ) : ( );

    if ($metric_value !~ m/\A $RE{num}{real} \z/xms) {
        $icao_history_point_ref->[ $column_number - 1 ] = $SEASONALITY_INVALID_DATA;

        push
            @clean_messages,
            "Value given for $column_name ('$metric_value') on line"
                . " $line_number, column number $column_number, does not"
                . ' look like a number. Will be treated as missing.';
    } # end if

    push
        @clean_messages,
        _clean_number_range(
            $icao_history_point_ref,
            $line_number,
            $column_name,
            $column_number,
            $minimum_value,
            $maximum_value
        );

    return @clean_messages;
} # end _clean_floating_point()

sub _get_value_and_column_number_and_clean_undefined {
    my ($icao_history_point_ref, $line_number, $column_name) = @_;

    my $real_column_number =
        $SEASONALITY_HISTORY_COLUMN_NUMBERS_BY_COLUMN_NAME_REF->{$column_name};

    my $metric_value = $icao_history_point_ref->[ $real_column_number ];

    my $column_number = $real_column_number + 1;

    my $message;
    if (not defined $metric_value or $metric_value eq q{}) {
        $metric_value = $SEASONALITY_INVALID_DATA;
        $icao_history_point_ref->[ $real_column_number ] = $metric_value;

        $message =
            "No value given for $column_name on line $line_number, column"
                . " number $column_number.";
    } # end if

    return ($metric_value, $column_number, $message);
} # end _get_value_and_column_number_and_clean_undefined()

sub _clean_number_range {
    my (
        $icao_history_point_ref,
        $line_number,
        $column_name,
        $column_number,
        $minimum_value,
        $maximum_value
    )
        = @_;

    my $real_column_number = $column_number - 1;
    my $metric_value = $icao_history_point_ref->[$real_column_number];

    if ($metric_value == $SEASONALITY_INVALID_DATA) {
        return;
    } # end if

    if ($metric_value < $minimum_value or $metric_value > $maximum_value) {
        $icao_history_point_ref->[$real_column_number] = $SEASONALITY_INVALID_DATA;

        return
            "Value given for $column_name ('$metric_value') on line"
                . " $line_number, column number $column_number, was not"
                . " within the range $minimum_value to $maximum_value."
                . ' Will be treated as a missing value.'
    } # end if

    return;
} # end _clean_number_range()

sub _validate_integer {
    my (
        $icao_history_point_ref,
        $line_number,
        $column_name,
        $minimum_value,
        $maximum_value
    )
        = @_;

    my ($metric_value, $column_number) =
        _get_value_and_column_number_and_validate_defined(
            $icao_history_point_ref,
            $line_number,
            $column_name,
        );

    if ($metric_value !~ m/\A $RE{num}{int} \z/xms) {
        Mac::Apps::Seasonality::InvalidDatumException->throw(
            message =>
                "Value given for $column_name ('$metric_value') on line"
                    . " $line_number, column number $column_number, does not"
                    . ' look like an integer.',
            input_line_number => $line_number,
            input_data_ref => $icao_history_point_ref,
            column_name => $column_name,
            column_number => $column_number,
            invalid_value => $metric_value,
        );
    } # end if

    _validate_number_range(
        $icao_history_point_ref,
        $line_number,
        $column_name,
        $column_number,
        $metric_value,
        $minimum_value,
        $maximum_value
    );

    return;
} # end _validate_integer()

sub _validate_floating_point {
    my (
        $icao_history_point_ref,
        $line_number,
        $column_name,
        $minimum_value,
        $maximum_value
    )
        = @_;

    my ($metric_value, $column_number) =
        _get_value_and_column_number_and_validate_defined(
            $icao_history_point_ref,
            $line_number,
            $column_name,
        );

    if ($metric_value !~ m/\A $RE{num}{real} \z/xms) {
        Mac::Apps::Seasonality::InvalidDatumException->throw(
            message =>
                "Value given for $column_name ('$metric_value') on line"
                    . " $line_number, column number $column_number, does not"
                    . ' look like a number.',
            input_line_number => $line_number,
            input_data_ref => $icao_history_point_ref,
            column_name => $column_name,
            column_number => $column_number,
            invalid_value => $metric_value,
        );
    } # end if

    _validate_number_range(
        $icao_history_point_ref,
        $line_number,
        $column_name,
        $column_number,
        $metric_value,
        $minimum_value,
        $maximum_value
    );

    return;
} # end _validate_floating_point()

sub _get_value_and_column_number_and_validate_defined {
    my ($icao_history_point_ref, $line_number, $column_name) = @_;

    my $column_number =
        $SEASONALITY_HISTORY_COLUMN_NUMBERS_BY_COLUMN_NAME_REF->{$column_name};

    my $metric_value = $icao_history_point_ref->[ $column_number ];

    $column_number++;

    if (! defined $metric_value) {
        Mac::Apps::Seasonality::InvalidDatumException->throw(
            message =>
                "No value given for $column_name on line $line_number, column"
                    . " number $column_number.",
            input_line_number => $line_number,
            input_data_ref => $icao_history_point_ref,
            column_name => $column_name,
            column_number => $column_number,
            invalid_value => $metric_value,
        );
    } # end if

    return ($metric_value, $column_number);
} # end _get_value_and_column_number_and_validate_defined()

sub _validate_number_range {
    my (
        $icao_history_point_ref,
        $line_number,
        $column_name,
        $column_number,
        $metric_value,
        $minimum_value,
        $maximum_value
    )
        = @_;

    if ($metric_value == $SEASONALITY_INVALID_DATA) {
        return;
    } # end if

    if ($metric_value < $minimum_value or $metric_value > $maximum_value) {
        Mac::Apps::Seasonality::InvalidDatumException->throw(
            message =>
                "Value given for $column_name ('$metric_value') on line"
                    . " $line_number, column number $column_number, is not"
                    . " within the range $minimum_value to $maximum_value.",
            input_line_number => $line_number,
            input_data_ref => $icao_history_point_ref,
            column_name => $column_name,
            column_number => $column_number,
            invalid_value => $metric_value,
        );
    } # end if

    return;
} # end _validate_number_range()

sub _prepare_icao_history_delete_statement {
    my $database_connection = shift;

    my $delete_statement = $database_connection->prepare(<<"END_DML");
        DELETE FROM
            $SEASONALITY_HISTORY_TABLE
        WHERE
                $SEASONALITY_HISTORY_COLUMN_ICAO = ?
            AND $SEASONALITY_HISTORY_COLUMN_DATE = ?
END_DML

    # The following values are bogus-- these statements are simply to tell
    # the driver what the parameter types are so that we can use execute()
    # without calling bind_param() each time. See "Binding Values Without
    # bind_param()" on pages 126-7 of Programming the Perl DBI.
    $delete_statement->bind_param(1, 'x', SQL_VARCHAR);
    $delete_statement->bind_param(2, '193705061825', SQL_DATETIME);

    return $delete_statement;
} # end _prepare_icao_history_delete_statement()

sub _prepare_icao_history_insert_statement {
    my $database_connection = shift;

    my $insert_statement = $database_connection->prepare(<<"END_DML");
        INSERT INTO
            $SEASONALITY_HISTORY_TABLE
        (
            $SEASONALITY_HISTORY_COLUMN_ICAO,
            $SEASONALITY_HISTORY_COLUMN_DATE,
            $SEASONALITY_HISTORY_COLUMN_WIND_DIRECTION,
            $SEASONALITY_HISTORY_COLUMN_WIND_SPEED_KNOTS,
            $SEASONALITY_HISTORY_COLUMN_GUST_SPEED_KNOTS,
            $SEASONALITY_HISTORY_COLUMN_VISIBILITY_MILES,
            $SEASONALITY_HISTORY_COLUMN_TEMPERATURE_C,
            $SEASONALITY_HISTORY_COLUMN_DEWPOINT_C,
            $SEASONALITY_HISTORY_COLUMN_PRESSURE_HPA,
            $SEASONALITY_HISTORY_COLUMN_RELATIVE_HUMIDITY
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
END_DML

    # The following values are bogus-- these statements are simply to tell
    # the driver what the parameter types are so that we can use execute()
    # without calling bind_param() each time. See "Binding Values Without
    # bind_param()" on pages 126-7 of "Programming the Perl DBI".
    ## no critic (ProhibitMagicNumbers)
    $insert_statement->bind_param( 1, 'x',              SQL_VARCHAR);
    $insert_statement->bind_param( 2, '193705061825',   SQL_DATETIME);
    $insert_statement->bind_param( 3, 1,                SQL_INTEGER);
    $insert_statement->bind_param( 4, 1,                SQL_INTEGER);
    $insert_statement->bind_param( 5, 1,                SQL_INTEGER);
    $insert_statement->bind_param( 6, 1.0,              SQL_FLOAT);
    $insert_statement->bind_param( 7, 1.0,              SQL_FLOAT);
    $insert_statement->bind_param( 8, 1.0,              SQL_FLOAT);
    $insert_statement->bind_param( 9, 1,                SQL_INTEGER);
    $insert_statement->bind_param(10, 1,                SQL_INTEGER);
    ## use critic

    return $insert_statement;
} # end _prepare_icao_history_insert_statement()

sub _prepare_db_status_update_statement {
    my $database_connection = shift;

    my $update_statement = $database_connection->prepare(<<"END_DML");
        UPDATE
            $SEASONALITY_DB_STATUS_TABLE
        SET
            $SEASONALITY_DB_STATUS_COLUMN_NEW_RECORDS_SINCE_VACUUM
                = 2 + $SEASONALITY_DB_STATUS_COLUMN_NEW_RECORDS_SINCE_VACUUM
END_DML

    return $update_statement;
} # end _prepare_db_status_update_statement()

sub _load_icao_history_row {
    my (
        $delete_statement,
        $insert_statement,
        $db_status_statement,
        $icao_history_point_ref
    ) =
        @_;

    $delete_statement->execute($icao_history_point_ref->[0], $icao_history_point_ref->[1]);
    $insert_statement->execute(@{$icao_history_point_ref});
    $db_status_statement->execute();

    return;
} # end _load_icao_history_row()


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

Mac::Apps::Seasonality::LoadICAOHistory -- Load data into an SQLite2 database
with the Seasonality weather.db schema.


=head1 VERSION

This document describes Mac::Apps::Seasonality::LoadICAOHistory version 0.0.5.


=head1 SYNOPSIS

    use English qw{ -no_match_vars };
    use DBI;
    use Mac::Apps::Seasonality::LoadICAOHistory qw{
        :conversion
        &clean_icao_history_set
        &load_icao_history
    };
    use Mac::Apps::Seasonality::Exceptions;

    my $celsius = convert_from_fahrenheit_to_celsius( 32.0 );
    my $hectopascals = convert_from_inches_of_mercury_to_hectopascals( 31.32);
    my $knots = convert_from_miles_per_hour_to_knots( 5.5 );

    my $data =
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

    my $database_connection =
        DBI->connect(
            "dbi:SQLite2:$database_file_name",
            q{},
            q{},
            {
                AutoCommit => 0,
                RaiseError => 1,
            }
        );

    clean_icao_history_set($data);

    eval { load_icao_history($database_connection, $data) };

    my $exception
    if ($exception = Mac::Apps::Seasonality::InvalidDatumException->caught()) {
        ...
    } elsif ($EVAL_ERROR) {
        ...
    } # end if


=head1 DESCRIPTION

Seasonality L<http://gauchosoft.com/Software/Seasonality/> is a weather
tracking and display application for Mac OS X.  This module provides a means
of getting data into Seasonality that it cannot retrieve on its own.


=head1 INTERFACE

Nothing is exported by default, but you can import everything using the
C<:all> tag.


=head2 Conversion

The following can be imported using the C<:conversion> tag.

=over

=item C<convert_from_fahrenheit_to_celsius($fahrenheit)>

=item C<convert_from_inches_of_mercury_to_hectopascals($inches)>

=item C<convert_from_miles_per_hour_to_knots($mph)>

These do the obvious conversions, but return the original value if it is
C<undef> or the
L<Mac::Apps::Seasonality::Constants/"$SEASONALITY_INVALID_DATA"> value.

=back


=head2 Input data cleanup

The following can be imported using the C<:cleaning> tag.

=over

=item C<clean_icao_history_set($icao_history_ref)>

Takes a reference to an array of references to arrays containing values
representing a single data point. The values in the second level arrays are
expected to be in the icao_history table's schema column order. In other
words, the parameter is a table that matches the icao_history database table's
layout.

Any invalid data in the set is marked as missing via the
L<Mac::Apps::Seasonality::Constants/"$SEASONALITY_INVALID_DATA"> value.

Returns a list of messages about the data that was affected.

=item C<clean_icao_history_point($icao_history_point_ref, $line_number)>

Takes a reference to an array of values representing a single data point and
the original line number this data was found on in the input source.  The
values are expected to be in the icao_history table's schema column order.

Any invalid data in the point is marked as missing via the
L<Mac::Apps::Seasonality::Constants/"$SEASONALITY_INVALID_DATA"> value.

Returns a list of messages about the data that was affected.

=back


=head2 Individual column cleanup

The following can be imported using the C<:cleaning> tag.

=over

=item C<clean_wind_direction(      $icao_history_point_ref, $line_number)>

=item C<clean_wind_speed_knots(    $icao_history_point_ref, $line_number)>

=item C<clean_gust_speed_knots(    $icao_history_point_ref, $line_number)>

=item C<clean_visibility_miles(    $icao_history_point_ref, $line_number)>

=item C<clean_temperature_c(       $icao_history_point_ref, $line_number)>

=item C<clean_dewpoint_c(          $icao_history_point_ref, $line_number)>

=item C<clean_pressure_hpa(        $icao_history_point_ref, $line_number)>

=item C<clean_relative_humidity(   $icao_history_point_ref, $line_number)>

Each of these takes a reference to an array of values representing a single
data point and the original line number this data was found on in the input
source. They pick out the datum that they are concerned about from the array
and attempt to fix any problems they find.

A list of messages about the modifications made is returned.

=back


=head2 Data loading.

=over

=item C<load_icao_history($database_connection, $icao_history_ref)>

Takes a reference to a DBI handle and to a reference to a set of ICAO metrics
and loads the data into the database.

C<$database_connection> must be an open handle to an SQLite2 database with
Seasonality's schema.  This handle must have the RaiseError option set on it;
this module does no error checking of database actions on its own.

C<$icao_history_ref> must be a reference to an array of ICAO data points,
where each data point is represented as a reference to an array of values in
the following order:

=over

=item Observation location identifier

=item Date and time of observation

=item Wind direction in degrees

=item Wind speed in knots

=item Gust speed in knots

=item Visibility in miles

=item Temperature in degrees Celsius

=item Dew point in degrees Celsius

=item Atmospheric pressure in hectopascals

=item Relative humidity in percent

=back

=for TODO commented out until individual validations are described.
For limitations on these values, see the descriptions of the validation
methods below.

If the attempt to load data is successful, no useful data is returned.  All
failures result in exceptions.

=back


=head2 Input data validation

The following can be imported using the C<:validation> tag.

=over

=item C<validate_icao_history_set($icao_history_ref)>

Takes a reference to an array of references to arrays containing values
representing a single data point. The values in the second level arrays are
expected to be in the icao_history table's schema column order. In other
words, the parameter is a table that matches the icao_history database table's
layout.

If the data is valid, no useful value is returned.

If the data is invalid, an instance of
L<Mac::Apps::Seasonality::InvalidDatumException> describing the problem is
thrown.

=item C<validate_icao_history_point($icao_history_point_ref, $line_number)>

Takes a reference to an array of values representing a single data point and
the original line number this data was found on in the input source.  The
values are expected to be in the icao_history table's schema column order.

If the data is valid, no useful value is returned.

If the data is invalid, an instance of
L<Mac::Apps::Seasonality::InvalidDatumException> describing the problem is
thrown.

=back


=head2 Individual column validation

The following can be imported using the C<:validation> tag.

=over

=item C<validate_icao(                $icao_history_point_ref, $line_number)>

=item C<validate_date(                $icao_history_point_ref, $line_number)>

=item C<validate_wind_direction(      $icao_history_point_ref, $line_number)>

=item C<validate_wind_speed_knots(    $icao_history_point_ref, $line_number)>

=item C<validate_gust_speed_knots(    $icao_history_point_ref, $line_number)>

=item C<validate_visibility_miles(    $icao_history_point_ref, $line_number)>

=item C<validate_temperature_c(       $icao_history_point_ref, $line_number)>

=item C<validate_dewpoint_c(          $icao_history_point_ref, $line_number)>

=item C<validate_pressure_hpa(        $icao_history_point_ref, $line_number)>

=item C<validate_relative_humidity(   $icao_history_point_ref, $line_number)>

Each of these takes a reference to an array of values representing a single
data point and the original line number this data was found on in the input
source. They pick out the datum that they are concerned about from the array
and check whether it conforms to the restrictions of that particular column.

If the datum is valid, no useful value is returned.

If the datum is invalid, an instance of
L<Mac::Apps::Seasonality::InvalidDatumException> describing the problem is
thrown.

=back


=head1 DIAGNOSTICS

TODO


=head1 CONFIGURATION AND ENVIRONMENT

This module assumes that it is running against a database in the format used
by Seasonality versions 1.3 and 1.4.


=head1 DEPENDENCIES

L<DBD::SQLite2>
L<Regexp::Common>
L<Mac::Apps::Seasonality::Constants>


=head1 INCOMPATIBILITIES

This module will not work on databases used by versions of Seasonality earlier
than version 1.3.


=head1 BUGS AND LIMITATIONS

=over

=item · The interface to this module is not frozen yet.

=item · Dates are only checked that they consist of twelve digits and are not
yet checked to see whether they are valid in the Gregorian calendar.

=item · The DIAGNOSTICS section above has not been filled in.

=back

Please report any bugs or feature requests to
C<bug-mac-apps-seasonality-loadicaohistory@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.


=head1 AUTHOR

Elliot Shank  C<< <perl@galumph.com> >>


=head1 LICENSE AND COPYRIGHT

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
SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES,
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
