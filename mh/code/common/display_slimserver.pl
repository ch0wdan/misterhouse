# Category = MisterHouse

#@ Echos spoken text to a Slimp3 display ( http://www.slimdevices.com ).
#@ Example mh.ini parms:  slimserver_clients=192.168.0.60:69,192.168.0.61:69  slimserver_server=192.168.0.2:9000

&Speak_pre_add_hook(\&slimserver_display, 0) if $Reload;

#speak "The time is $Time_Now" if new_second 15;

sub slimserver_display {
    my (%parms) = @_;
                                # Drop extra blanks and newlines
    return unless $parms{text};
    $parms{text} =~ s/[\n\r ]+/ /gm;

				# Allow for player and/or players parm
    $config_parms{slimserver_players} = $config_parms{slimserver_player} unless $config_parms{slimserver_players};
    for my $player (split ',', $config_parms{slimserver_players}) {
	my $request = "http://$config_parms{slimserver_server}/status?p0=display&p1=MisterHouse Message:&p2=$parms{text}&p3=30&player=$player";
        print "slimserver request: $request\n" if $Debug{'slimserver'};
	get $request;
    }
}


