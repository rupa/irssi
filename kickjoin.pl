#!/usr/bin/perl
use strict;
use vars qw($VERSION %IRSSI);
use Data::Dumper;

$VERSION = "0.0.1";
%IRSSI = (
    authors     => "rupa",
    contact     => "",
    name        => "",
    description => "be a douche and kick people on join",
    license     => "GPLv2",
    url         => "",
    changed     => "",
    modules     => "",
);

my %kicklist;

print CLIENTCRAP "kickjoin.pl $VERSION loaded.";
print CLIENTCRAP "/set kickjoin on|off";
print CLIENTCRAP "/kickjoin [-] [nick] [seconds]";

sub kicklist {
    my ($msg, $server, $chan) = @_;
    my @msg = split(/ /, $msg);
    my ($nick, $a);

    if( ! @msg ) {
        # list all
        print CLIENTCRAP Dumper(%kicklist);

    } elsif( $msg[0] eq "-" ) {
        # remove from list
        delete($kicklist{$msg[1]});

    } elsif( ! $chan ) {
        # list one
        print CLIENTCRAP Dumper($kicklist{$msg[0]});

    } else {
        # add to list
        $kicklist{$msg[0]} = [ $server->{tag}, $chan->{name}];

        # remove from list at some point
        if( $msg[1] ) {
            my $say = "/MSG $chan->{name} eat shit for $msg[1] sec, $msg[0]";
            $server->command($say);
            Irssi::timeout_add_once($msg[1] * 1000, sub {
                delete($kicklist{$msg[0]});
                $server->command("/MSG $chan->{name} $msg[0] done eating shit");
            }, []);
            $server->command("/KICK $chan->{name} $msg[0]");
        }
    }
}

sub onjoin {
    return if not Irssi::settings_get_bool("kickjoin");
    my ($server, $chan, $nick, $addr) = @_;

    return if not $kicklist{$nick};
    return if $server->{tag} ne $kicklist{$nick}[0];
    return if $chan ne $kicklist{$nick}[1];

    $server->command("/KICK $chan $nick");
}

Irssi::signal_add("message join", "onjoin");
Irssi::settings_add_bool("kickjoin", "kickjoin", 0);
Irssi::command_bind("kickjoin", "kicklist", "kickjoin")
