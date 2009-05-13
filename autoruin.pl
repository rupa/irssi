#!/usr/bin/perl
use strict;
use vars qw($VERSION %IRSSI);

$VERSION = "0.0.1";
%IRSSI = (
    authors     => "rupa",
    contact     => "",
    name        => "",
    description => "autoruin",
    url         => "",
    changed     => "",
    modules     => "",
    license     => "GPLv2",
);

print CLIENTCRAP "autoruin.pl $VERSION loaded.";

sub onflood {
    return if not Irssi::settings_get_bool("autoruin");
    my ($server, $nick, $host, $level, $chan) = @_;

    return if $server->{tag} ne "slashnet";
    return if $chan ne "#mefi";

    $server->command("/MSG $chan RUIN");
}				

Irssi::signal_add('flood', 'onflood');
Irssi::settings_add_bool("autoruin", "autoruin", 0);
