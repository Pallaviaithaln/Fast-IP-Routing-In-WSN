puts "\n\n"
puts "==================++++++++++++++++++++++++++++++++++==================="
puts "==========================WSN Demo===================================="
puts "==================++++++++++++++++++++++++++++++++++==================="
puts "\n\n"

puts "+=======================================================+"
puts "+		N	=	Number of Nodes		+"
puts "+		A	=	Target Area		+"
puts "+		ST	=	Simulation Time	        +"
puts "+		RR	=	Transmission Range	+"
puts "+		Gt	=	Transmission Gain	+"
puts "+		Gr	=	Reception Gain		+"
puts "+		Pl	=	Path Loss		+"
puts "+=======================================================+"
puts "\n\n";


puts "Configure Number of Nodes(N)";
gets stdin argv;

puts "Configure Target Area(A) by X and Y Value";
gets stdin X_area;
gets stdin Y_area;


puts "Configure Tarnsmission Range in Meters(TR)"
gets stdin Radio_Range;


puts "Configure Transmission Gain";
gets stdin Gt;

puts "Reception Transmission Gain";
gets stdin Gr;

puts "Configure Path Loss Value";
gets stdin path_loss

puts "Configure The Energy in Joules"
gets stdin Energy_Value

puts "Enter the Packet Size in kbps"
gets stdin Packet_Size

set val(chan)          Channel/WirelessChannel      ;# channel type
set val(prop)          Propagation/TwoRayGround     ;# radio-propagation model
set val(netif)         Phy/WirelessPhy   	    ;# network interface type
set val(mac)           Mac/802_11	            ;# MAC type
set val(ifq)           Queue/DropTail/PriQueue      ;# interface queue type
set val(ll)            LL                           ;# link layer type
set val(ant)           Antenna/OmniAntenna          ;# antenna model
set val(ifqlen)        100	         	    ;# max packet in ifq
set val(nn)            [lindex $argv]		    ;# number of mobilenodes
set val(rp)            AODV			    ;# protocol tye
set val(x)             $X_area			    ;# X dimension of topography
set val(y)             $Y_area			    ;# Y dimension of topography
set val(stop)          50			    ;# simulation period 
set val(energymodel)   EnergyModel		    ;# Energy Model
set val(initialenergy) $Energy_Value			    ;# value

set ns        		[new Simulator]
set tracefd       	[open WSN.tr w]
set namtrace      	[open WSN.nam w]

$ns trace-all $tracefd
$ns namtrace-all-wireless $namtrace $val(x) $val(y)

# set up topography object
set topo       [new Topography]
$topo load_flatgrid $val(x) $val(y)

create-god $val(nn)

# configure the nodes
$ns node-config -adhocRouting $val(rp) \
            -llType $val(ll) \
             -macType $val(mac) \
             -ifqType $val(ifq) \
             -ifqLen $val(ifqlen) \
             -antType $val(ant) \
             -propType $val(prop) \
             -phyType $val(netif) \
             -channel [new $val(chan)] \
             -topoInstance $topo \
             -agentTrace ON \
             -routerTrace ON \
             -macTrace  OFF \
             -movementTrace OFF \
             -energyModel $val(energymodel) \
             -initialEnergy $val(initialenergy) \
             -rxPower 0.25 \
             -txPower 0.5 \
	     -idlePower 0.005 \
	     -sleepPower 10.0009 

for {set i 0} {$i < $val(nn) } { incr i } {
        set mnode_($i) [$ns node]
}

for {set i 2} {$i < $val(nn) } { incr i } {
	$mnode_($i) set X_ [ expr {$val(x) * rand()} ]
	$mnode_($i) set Y_ [ expr {$val(y) * rand()} ]
	$mnode_($i) set Z_ 0
}

# Position of Destination
$mnode_(0) set X_ 0.0
$mnode_(0) set Y_ 0.0
$mnode_(0) set Z_ 0.0
$mnode_(0) label "Destination"


# Position of Source 
$mnode_(1) set X_ 1000.0
$mnode_(1) set Y_ 1000.0
$mnode_(1) set Z_ 0.0
$mnode_(1) label "Source"



for {set i 0} {$i < $val(nn)} { incr i } {
	$ns initial_node_pos $mnode_($i) 55
}

#Setup a UDP connection
set udp [new Agent/TCP]
$ns attach-agent $mnode_(1) $udp

set sink [new Agent/TCPSink]
$ns attach-agent $mnode_(0) $sink

$ns connect $udp $sink
#$udp set fid_ 2

#Setup a CBR over UDP connection
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $udp
$cbr set type_ CBR
$cbr set packet_size_ 50
$cbr set rate_ 0.1Mb
$cbr set interval_ 0.005
#$cbr set random_ false


$ns at 0.1 "$cbr start"
$ns at [expr $val(stop) - 5] "$cbr stop"

# Telling nodes when the simulation ends
for {set i 0} {$i < $val(nn) } { incr i } {
    $ns at $val(stop) "$mnode_($i) reset;"
}

# ending nam and the simulation
$ns at $val(stop) "$ns nam-end-wireless $val(stop)"
$ns at $val(stop) "stop"
$ns at [expr $val(stop) + 0.01] "puts \"end simulation\"; $ns halt"

proc stop {} {
    global ns tracefd namtrace
    $ns flush-trace
    close $tracefd
    close $namtrace
    exec nam WSN.nam &
}
$ns run

