#!/usr/bin/perl
use strict;
use vars qw($VERSION %IRSSI);

$VERSION = "0.0.1";
%IRSSI = (
    authors     => "31d1",
    contact     => "",
    name        => "",
    description => "stop a bus",
    url         => "",
    changed     => "",
    modules     => "",
    license     => "GPLv2",
);

print CLIENTCRAP "defense.pl $VERSION loading.";

# chans to defend yourself in
my @defensechans = ("#mefi", "#dongs");

sub frigth_back {
    my ($tag, $cmd) = split(/\|/, $@_);
    my $server = Irssi::server_find_tag($tag);
    $server->command($cmd);
}

sub onmode {
    my ($server, $chan, $setby, $setbyaddr, $mode) = @_;

    return unless grep(/$chan/, @defensechans);

    # get unbanned
    if( $mode =~ /^\+b/ && $mode =~ /\Q$server->{nick}\E/ ) {
        $server->command("/msg Chanserv unban $chan $server->{nick}");
        Irssi::timeout_add_once(2000, "fk_u", "$server->{tag}|/join $chan");

        return if not Irssi::settings_get_bool("frigth_back");
        Irssi::timeout_add_once(2000, "fk_u", "$server->{tag}|/kick $chan $setby");

    # regain ops
    } elsif( $mode =~ /^\-o/ && $mode =~ /\Q$server->{nick}\E/ ) {
        $server->command("/msg Chanserv op $chan $server->{nick}");

        return if not Irssi::settings_get_bool("frigth_back");
        Irssi::timeout_add_once(2000, "fk_u", "$server->{tag}|/kick $chan $setby");
    }

}

Irssi::signal_add('message irc mode', 'onmode');
Irssi::settings_add_bool("defense", "frigth_back", 0);
