#!/usr/bin/perl -X

use strict;
use Irssi;
use LWP::UserAgent;

use vars qw($VERSION %IRSSI);

$VERSION = "0.1";
%IRSSI = (
    authors     => 'rupa, denis Lemire',
    contact     => 'rupa@lrrr.us',
    name        => 'hlprowl.pl',
    description => 'prowl stuff to your iphone when you are away',
    license     => 'GPLv2',
    url         => '',
);

my $debug = 0;

sub send_prowl {
    # function lightly edited via
    # http://www.denis.lemire.name/2009/07/07/prowl-irssi-hack/
    my ($event, $text) = @_;

    print "Sending prowl" if $debug;

    my %options = ();

    $options{'application'} ||= "Irssi";
    $options{'event'} = $event;
    $options{'notification'} = $text;
    $options{'priority'} ||= 0;

    if (open(APIKEYFILE, $ENV{HOME} . "/.prowlkey")) {
        $options{apikey} = <APIKEYFILE>;
        chomp $options{apikey};
        close(APIKEYFILE);
    } else {
        print "Unable to open prowl key file" if $debug;
    }

    # URL encode our arguments
    $options{'application'} =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
    $options{'event'} =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
    $options{'notification'} =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;

    # Generate our HTTP request.
    my ($userAgent, $request, $response, $requestURL);
    $userAgent = LWP::UserAgent->new;
    $userAgent->agent("ProwlScript/1.0");

    $requestURL = sprintf("https://prowl.weks.net/publicapi/add?apikey=%s&application=%s&event=%s&description=%s&priority=%d",
                    $options{'apikey'},
                    $options{'application'},
                    $options{'event'},
                    $options{'notification'},
                    $options{'priority'});

    $request = HTTP::Request->new(GET => $requestURL);
    $response = $userAgent->request($request);

    if ($response->is_success) {
        print "Notification successfully posted." if $debug;
    } elsif ($response->code == 401) {
        print "Notification not posted: incorrect API key." if $debug;
    } else {
        print "Notification not posted: ". $response->content if $debug;
    }
}

sub print_text {
    my ($dest, $text, $stripped) = @_;
    my $server = $dest->{server};
    return if !($dest->{level} & MSGLEVEL_HILIGHT);
    return if not $server->{usermode_away};
    send_prowl($dest->{target}, $stripped);
}

sub message_private {
    my ($server, $msg, $nick, $addr) = @_;
    return if not $server->{usermode_away};
    send_prowl($nick, $msg);
}

Irssi::signal_add('print text', 'print_text');
Irssi::signal_add('message private', 'message_private');
