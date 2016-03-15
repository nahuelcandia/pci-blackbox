CREATE OR REPLACE FUNCTION Authorise(
OUT AuthoriseRequestID uuid,
OUT ResultCode text,
OUT TermURL text,
OUT IssuerURL text,
OUT MD text,
OUT PaReq text,
_OrderID text,
_CurrencyCode char(3),
_PaymentAmount numeric,
_CardNumberReference uuid,
_CardKey text,
_CardBIN char(6),
_CardLast4 char(4),
_CVCKey text,
_REMOTE_ADDR inet,
_HTTP_USER_AGENT text,
_HTTP_ACCEPT text
) RETURNS RECORD AS $BODY$
DECLARE
_ record;
_PCIBlackBoxURL text;
_PSP text;
_MerchantAccount text;
_URL text;
_Username text;
_Password text;
_CardID bigint;
_Reference text;
_ShopperEmail text;
_ShopperReference text;
_MerchantAccountID integer;

_AuthCode integer;
_PSPReference text;
BEGIN

-- In production, resolve these variables from OrderID:
SELECT
    'reference'||random()::text,
    'joe@joe.com',
    'shopperref'||random()::text
INTO STRICT
    _Reference,
    _ShopperEmail,
    _ShopperReference;

_CardID := Store_Card_Key(_CardNumberReference, _CardKey, _CardBIN, _CardLast4);

-- There is only one merchant account so far
SELECT MerchantAccountID, PSP, MerchantAccount, URL, Username, Password, PCIBlackBoxURL INTO STRICT _MerchantAccountID, _PSP, _MerchantAccount, _URL, _Username, _Password, _PCIBlackBoxURL FROM MerchantAccounts;

SELECT
    Authorise_Payment_Request_JSON_RPC.AuthCode,
    Authorise_Payment_Request_JSON_RPC.IssuerURL,
    Authorise_Payment_Request_JSON_RPC.MD,
    Authorise_Payment_Request_JSON_RPC.PaReq,
    Authorise_Payment_Request_JSON_RPC.PSPReference,
    Authorise_Payment_Request_JSON_RPC.ResultCode
INTO STRICT
    _AuthCode,
    Authorise.IssuerURL,
    Authorise.MD,
    Authorise.PaReq,
    _PSPReference,
    Authorise.ResultCode
FROM Authorise_Payment_Request_JSON_RPC(
    _PCIBlackBoxURL,
    _CardKey,
    _CVCKey,
    _PSP,
    _MerchantAccount,
    _URL,
    _Username,
    _Password,
    _CurrencyCode,
    _PaymentAmount,
    _Reference,
    _REMOTE_ADDR,
    _ShopperEmail,
    _ShopperReference,
    _HTTP_ACCEPT,
    _HTTP_USER_AGENT
);

INSERT INTO AuthoriseRequests (OrderID, CurrencyCode, PaymentAmount, MerchantAccountID, CardID, AuthCode, IssuerURL, MD, PaReq, PSPReference, ResultCode)
VALUES (_OrderID, _CurrencyCode, _PaymentAmount, _MerchantAccountID, _CardID, _AuthCode, Authorise.IssuerURL, Authorise.MD, Authorise.PaReq, _PSPReference, Authorise.ResultCode)
RETURNING AuthoriseRequests.AuthoriseRequestID INTO STRICT Authorise.AuthoriseRequestID;

-- Set this to your own domain-name:

TermURL := 'https://MY_EXTERNAL_IP:30001/nonpci/authorise_3d?redirect=1&authoriserequestid=' || AuthoriseRequestID;

RETURN;

END;
$BODY$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

REVOKE ALL ON FUNCTION Authorise(_OrderID text, _CurrencyCode char(3), _PaymentAmount numeric, _CardNumberReference uuid, _CardKey text, _CardBIN char(6), _CardLast4 char(4), _CVCKey text, _REMOTE_ADDR inet, _HTTP_USER_AGENT text, _HTTP_ACCEPT text) FROM PUBLIC;
GRANT  ALL ON FUNCTION Authorise(_OrderID text, _CurrencyCode char(3), _PaymentAmount numeric, _CardNumberReference uuid, _CardKey text, _CardBIN char(6), _CardLast4 char(4), _CVCKey text, _REMOTE_ADDR inet, _HTTP_USER_AGENT text, _HTTP_ACCEPT text) TO GROUP nonpci_api;
