use strict;
use Irssi;
use vars qw($VERSION %IRSSI);

$VERSION = "0.1";
%IRSSI = (
    authors     => 'rupa',
    contact     => 'rupa@lrrr.us',
    name        => 'hlagg.pl',
    description => 'store higlighted lines internally',
    license     => 'GNU General Public License',
    url         => '',
);

my @hls;
my @hlnew;

sub cmd_help {
    my @hlp = (
        $IRSSI{'name'}.": ".$IRSSI{'description'},
        "/hlagg all   - show all",
        "/hlagg clear - clear list",
        "/hlagg N     - show last N entries",
        "/hlagg       - show all new entries",
    );
    Irssi::print(join("\n", @hlp), MSGLEVEL_NOTICES);
}

sub hlagg {
    my ($q) = @_;
    my $out;
    my $window = Irssi::active_win();
    return cmd_help() if $q eq "help";
    if( $q eq "clear" ) {
        @hls = ();
        return;
    } elsif( $q eq "all" or ($q > 0 and (scalar(@hls) - $q) <= 0) ) {
        return if !@hls;
        $window->print(join("\n", @hls), MSGLEVEL_NOTICES);
    } elsif ( $q > 0 ) {
        return if !@hls;
        $window->print(join("\n", @hls[(scalar(@hls) - $q) .. $#hls]), MSGLEVEL_NOTICES);
    } else {
        return if !@hlnew;
        $window->print(join("\n", @hlnew), MSGLEVEL_NOTICES);
        @hlnew = ();
    }
    $window->print(join("\n", @hlnew), MSGLEVEL_NOTICES);
}

sub print_text {
    my ($dest, $text, $stripped) = @_;
    my $server = $dest->{server};
    return if (!$server || !($dest->{level} & MSGLEVEL_HILIGHT));
    my $sender = $stripped;
    $sender =~ s/^\<.([^\>]+)\>.+/$1/ ;
    $stripped =~ s/^\<.[^\>]+\>.// ;
    $stripped =~ s/\x03\d?\d?(,\d\d?)?|\x02|\x1f|\x16|\x06//g;
    my $summary = $dest->{target} . ": " . $sender;
    push(@hls, localtime(time)." $summary $stripped");
    push(@hlnew, localtime(time)." $summary $stripped");
}

Irssi::signal_add('print text', 'print_text');
Irssi::command_bind('hlagg', 'hlagg');
