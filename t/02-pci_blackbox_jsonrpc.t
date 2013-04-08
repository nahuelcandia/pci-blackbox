#!/usr/bin/perl
use strict;
use warnings;
no warnings qw(uninitialized);

use Test::More;
use Test::Deep;
use Data::Dumper;
use JSON::RPC::Simple::Client;
use JSON qw(from_json to_json);
use DBI;
use DBIx::Pg::CallFunction;

plan tests => 3;

my $nonpci = JSON::RPC::Simple::Client->new('https://localhost:30001/nonpci');
my $pci    = JSON::RPC::Simple::Client->new('https://localhost:30002/pci');

$nonpci->{ua}->ssl_opts(verify_hostname => 0);
$pci->{ua}->ssl_opts(verify_hostname => 0);

# Variables used throughout the test
my $cardnumber              = '5212345678901234';
my $cardexpirymonth         = 06;
my $cardexpiryyear          = 2016;
my $cardholdername          = 'Simon Hopper';
my $currencycode            = 'EUR';
my $paymentamount           = 20;
my $reference               = rand();
my $cardcvc                 = 737;
my $shopperemail            = 'test@test.com';
my $shopperreference        = rand();



# Test 1, Get_Hash_Salt (not really necessary, you could also hard-code the HashSalt value in the javascript code to avoid this extra database call)
my $hashsalt = $nonpci->get_hash_salt();
like($hashsalt, qr{^\$2a\$08\$[a-zA-Z0-9./]{22}$}, 'Get_Hash_Salt');



# Test 2, Encrypt_Card
my $encrypted_card = $pci->encrypt_card({
    cardnumber      => $cardnumber,
    cardexpirymonth => $cardexpirymonth,
    cardexpiryyear  => $cardexpiryyear,
    cardholdername  => $cardholdername,
    cardissuenumber => undef,
    cardstartmonth  => undef,
    cardstartyear   => undef,
    hashsalt        => $hashsalt,
    cardcvc         => $cardcvc
});
cmp_deeply(
    $encrypted_card,
    {
        cardnumberreference => re('^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$'),
        cardkey             => re('^[0-9a-f]{512}$'),
        cardbin             => re('^[0-9]{6}$'),
        cardlast4           => re('^[0-9]{4}$'),
        cvckey              => re('^[0-9a-f]{512}$')
    },
    'Encrypt_Card'
);



# Test 3, Authorise
my $request_authorise = {
    orderid                 => 1234567890,
    currencycode            => $currencycode,
    paymentamount           => $paymentamount,
    cardnumberreference     => $encrypted_card->{cardnumberreference},
    cardkey                 => $encrypted_card->{cardkey},
    cardbin                 => $encrypted_card->{cardbin},
    cardlast4               => $encrypted_card->{cardlast4},
    cvckey                  => $encrypted_card->{cvckey},
    hashsalt                => $hashsalt,
    # these are overwritten by pci-blackbox.psgi:
    remote_addr             => undef,
    http_user_agent         => undef,
    http_accept             => undef
};
my $authorise_request_id = $nonpci->authorise($request_authorise);
like($authorise_request_id, qr/^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/, 'Authorise');
