package Mac::Apps::Seasonality::LoadICAOHistoryExceptions;

use utf8;
use 5.008006;
use strict;
use warnings;
use Carp;

use version; our $VERSION = qv('v0.0.5');

## no critic (RestrictLongStrings)
use Exception::Class (
    'Mac::Apps::Seasonality::LoadICAOHistoryException' => {
        description => 'A problem with dealing with ICAO history.',
    },

    'Mac::Apps::Seasonality::ValidationException' => {
        isa         => 'Mac::Apps::Seasonality::LoadICAOHistoryException',
        description => 'A problem with input data.',
        fields      => [ qw{ input_line_number } ],
    },

    'Mac::Apps::Seasonality::CSVParseException' => {
        isa         => 'Mac::Apps::Seasonality::ValidationException',
        description => 'A problem with a line of text that is supposed to be in CSV format.',
        fields      => [ qw{ invalid_input } ],
    },

    'Mac::Apps::Seasonality::DataException' => {
        isa         => 'Mac::Apps::Seasonality::ValidationException',
        description => 'A problem with the content of input data.',
        fields      => [ qw{ input_data_ref } ],
    },
    'Mac::Apps::Seasonality::InvalidDataSizeException' => {
        isa         => 'Mac::Apps::Seasonality::DataException',
        description => 'An array that is supposed to represent one data point has too much or too little data in it.',
        fields      => [ qw{ expected_number_of_elements actual_number_of_elements } ],
    },
    'Mac::Apps::Seasonality::InvalidDatumException' => {
        isa         => 'Mac::Apps::Seasonality::DataException',
        description => 'An individual data item that is not valid for the aspect of a data point it represents.',
        fields      => [ qw{ column_name column_number invalid_value } ],
    },
);
## use critic

1; # Magic true value required at end of module

__END__

=encoding utf8

=head1 NAME

Mac::Apps::Seasonality::LoadICAOHistoryExceptions - Exceptions thrown for
various problems when dealing with ICAO history.


=head1 VERSION

This document describes Mac::Apps::Seasonality::LoadICAOHistoryExceptions
version 0.0.5.


=head1 SYNOPSIS

 use Mac::Apps::Seasonality::LoadICAOHistoryExceptions;

 eval { ... };

 my $exception;
 if ($exception = Mac::Apps::Seasonality::ICAOHistory::InvalidDatumException->caught()) {
    ... $exception->column_name ...
 } # end if


=head1 DESCRIPTION

This module contains all the exception classes used to indicate problems with
processing ICAO data.


=head1 INTERFACE

The exception hierarchy.

=over

=item C<Mac::Apps::Seasonality::ICAOHistory::LoadICAOHistoryException>

Base exception class with no behavior beyond that supplied by
L<Exception::Class>.

=over

=item C<Mac::Apps::Seasonality::ICAOHistory::ValidationException>

A problem with input ICAO history data.

=over

I<Attributes>:

C<input_line_number>: The line number that the problematic data was found on.>

=back


=over

=item C<Mac::Apps::Seasonality::ICAOHistory::CSVParseException>

A problem with a line of text that is supposed to be in CSV format but
actually isn't.


=item C<Mac::Apps::Seasonality::ICAOHistory::DataException>

A problem with the input (post parsing from CSV) that is supposed to represent
one data point.

=over

I<Attributes>:

C<input_data_ref>: A reference to an array containing the values for one data
point, in the order of the columns in the icao_history database table.

=back


=over

=item C<Mac::Apps::Seasonality::ICAOHistory::InvalidDataSizeException>

An array that is supposed to represent one data point has too much or too
little data in it.

=over

I<Attributes>:

C<expected_number_of_elements>: How many items were there supposed to be.

C<actual_number_of_elements>: How many items there were.

=back


=item C<Mac::Apps::Seasonality::ICAOHistory::InvalidDatumException>

An individual data item is not valid for the aspect of a data point it
represents.

=over

I<Attributes>:

C<column_name>: The name of the column in the icao_history database table that
the datum is intended for.

C<column_number>: The position the invalid datum is in in the input.

C<invalid_value>: The actual value in question.

=back


=back

=back

=back

=back


=head1 DIAGNOSTICS

This module I<is> nothing but diagnostics.


=head1 CONFIGURATION AND ENVIRONMENT

Mac::Apps::Seasonality::LoadICAOHistoryExceptions requires no configuration
files or environment variables.


=head1 DEPENDENCIES

L<Exception::Class>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

That this module exists at all because data can't be magically be corrected
without the assistance of a human being.

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
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
