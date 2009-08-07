#!/usr/bin/perl
use strict;
use vars qw($VERSION %IRSSI);

$VERSION = "0.0.1";
print CLIENTCRAP "defense.pl $VERSION loading.";
print CLIENTCRAP "/set frigth_back [on/off] - toggle /kick your attacker.";
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

# chans to defend yourself in
my @defensechans = ("#mefi", "#dongs");
# give Chanserv a chance to respond before we frigth back, in ms
my $hang = 3000;

sub frigth_back {
    my ($tag, $cmd) = split(/\|/, join(" ", @_));
    my $server = Irssi::server_find_tag($tag);
    $server->command($cmd);
}

sub onmode {
    my ($server, $chan, $setby, $setbyaddr, $mode) = @_;

    return unless grep(/$chan/, @defensechans);

    # get unbanned
    if( $mode =~ /^\+b (.*)/ ) {

        my $found;
        if( $mode =~ /\Q$server->{nick}\E/ ) {
            $found = 1;
        } else {
            my $chanobj = $server->channel_find($chan);
            my $nickobj = $chanobj->nick_find_mask($1);
            return unless $nickobj;
            if( $nickobj->{nick} eq $server->{nick} ) {
                $found = 1;
            }
        }
        return if not $found;

        $server->command("/msg Chanserv unban $chan $server->{nick}");
        Irssi::timeout_add_once($hang, "frigth_back",
                                "$server->{tag}|/join $chan");

        return unless Irssi::settings_get_bool("frigth_back");
        Irssi::timeout_add_once($hang + 2000, "frigth_back",
                                "$server->{tag}|/kick $chan $setby");

    # regain ops
    } elsif( $mode =~ /^\-o/ && $mode =~ /\Q$server->{nick}\E/ ) {
        $server->command("/msg Chanserv op $chan $server->{nick}");

        return unless Irssi::settings_get_bool("frigth_back");
        Irssi::timeout_add_once($hang, "frigth_back",
                                "$server->{tag}|/kick $chan $setby");
    }

}

Irssi::signal_add('message irc mode', 'onmode');
Irssi::settings_add_bool("defense", "frigth_back", 0);
