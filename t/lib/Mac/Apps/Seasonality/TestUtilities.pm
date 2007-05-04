package Mac::Apps::Seasonality::TestUtilities;

use strict;
use warnings;

use version; our $VERSION = qv('v0.0.4');

use Fatal qw{ :void close };
use Readonly;
use File::Temp qw{ tempfile };
use DBI;

use Exporter qw( import );

our @EXPORT         = qw{ $EMPTY_STRING $SPACE createTestDatabase };
our @EXPORT_OK      = qw{ };
our %EXPORT_TAGS    = ( all => [ @EXPORT, @EXPORT_OK ] );

Readonly our $EMPTY_STRING  => q{};
Readonly our $SPACE         => q{ };

sub createTestDatabase {
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
} # end sub createTestDatabase

1;  # Magic true value required at end of module

__END__

=encoding utf8

=head1 NAME

Mac::Apps::Seasonality::TestUtilities - Various helper subroutines for testing
loading data into Seasonality's weather.db.


=head1 VERSION

This document describes Mac::Apps::Seasonality::TestUtilities version 0.0.4.


=head1 SYNOPSIS

    use Mac::Apps::Seasonality::TestUtilities;

    $db_connection = createTestDatabase();


=head1 INTERFACE

=over

=item $EMPTY_STRING

Empty string constant.


=item $SPACE

Single space constant.


=item createTestDatabase()

Creates a temporary database with the Seasonality weather.db schema.  This
database will automatically be deleted upon program termination.


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
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=0 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
