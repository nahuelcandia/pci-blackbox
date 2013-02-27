#!/usr/bin/perl
use strict;
use warnings;
no warnings qw(uninitialized);

use DBI;
use DBIx::Pg::CallFunction;
use Test::More;
use Test::Deep;
use Data::Dumper;
plan tests => 6;

# Connect to the PCI compliant service
my $dbh_pci = DBI->connect("dbi:Pg:dbname=pci", '', '', {pg_enable_utf8 => 1, PrintError => 0});
my $pci = DBIx::Pg::CallFunction->new($dbh_pci);

# Connect to the non-PCI compliant service
my $dbh = DBI->connect("dbi:Pg:dbname=nonpci", '', '', {pg_enable_utf8 => 1, PrintError => 0});
my $nonpci = DBIx::Pg::CallFunction->new($dbh);

my $cardnumber              = '4111111111111111';
my $cardexpirymonth         = 06;
my $cardexpiryyear          = 2016;
my $cardholdername          = 'Simon Hopper';
my $currencycode            = 'EUR';
my $paymentamount           = 20;
my $reference               = rand();
my $shopperip               = '1.2.3.4';
my $cardcvc                 = 737;
my $shopperemail            = 'test@test.com';
my $shopperreference        = rand();
my $fraudoffset             = undef;
my $selectedbrand           = undef;
my $browserinfoacceptheader = 'text/html,application/xhtml+xml, application/xml;q=0.9,*/*;q=0.8';
my $browserinfouseragent    = 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9) Gecko/2008052912 Firefox/3.0';

my $merchant_account = $nonpci->get_merchant_account();
cmp_deeply(
    $merchant_account,
    {
        psp             => re('.+'),
        merchantaccount => re('.+'),
        url             => re('^https://'),
        username        => re('.+'),
        password        => re('.+')
    },
    'Get_Merchant_Account'
);

# Store sensitive card data encrypted to the
# PCI-DSS compliant protected component
my $cardkey = $pci->encrypt_card({
    _cardnumber      => $cardnumber,
    _cardexpirymonth => $cardexpirymonth,
    _cardexpiryyear  => $cardexpiryyear,
    _cardholdername  => $cardholdername,
    _cardissuenumber => undef,
    _cardstartmonth  => undef,
    _cardstartyear   => undef
});
like($cardkey,qr/^[0-9a-f]{512}$/,'Encrypt_Card');

my $cardid = $nonpci->store_card_key({_cardkey => $cardkey});
cmp_ok($cardid,'>=',1,"Store_Card_Key");

my $request = {
    _cardkey                 => $cardkey,
    _psp                     => $merchant_account->{psp},
    _merchantaccount         => $merchant_account->{merchantaccount},
    _url                     => $merchant_account->{url},
    _username                => $merchant_account->{username},
    _password                => $merchant_account->{password},
    _currencycode            => $currencycode,
    _paymentamount           => $paymentamount,
    _reference               => $reference,
    _shopperip               => $shopperip,
    _cardcvc                 => $cardcvc,
    _shopperemail            => $shopperemail,
    _shopperreference        => $shopperreference,
    _fraudoffset             => $fraudoffset,
    _selectedbrand           => $selectedbrand,
    _browserinfoacceptheader => $browserinfoacceptheader,
    _browserinfouseragent    => $browserinfouseragent
};

# Use the card by passing the CardKey
# along with the payment information
my $response = $pci->authorise_payment_request($request);

cmp_deeply(
    $response,
    {
        'dccamount'     => undef,
        'md'            => undef,
        'authcode'      => re('^\d+$'),
        'dccsignature'  => undef,
        'fraudresult'   => undef,
        'parequest'     => undef,
        'refusalreason' => undef,
        'issuerurl'     => undef,
        'resultcode'    => 'Authorised',
        'pspreference'  => re('^\d+$')
    },
    'Authorise_Payment_Request, card on file'
);

$request = {
    _cardnumber              => $cardnumber,
    _cardexpirymonth         => $cardexpirymonth,
    _cardexpiryyear          => $cardexpiryyear,
    _cardholdername          => $cardholdername,
    _cardissuenumber         => undef,
    _cardstartmonth          => undef,
    _cardstartyear           => undef,
    _psp                     => $merchant_account->{psp},
    _merchantaccount         => $merchant_account->{merchantaccount},
    _url                     => $merchant_account->{url},
    _username                => $merchant_account->{username},
    _password                => $merchant_account->{password},
    _currencycode            => $currencycode,
    _paymentamount           => $paymentamount,
    _reference               => $reference,
    _shopperip               => $shopperip,
    _cardcvc                 => $cardcvc,
    _shopperemail            => $shopperemail,
    _shopperreference        => $shopperreference,
    _fraudoffset             => $fraudoffset,
    _selectedbrand           => $selectedbrand,
    _browserinfoacceptheader => $browserinfoacceptheader,
    _browserinfouseragent    => $browserinfouseragent
};

$response = $pci->authorise_payment_request($request);

cmp_deeply(
    $response,
    {
        'cardkey'       => re('^[a-f0-9]{512}$'),
        'dccamount'     => undef,
        'md'            => undef,
        'authcode'      => re('^\d+$'),
        'dccsignature'  => undef,
        'fraudresult'   => undef,
        'parequest'     => undef,
        'refusalreason' => undef,
        'issuerurl'     => undef,
        'resultcode'    => 'Authorised',
        'pspreference'  => re('^\d+$')
    },
    'Authorise_Payment_Request, new card'
);

# 3D Secure test card
$request->{_cardnumber} = '5212345678901234';

$response = $pci->authorise_payment_request($request);

cmp_deeply(
    $response,
    {
        'dccamount'     => undef,
        'md'            => re('^[a-zA-Z0-9/+=]+$'),
        'authcode'      => undef,
        'cardkey'       => re('^[a-f0-9]{512}$'),
        'dccsignature'  => undef,
        'fraudresult'   => undef,
        'parequest'     => re('^[a-zA-Z0-9/+=]+$'),
        'refusalreason' => undef,
        'issuerurl'     => re('^https://'),
        'resultcode'    => 'RedirectShopper',
        'pspreference'  => re('^\d+$')
    },
    'Authorise_Payment_Request, new card, 3D Secure'
);

$cardid = $nonpci->store_card_key({_cardkey => $response->{cardkey}});



