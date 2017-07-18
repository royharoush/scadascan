use strict;
use IO::Socket::INET;
use IO::Select;
use Net::IP;
use Switch;


use constant MAX_RECV_LEN => 65536;

sub check_dnp_tcp
{
	my @buffer = ();
	my $data;

	my $ip = $_[0];

	print "\nProcessing DNP...";
	# DNP 3.0 link layer frame
	# Start character (2 bytes)
	$buffer[0] = chr(5);
	$buffer[1] = chr(100);
	# Length field (1 byte)
	$buffer[2] = chr(05);
	# Control byte (1 byte)
	$buffer[3] = chr(201);
	# Destination address (2 bytes)
	$buffer[4] = chr(241);
	$buffer[5] = chr(255);
	# Source address (2 bytes)
	$buffer[6] = chr(05);
	$buffer[7] = chr(00);
	# CRC (2 bytes)
	$buffer[8] = chr(170);
	$buffer[9] = chr(210);

       # flush after every write
       	$| = 1;

	my $socket;

       	$socket = IO::Socket::INET->new (
               PeerHost => $ip,
               PeerPort => '20000',
               Proto => 'tcp',
	       Timeout => 3);
	if(!$socket) {        
		print "\nDNP not running";
		return 0;
	}

	$data = join('',@buffer);
	$socket->send($data);

        $socket->recv($data, MAX_RECV_LEN);
        my $len = length($data);

	@buffer = $data;

	if(($buffer[0] == chr(5)) && $buffer[1] == chr(100)){
		print "\nDNP3 running";
	}
	else {
		print "\nDNP not running";
	}
	$socket->close();
}

sub check_modbus_tcp
{

	my $quantity = 1;
	my $start_add = 0;
	my $pack_val = unpack('H*',pack("n",$start_add));
	my @buffer = ();
	my $data;
	my $slave_id = 0;
	my $ip = $_[0];

	# flush after every write
	$| = 1;

	my $socket;

	$socket = IO::Socket::INET->new (
		PeerHost => $ip,
		PeerPort => '502',
		Proto => 'tcp',
		Timeout => 3);
	if(!$socket){
		print "\nModbus not running";
		return 0;
	}

	
	# Transaction ID (2 bytes)
		$buffer[0] = chr(1);
		$buffer[1] = chr(0);
	# Protocol ID (2 bytes)	
		$buffer[2] = chr(0);
		$buffer[3] = chr(0);
	# Length (2 bytes)
		$buffer[4] = chr(0);	
		$buffer[5] = chr(6);
	# Unit ID (1 bye)
		$buffer[6] = chr($slave_id);
	# Function Code (1 byte)
		$buffer[7] = chr(3);
	# Data
		$buffer[8] = chr(hex (substr $pack_val, 0, 2));
		$buffer[9] = chr(hex (substr $pack_val, 2, 2));
		$buffer[10] = chr(0);
		$buffer[11] = chr($quantity);

	my $found = 0;
	
	for($slave_id = 0; $found == 0; ++$slave_id){

		$buffer[6] = chr($slave_id);
		$data = join('',@buffer);
		$socket->send($data);


		my $select = IO::Select->new();
		$select->add($socket);
		my @ok_to_read = $select->can_read(2);
		my $soc;
		$data = '';
		foreach $soc (@ok_to_read) {
			$soc->recv($data,MAX_RECV_LEN);
		}
		my $len = length($data);
		if($len <= 0){
			print ".";
		}
		else {
			# More data validation here
			$found = 1;
			print "Modbus unit ID $slave_id found\n";
		}
	}
	$socket->close();
}

sub get_cmd_args
{
	my $ip_str='';
	my $num_args=0;
	my $modbus=0;
	my $dnp=0;
	my $i=0;
	my $mbselect=0;
       
	$num_args = $#ARGV + 1;
	if ($num_args <= 0) {
		print "\nUsage: scada_scan.pl [-m -d ] <IP Range>\n";
		print "Options:\n";
		print "         -m : Modbus bruteforce slave ID\n";
		print "         -d : DNP 3.0 TCP scan\n";
		exit;
	}

	for($i = 0; $i < $num_args-1; ++$i) {
		switch($ARGV[$i]) {
			case "-m"{
				$modbus = 1;
			}
			case "-d"{
				$dnp = 1;
			}	
			default{
				print "\nUnknown option.";
				exit;
			}
		}
	}	

	if($modbus == 0 && $dnp == 0){
		print " No option selected. Exiting";
		exit;
	}	
	$ip_str = $ARGV[$num_args - 1];
	my $ip = new Net::IP ($ip_str);
	if(!$ip){
		die (Net::IP::Error());
	}

	$_[0] = $modbus;
	$_[1] = $dnp;
	$_[2] = $ip;
}

my $modbus = 0;
my $dnp = 0;
my $ip;
my $sid;
my $found;

&get_cmd_args($modbus, $dnp, $ip);

do {

	print "\nWorking on ";
	print	($ip->ip());
	if($modbus == 1){
		check_modbus_tcp($ip->ip);
	}


	if($dnp == 1) {
		check_dnp_tcp($ip->ip);
	}
} while(++$ip);


