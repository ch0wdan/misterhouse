
# Category = X10

#@ Relays selected X10 RF (Radio Frequency) data out to your X10 powerline interface.
#@ To enable a MR26 or W800RF32, set mh.ini parameters MODEL_module=X10_MODEL and MODEL_port=COM#,
#@ where MODEL is either MR26 or W800 (for W800RF32)
#@ (available from <a href=http://www.x10.com/products/x10_mr26a.htm>x10.com</a>
#@  or <a href=http://www.wgldesigns.com>wgldesigns.com</a>).
#@ Optionally set mh.ini parm x10_relay_hc to a regex to limit which house codes to relay 
#@ (e.g. [ap] to relay only house codes a and p).  Defaults to relaying all house codes.
#@ For more info, see comments at the top and bottom of mh/lib/X10_MR26.pm and X10_W800.pm.

# 10_rf_receiver  = new X10_MR26;
# 10_rf_receiver  = new X10_W800;
$X10_rf_receiver  = new X10_RF_Receiver;   # Works for both the MR26 and W800

print_log "X10 RF data: $state" if $state = state_now $X10_rf_receiver and $config_parms{x10_errata} >= 3;

                                # You may want to limit this to not relay busy motion detectors
$X10_transmitter = new X10_Item;
$X10_transmitter->{states_casesensitive} = 0;

if ($state = state_now $X10_rf_receiver and $state =~ /^X/i) {
    my $hc = $config_parms{x10_relay_hc};
    $hc = '.' unless $hc;
    if ($state =~ /^X$hc/i) {
        print_log "Relaying X10 RF data: $state" if  $config_parms{x10_errata} >= 3;
        set $X10_transmitter $state;
    }
}
