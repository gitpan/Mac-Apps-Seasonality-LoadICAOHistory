package Mac::Apps::Seasonality::LoadICAOHistoryFromCSV;

use utf8;
use 5.008006;
use strict;
use warnings;
use Carp;

use version; our $VERSION = qv('v0.0.4');

use Exporter qw( import );

our @EXPORT_OK =
    qw{
        load_icao_history_from_csv_handle
    };

use Text::CSV_XS;

use Mac::Apps::Seasonality::LoadICAOHistory qw{ load_icao_history };
use Mac::Apps::Seasonality::LoadICAOHistoryExceptions;

sub load_icao_history_from_csv_handle {
    my ($database_handle, $io_handle) = @_;

    my $parser = Text::CSV_XS->new();

    my $data_set_ref = [];
    my $line;
    while (defined($line = $io_handle->getline()) and $parser->parse($line)) {
        my @fields = $parser->fields();

        foreach my $field (@fields) {
            $field =~ s{ \A \s+ }{ }xms;
            $field =~ s{ \s+ \z }{ }xms;
            if (length $field == 0) {
                $field = undef;
            } # end if
        } # end foreach

        push @{$data_set_ref}, [ @fields ];
    } # end while

    if (defined $line) {
        my $line_number = scalar @{$data_set_ref} + 1;
        Mac::Apps::Seasonality::CSVParseException->throw(
            message => "Invalid CSV input on line $line_number: " . $parser->error_input(),
            input_line_number => $line_number,
            invalid_input => $parser->error_input(),
        );
    } # end if

    load_icao_history($database_handle, $data_set_ref);

    return scalar @{$data_set_ref};
} # end load_icao_history_from_csv_handle()


1; # Magic true value required at end of module

__END__

=encoding utf8

=head1 NAME

Mac::Apps::Seasonality::LoadICAOHistoryFromCSV - Load data from a CSV file into
Seasonality's database.


=head1 VERSION

This document describes Mac::Apps::Seasonality::LoadICAOHistoryFromCSV
version 0.0.4.


=head1 SYNOPSIS

    use English qw{ -no_match_vars };
    use Fatal qw{ open close read write };
    use IO::File;
    use DBI;
    use Mac::Apps::Seasonality::LoadICAOHistoryFromCSV
        qw{ load_icao_history_from_csv_handle };
    use Mac::Apps::Seasonality::Exceptions;

    my $file_handle = IO::File->new('data.csv', 'r');

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

    eval { load_icao_history_from_csv_handle($database_connection, $file_handle) };

    my $exception
    if ($exception = Mac::Apps::Seasonality::CSVParseException->caught()) {
        ...
    } elsif ($exception = Mac::Apps::Seasonality::InvalidDatumException->caught()) {
        ...
    } elsif ($EVAL_ERROR) {
        ...
    } # end if


=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE

=over

=item load_icao_history_from_csv_handle($database_connection, $io_handle)

Takes a reference to a DBI handle and to an I/O handle referring to data in CSV
format and loads the data from the handle into the database.

C<$database_connection> must be an open handle to an SQLite2 database with
Seasonality's schema.  This handle must have the RaiseError option set on it;
this module does no error checking of database actions on its own.

C<$io_handle> must be an open handle to data in CSV format, with the data on
each line in the order described in the documentation for
L<Mac::Apps::Seasonality::LoadICAOHistory/load_icao_history>.  No checking is
done for I/O errors, so the use of the Fatal module is highly suggested.  The
data read from this handle must not contain anything other than the actual data
to be loaded.  In particular, this means that there cannot be any column
headers.

If no problems are encountered, the number of data points loaded is returned.

A Mac::Apps::Seasonality::CSVParseException is thrown if the raw input cannot
be turned into the module's internal representation.

A Mac::Apps::Seasonality::InvalidDatumException is thrown if an individual
value does not fit the constraints required by Seasonality.

=back


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.

Mac::Apps::Seasonality::LoadICAOHistoryFromCSV requires no configuration files
or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-mac-apps-seasonality-loadicaohistory@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.


=head1 AUTHOR

Elliot Shank  C<< perl@galumph.com >>


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
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=0 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
