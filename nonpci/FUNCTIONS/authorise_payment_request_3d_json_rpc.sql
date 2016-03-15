CREATE OR REPLACE FUNCTION Authorise_Payment_Request_3D_JSON_RPC(
OUT PSPReference text,
OUT ResultCode text,
OUT AuthCode integer,
_PCIBlackBoxURL text,
_PSP text,
_MerchantAccount text,
_URL text,
_Username text,
_Password text,
_HTTP_ACCEPT text,
_HTTP_USER_AGENT text,
_MD text,
_PaRes text,
_ShopperIP inet
) RETURNS RECORD AS $BODY$

my ($PCIBlackBoxURL, $PSP, $MerchantAccount, $URL, $Username, $Password, $HTTP_ACCEPT, $HTTP_USER_AGENT, $MD, $PaRes, $ShopperIP) = @_;

use JSON::RPC::Simple::Client;
my $c = JSON::RPC::Simple::Client->new($PCIBlackBoxURL);

if ($PCIBlackBoxURL =~ m!^https://localhost!i) {
    # Test-environment or local call, skip check
    $c->{ua}->ssl_opts(verify_hostname => 0);
}

my $r = $c->authorise_payment_request_3d({
    psp                     => $PSP,
    merchantaccount         => $MerchantAccount,
    url                     => $URL,
    username                => $Username,
    password                => $Password,
    http_accept             => $HTTP_ACCEPT,
    http_user_agent         => $HTTP_USER_AGENT,
    md                      => $MD,
    pares                   => $PaRes,
    shopperip               => $ShopperIP
});
return $r;
$BODY$ LANGUAGE plperlu VOLATILE SECURITY DEFINER;

REVOKE ALL ON FUNCTION Authorise_Payment_Request_3D_JSON_RPC(_PCIBlackBoxURL text, _PSP text, _MerchantAccount text, _URL text, _Username text, _Password text, _HTTP_ACCEPT text, _HTTP_USER_AGENT text, _MD text, _PaRes text, _ShopperIP inet) FROM PUBLIC;
GRANT  ALL ON FUNCTION Authorise_Payment_Request_3D_JSON_RPC(_PCIBlackBoxURL text, _PSP text, _MerchantAccount text, _URL text, _Username text, _Password text, _HTTP_ACCEPT text, _HTTP_USER_AGENT text, _MD text, _PaRes text, _ShopperIP inet) TO GROUP nonpci_api;
