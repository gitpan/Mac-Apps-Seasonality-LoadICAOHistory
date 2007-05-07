package Mac::Apps::Seasonality::CommandLineUtilities;

use utf8;
use 5.008006;
use strict;
use warnings;

use version; our $VERSION = qv('v0.0.5');

use English qw{ −no_match_vars };
use Carp;
use Fatal qw{ open close read write };
use Readonly;

use Exporter qw( import );

use Time::localtime;
use File::Copy;
use DBI;

use Mac::Processes qw{ LSFindApplicationForInfo };
use Mac::Apps::Launch;

use Mac::Apps::Seasonality::Constants qw{ :application };

Readonly our $GROWL_NOTIFICATION_PROGRESS                       => 'Progress';
Readonly our $GROWL_NOTIFICATION_SEASONALITY_APPLICATION_STATUS => "$SEASONALITY_NAME application status";
Readonly our $GROWL_NOTIFICATION_ERROR                          => 'Error';

Readonly our $GROWL_NOTIFICATIONS_REF   => [
    $GROWL_NOTIFICATION_PROGRESS,
    $GROWL_NOTIFICATION_SEASONALITY_APPLICATION_STATUS,
    $GROWL_NOTIFICATION_ERROR,
];
Readonly our $GROWL_APPLICATION_ICON    => $SEASONALITY_NAME;


our @EXPORT_OK      = qw{
    $GROWL_NOTIFICATION_PROGRESS
    $GROWL_NOTIFICATION_SEASONALITY_APPLICATION_STATUS
    $GROWL_NOTIFICATION_ERROR

    $GROWL_NOTIFICATIONS_REF
    $GROWL_APPLICATION_ICON

    &initialize_program_utilities
    &state_progress
    &shutdown_seasonality_if_necessary
    &create_database_connection
    &close_database_connection
    &restart_seasonality_if_necessary
};
our %EXPORT_TAGS    = (
    all             => [@EXPORT_OK],
    growl           => [
        qw{
            $GROWL_NOTIFICATION_PROGRESS
            $GROWL_NOTIFICATION_SEASONALITY_APPLICATION_STATUS
            $GROWL_NOTIFICATION_ERROR

            $GROWL_NOTIFICATIONS_REF
            $GROWL_APPLICATION_ICON
        }
    ],
    functions       => [
        qw{
            &initialize_program_utilities
            &state_progress
            &shutdown_seasonality_if_necessary
            &create_database_connection
            &close_database_connection
            &restart_seasonality_if_necessary
        }
    ],
);


eval 'use Mac::Growl qw{ RegisterNotifications PostNotification };';    ## no critic (ProhibitStringyEval)
Readonly my $GROWL_AVAILABLE        => not $EVAL_ERROR;


Readonly my $EMPTY_STRING               => q{};
Readonly my $SEASONALITY_PATH           => LSFindApplicationForInfo($SEASONALITY_CREATOR);
Readonly my $STANDARD_DELAY_SECONDS     => 5;
Readonly my $UNINITIALIZED_ERROR_STRING =>
    __PACKAGE__ . ' has not been initialized.  Call initialize_program_utilities() first.';

Readonly my $TM_STRUCT_BASE_YEAR    => 1900;
Readonly my $TM_STRUCT_MONTH_OFFSET =>    1;


my $application_name            = undef;
my $quiet                       = 0;
my $use_growl                   = 0;
my $initialized                 = 0;
my $start_seasonality_at_end    = 0;
my $seasonality_is_running      = undef;
my $database_connection         = undef;


sub initialize_program_utilities {
    $application_name = shift;

    my %options = @_;

    $quiet = $options{quiet} ? 1 : 0;
    $use_growl = defined $options{use_growl} ? $options{use_growl} : 1;

    if (not $application_name) {
        state_progress(
            $GROWL_NOTIFICATION_ERROR,
            'No application name was given to initialize_program_utilities().'
        );

        croak $EMPTY_STRING;
    } # end if

    if ($use_growl and not $GROWL_AVAILABLE) {
        $use_growl = 1;
    } # end if

    if ($use_growl) {
        RegisterNotifications(
            $application_name,
            $GROWL_NOTIFICATIONS_REF,
            $GROWL_NOTIFICATIONS_REF,
            $GROWL_APPLICATION_ICON
        );
    } # end if

    $initialized = 1;

    return;
} # end init()

sub state_progress {
    my ($notification, $message) = @_;

    if (not $initialized) {
        croak $UNINITIALIZED_ERROR_STRING;
    } # end if

    if ($quiet and $notification ne $GROWL_NOTIFICATION_ERROR) {
        return;
    } # end if

    if ($use_growl) {
        PostNotification(
            $application_name,
            $notification,
            $notification,
            $message,
            $notification eq $GROWL_NOTIFICATION_ERROR  # sticky
        );
    } # end if

    print $message, "\n";

    return;
} # end state_progress()


sub shutdown_seasonality_if_necessary {
    my %options = @_;
    my $no_shutdown = $options{no_shutdown} ? 1 : 0;
    my $no_restart = $options{no_restart} ? 1 : 0;
    my $force_start = $options{force_start} ? 1 : 0;
    my $shutdown_wait =
        defined $options{shutdown_wait}
            ? $options{shutdown_wait}
            : $STANDARD_DELAY_SECONDS;

    if (not $initialized) {
        state_progress(
            $GROWL_NOTIFICATION_ERROR,
            $UNINITIALIZED_ERROR_STRING
        );

        croak $EMPTY_STRING;
    } # end if

    $seasonality_is_running = IsRunning($SEASONALITY_CREATOR);
    if ($seasonality_is_running) {
        if ($no_shutdown) {
            state_progress(
                $GROWL_NOTIFICATION_SEASONALITY_APPLICATION_STATUS,
                "$SEASONALITY_NAME is running, but it will not be shut down."
            );
        } else {
            $start_seasonality_at_end = ! $no_restart || $force_start;

            state_progress(
                $GROWL_NOTIFICATION_SEASONALITY_APPLICATION_STATUS,
                "Attempting to shut down $SEASONALITY_NAME."
            );

            if (not QuitApps($SEASONALITY_CREATOR)) {
                state_progress(
                    $GROWL_NOTIFICATION_ERROR,
                    "Could not shut down $SEASONALITY_NAME: $EXTENDED_OS_ERROR"
                );

                croak $EMPTY_STRING;
            } # end if

            if ($shutdown_wait) {
                state_progress(
                    $GROWL_NOTIFICATION_SEASONALITY_APPLICATION_STATUS,
                    "Waiting for $SEASONALITY_NAME to shut down."
                );

                sleep $shutdown_wait;
            } # end if

            $seasonality_is_running = 0;
        } # end if
    } else {
        $start_seasonality_at_end = $force_start;
    } # end if

    return;
} # end shutdown_seasonality_if_necessary()


sub create_database_connection {
    my ($database_file_name, %options) = @_;
    my $backup = $options{backup} ? 1 : 0;

    if (not $initialized) {
        state_progress(
            $GROWL_NOTIFICATION_ERROR,
            $UNINITIALIZED_ERROR_STRING
        );

        croak $EMPTY_STRING;
    } # end if

    if (not -w $database_file_name) {
        state_progress(
            $GROWL_NOTIFICATION_ERROR,
            q{"}
                . $database_file_name
                . q{" does not exist as a writable file.  Will not create it.}
        );

        croak $EMPTY_STRING;
    } # end if

    if ($backup) {
        if ($seasonality_is_running) {
            state_progress(
                $GROWL_NOTIFICATION_PROGRESS,
                "Not backing up database because $SEASONALITY_NAME is running.",
            );
        } else {
            my $time = localtime;
            my $backup_file_name =
                sprintf
                    '%s.backup.%d-%02d-%02d.%02d:%02d:%02d',
                    $database_file_name,
                    $time->year + $TM_STRUCT_BASE_YEAR,
                    $time->mon + $TM_STRUCT_MONTH_OFFSET,
                    $time->mday,
                    $time->hour,
                    $time->min,
                    $time->sec,
                ;

            state_progress(
                $GROWL_NOTIFICATION_PROGRESS,
                "Backing up database to $backup_file_name.",
            );

            if ( not copy($database_file_name, $backup_file_name) ) {
                state_progress(
                    $GROWL_NOTIFICATION_ERROR,
                    qq{Could not copy "$database_file_name" to "$backup_file_name": $OS_ERROR}
                );

                croak $EMPTY_STRING;
            } # end if
        } # end if
    } # end if


    state_progress(
        $GROWL_NOTIFICATION_PROGRESS,
        'Connecting to database.',
    );

    $database_connection =
        DBI->connect(
            "dbi:SQLite2:$database_file_name",
            $EMPTY_STRING,
            $EMPTY_STRING,
            {
                AutoCommit => 0,
                RaiseError => 1,
            }
        );
    if (! defined $database_connection) {
        state_progress(
            $GROWL_NOTIFICATION_ERROR,
            "Could not open $database_file_name: $DBI::errstr"
        );

        croak $EMPTY_STRING;
    } # end if

    return $database_connection;
} # end create_database_connection()


sub close_database_connection {
    if (defined $database_connection) {
        $database_connection->disconnect();

        state_progress(
            $GROWL_NOTIFICATION_PROGRESS,
            'Disconnected from database.',
        );
    } # end if

    return;
} # end close_database_connection()


sub restart_seasonality_if_necessary {
    if ($start_seasonality_at_end) {
        state_progress(
            $GROWL_NOTIFICATION_SEASONALITY_APPLICATION_STATUS,
            "Attempting to start $SEASONALITY_NAME."
        );

        if (not LaunchApps($SEASONALITY_CREATOR)) {
            state_progress(
                $GROWL_NOTIFICATION_ERROR,
                "Could not start $SEASONALITY_NAME: $EXTENDED_OS_ERROR",
            );

            exit 1;
        } # end if
    } # end if
} # end restart_seasonality_if_necessary()


1; # Magic true value required at end of module

__END__

=pod

=encoding utf8

=for stopwords STDOUT

=head1 NAME

Mac::Apps::Seasonality::CommandLineUtilities - Utility routines for
command-line tools related to Seasonality.


=head1 VERSION

This document describes Mac::Apps::Seasonality::CommandLineUtilities version
0.0.5.


=head1 SYNOPSIS

    use Mac::Growl qw{ RegisterNotifications PostNotification };

    use Mac::Apps::Seasonality::Constants qw{ :application };
    use Mac::Apps::Seasonality::CommandLineUtilities qw{ :growl };

    RegisterNotifications(
        'Command-line Tool Name',
        $GROWL_NOTIFICATIONS_REF,
        $GROWL_NOTIFICATIONS_REF,
        $GROWL_APPLICATION_ICON
    );

    PostNotification(
        'Command-line Tool Name',
        $GROWL_NOTIFICATION_PROGRESS,
        'Notification Title',
        'Notification Text',
    );
    PostNotification(
        'Command-line Tool Name',
        $GROWL_NOTIFICATION_SEASONALITY_APPLICATION_STATUS
        'Notification Title',
        "$SEASONALITY_NAME is currently causing a rainstorm in Death Valley",
    );
    PostNotification(
        'Command-line Tool Name',
        $GROWL_NOTIFICATION_ERROR
        'Notification Title',
        q{Could not go to the gym today. It's too hot outside.},
        'sticky'
    );



    use DBI;
    use Mac::Apps::Seasonality::CommandLineUtilities    qw{ :all };

    initialize_program_utilities(
        'Command-line Tool Name',
        quiet => 0,
        use_growl => 1,
    );

    state_progress($GROWL_NOTIFICATION_PROGRESS, q{Hey! I'm doing something!};

    shutdown_seasonality_if_necessary(
        no_shutdown   => 0,
        no_restart    => 0,
        force_start   => 0,
        shutdown_wait => 5,
    );

    my $database_connection = create_database_connection('weather.db', backup => 1);

    # do something with the database.

    close_database_connection();

    restart_seasonality_if_necessary();



=head1 DESCRIPTION

This is a set of utilities for building applications which deal with
Seasonality.  All functions expect that C<initialize_program_utilities()> has
been called first.  Most functions will emit messages about what they're doing
via C<state_progress()>.  This behavior can be disabled by passing a true
value for the second parameter to C<initialize_program_utilities()>.  The
C<state_progress()> function emits messages to STDOUT and via Growl
notifications if L<Mac::Growl> is installed and the third parameter to
C<initialize_program_utilities()> is a true value.



=head1 INTERFACE

=over

=item C<$GROWL_NOTIFICATION_PROGRESS>

The progress notification for Growl, to be used as the second parameter to
L<Mac::Growl/"PostNotification"> in order to announce actions being taken by
the program.

=item C<$GROWL_NOTIFICATION_SEASONALITY_APPLICATION_STATUS>

The state of Seasonality notification for Growl, to be used as the second
parameter to L<Mac::Growl/"PostNotification"> in order to announce whether the
program thinks Seasonality is running or not.

=item C<$GROWL_NOTIFICATION_ERROR>

The error notification for Growl, to be used as the second parameter to
L<Mac::Growl/"PostNotification"> in order to announce problems found by the
program.

=item C<$GROWL_NOTIFICATIONS_REF>

A reference to an array containing C<$GROWL_NOTIFICATION_PROGRESS>,
C<$GROWL_NOTIFICATION_SEASONALITY_APPLICATION_STATUS>, and
C<$GROWL_NOTIFICATION_ERROR>.  This is useful for the second and third
parameters to L<Mac::Growl/"RegisterNotifications">.

=item C<$GROWL_APPLICATION_ICON>

The name of the icon to use for notifications.

=item C<initialize_program_utilities( $application_name, [ quiet =E<gt> $boolean, ] [ use_growl =E<gt> $boolean, ] )>

Saves the name of the application, tells C<state_progress()> whether to
actually emit anything and whether it should use Growl if it is available.
Also it initializes Growl if it is to be used.

No useful value is returned.


=item C<state_progress( $notification, $message )>

Emits messages to STDOUT and to Growl, if it is enabled.

The C<$notification> parameter should be one of
C<$GROWL_NOTIFICATION_PROGRESS>,
C<$GROWL_NOTIFICATION_SEASONALITY_APPLICATION_STATUS>, or
C<$GROWL_NOTIFICATION_ERROR> if Growl is being used.  In particular, if this
parameter is C<$GROWL_NOTIFICATION_ERROR>, the message will be emitted even if
the call to C<initialize_program_utilities()> stated that the application
should be quiet; also, if Growl is enabled, the notification will be sticky.

No useful value is returned.


=item C<shutdown_seasonality_if_necessary( [ no_shutdown =E<gt> $boolean, ] [ no_restart =E<gt> $boolean, ] [ force_start =E<gt> $boolean, ] [ shutdown_wait =E<gt> $seconds, ] )>

Shuts down Seasonality, if it is running, and gathers the information that
C<restart_seasonality_if_necessary()> needs.

If C<no_shutdown> is true, Seasonality will not be shut down, even if is
running.

If C<no_restart> is true, Seasonality will not be restarted by
C<restart_seasonality_if_necessary()>, even if it was running when this
function was called.

If C<force_start> is true, Seasonality will be started by
C<restart_seasonality_if_necessary()>, even if it wasn't running when this
function was called.  A true value for this parameter overrides the value of
C<no_restart>.

The value of C<shutdown_wait> is the number of seconds to wait for Seasonality
to stop, if it is going to be brought down.

No useful value is returned.


=item C<create_database_connection( $database_file_name, [ backup =E<gt> $boolean, ] )>

TODO


=item C<close_database_connection()>

TODO


=item C<restart_seasonality_if_necessary()>

TODO


=back


=head1 EXPORT TAGS

None of the above constants or functions are exported by default.  They have
to be individually imported, or you can use the following tags.

=over

=item C<:all>

Import everything.


=item C<:growl>

Import the C<$GROWL_*> constants.


=item C<:functions>

Import the functions.


=back


=head1 DIAGNOSTICS

=over

=item C<< No application name was given to initialize_program_utilities(). >>

No arguments were given to C<initialize_program_utilities()> or the
application name was empty.


=item C<< Mac::Apps::Seasonality::CommandLineUtilities has not been initialized.  Call initialize_program_utilities() first. >>

A function in this package was invoked before
C<initialize_program_utilities()> was called.


=item C<< Could not shut down Seasonality: $EXTENDED_OS_ERROR >>

An attempt to stop a current Seasonality process failed for the specified
reason.


=item C<< "%s" does not exist as a writable file.  Will not create it. >>

A call was made to C<create_database_connection()> with the path to the
database not existing or not being writable.  All database files should be
created by Seasonality in order to ensure that it doesn't run into any
problems with them.


=item C<< Could not copy "%s" to "%s": $OS_ERROR >>

An attempt to back up the database failed.


=item C<< Could not open %s: $DBI::errstr >>

An attempt to open the database failed due to a problem discovered by the
database driver.


=back


=head1 CONFIGURATION AND ENVIRONMENT

Mac::Apps::Seasonality::CommandLineUtilities requires no configuration files
or environment variables.


=head1 DEPENDENCIES

L<DBD::SQLite2>
L<Mac::Apps::Launch>
L<Mac::Apps::Seasonality::Constants>
L<Mac::Processes>
L<Readonly>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

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
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
