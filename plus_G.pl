use strict;
use warnings;

use Irssi;
use vars qw($VERSION %IRSSI);

$VERSION = '1.0';
%IRSSI = (
    authors     => '',
    contact     => '',
    name        => 'self <censored>',
    description => 'Stop all the cussing.',
    license     => 'Public domain',
);

# USAGE: /set G <ON|OFF>

Irssi::settings_add_bool('Censored', 'G', 0);

sub plus_G {
    my ($message, $server, $item) = @_;
    my $censored = Irssi::settings_get_bool("G");

    if (!$censored) {
        Irssi::signal_continue($message, $server, $item);
        return;
    }

    for ($message) {

        # found with /stats b (only works on some slashnet servers)
        # c = channel, m = message, q = quit (?)
        s/\btits\b/<censored>/g;
        s/fuck/<censored>/g;
        s/\bsonuvabitch\b/<censored>/g;
        s/\bdickhead\b/<censored>/g;
        s/\bgay\b/<censored>/g;
        s/\bhorny\b/<censored>/g;
        s/\bfag\b/<censored>/g;
        s/\bfaggot\b/<censored>/g;
        s/fucker/<censored>/g;
        s/\bjackass\b/<censored>/g;
        s/\bpenis\b/<censored>/g;
        s/\bvagina\b/<censored>/g;
        s/\bcunt\b/<censored>/g;
        s/\bbitch\b/<censored>/g;
        s/\basshole\b/<censored>/g;
        s/\bshit\b/<censored>/g;
        s/\bslut\b/<censored>/g;
        s/\bwhore\b/<censored>/g;
        s/\bfuck\b/<censored>/g;
        s/\bpussy\b/<censored>/g;
        s/\bcleveland\b/hell/g;

    }

    Irssi::signal_continue($message, $server, $item);
}

Irssi::signal_add("send text", \&plus_G);
