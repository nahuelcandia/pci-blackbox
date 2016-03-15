CREATE OR REPLACE FUNCTION Capture(
_AuthoriseRequestID uuid
) RETURNS BOOLEAN AS $BODY$
DECLARE
_PSP text;
_MerchantAccount text;
_URL text;
_Username text;
_Password text;
_CurrencyCode char(3);
_PaymentAmount numeric;
_PSPReference text;
_MerchantAccountID integer;
_NewPSPReference text;
_Response text;
_OK boolean;
BEGIN

-- There is only one merchant account so far
SELECT
    MerchantAccounts.PSP,
    MerchantAccounts.MerchantAccount,
    MerchantAccounts.URL,
    MerchantAccounts.Username,
    MerchantAccounts.Password,
    AuthoriseRequests.CurrencyCode,
    AuthoriseRequests.PaymentAmount,
    AuthoriseRequests.PSPReference
INTO STRICT
    _PSP,
    _MerchantAccount,
    _URL,
    _Username,
    _Password,
    _CurrencyCode,
    _PaymentAmount,
    _PSPReference
FROM MerchantAccounts
INNER JOIN AuthoriseRequests ON (AuthoriseRequests.MerchantAccountID = MerchantAccounts.MerchantAccountID)
WHERE AuthoriseRequests.AuthoriseRequestID = _AuthoriseRequestID;

SELECT
    Capture_Payment_Request.PSPReference,
    Capture_Payment_Request.Response
INTO STRICT
    _NewPSPReference,
    _Response
FROM Capture_Payment_Request(
    _PSP,
    _MerchantAccount,
    _URL,
    _Username,
    _Password,
    _CurrencyCode,
    _PaymentAmount,
    _PSPReference
);

INSERT INTO CaptureRequests (AuthoriseRequestID, PSPReference, Response)
VALUES (_AuthoriseRequestID, _NewPSPReference, _Response)
RETURNING TRUE INTO STRICT _OK;

RETURN TRUE;

END;
$BODY$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

REVOKE ALL ON FUNCTION Capture(_AuthoriseRequestID uuid) FROM PUBLIC;
GRANT  ALL ON FUNCTION Capture(_AuthoriseRequestID uuid) TO GROUP nonpci_api;
