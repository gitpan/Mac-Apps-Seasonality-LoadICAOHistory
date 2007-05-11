use strict;
use warnings;

use Test::More;

# Do not modify the following line by hand.  Use Test::Count.
plan tests => 13;


use Mac::Apps::Seasonality::Constants qw{ :all };
use Mac::Apps::Seasonality::LoadICAOHistory qw{ :conversion };

my $max_epsilon = 0.000_000_01;

# TEST:$invalid_data_tests=3
sub test_invalid_data {
    my ($sub_name, $sub_ref) = @_;

    my %invalid_values = (
        'q{}' => q{},
        'undef' => undef,
        '$SEASONALITY_INVALID_DATA' => $SEASONALITY_INVALID_DATA,
    );
    while (my ($value_string, $value) = each %invalid_values) {
        is(
            $sub_ref->($value),
            $value,
            "$sub_name($value_string) should return its input",
        );
    } # end while
} # end test_invalid_data()


# TEST
cmp_ok(
    epsilon( convert_from_fahrenheit_to_celsius( 32 ), 0 ),
    '<',
    $max_epsilon,
    'convert_from_fahrenheit_to_celsius() of the freezing point of water.',
);

# TEST*$invalid_data_tests
test_invalid_data(
    'convert_from_fahrenheit_to_celsius',
    \&convert_from_fahrenheit_to_celsius
);


# TEST
cmp_ok(
    epsilon( convert_from_fahrenheit_to_celsius( 212 ), 100 ),
    '<',
    $max_epsilon,
    'convert_from_fahrenheit_to_celsius() of the boiling point of water.',
);


# TEST
cmp_ok(
    epsilon( convert_from_inches_of_mercury_to_hectopascals( 30 ), 1015.916_600_01 ),
    '<',
    $max_epsilon,
    'convert_from_inches_of_mercury_to_hectopascals() of 30 inches.',
);

# TEST*$invalid_data_tests
test_invalid_data(
    'convert_from_inches_of_mercury_to_hectopascals',
    \&convert_from_inches_of_mercury_to_hectopascals
);


# TEST
cmp_ok(
    epsilon( convert_from_miles_per_hour_to_knots( 20 ), 17.3795248 ),
    '<',
    $max_epsilon,
    'convert_from_miles_per_hour_to_knots() of 20 mph.',
);

# TEST*$invalid_data_tests
test_invalid_data(
    'convert_from_miles_per_hour_to_knots',
    \&convert_from_miles_per_hour_to_knots
);


sub epsilon {
    my ($actual, $expected) = @_;

    my $denominator = $expected ? $expected : 1;

    return abs ( ($actual - $expected) / $denominator);
} # end epsilon()

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
