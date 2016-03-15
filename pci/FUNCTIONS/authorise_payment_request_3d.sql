CREATE OR REPLACE FUNCTION Authorise_Payment_Request_3D(
OUT PSPReference text,
OUT ResultCode text,
OUT AuthCode integer,
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
DECLARE
_XMLRequest xml;
_XMLResponse xml;
BEGIN

IF _PSP = 'Adyen' THEN
    _XMLRequest := Format_Adyen_Authorise_Request_3D(
        _HTTP_ACCEPT,
        _HTTP_USER_AGENT,
        _MD,
        _MerchantAccount,
        _PaRes,
        _ShopperIP
    );
ELSE
    RAISE EXCEPTION 'ERROR_UNSUPPORTED_PSP %', _PSP;
END IF;

_XMLResponse := HTTP_POST_XML(_URL, _Username, _Password, _XMLRequest);

IF _PSP = 'Adyen' THEN
    SELECT
        Parse_Adyen_Authorise_Response_3D.PSPReference,
        Parse_Adyen_Authorise_Response_3D.ResultCode,
        Parse_Adyen_Authorise_Response_3D.AuthCode
    INTO STRICT
        Authorise_Payment_Request_3D.PSPReference,
        Authorise_Payment_Request_3D.ResultCode,
        Authorise_Payment_Request_3D.AuthCode
    FROM Parse_Adyen_Authorise_Response_3D(_XMLResponse);
ELSE
    RAISE EXCEPTION 'ERROR_UNSUPPORTED_PSP %', _PSP;
END IF;

RETURN;
END;
$BODY$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

REVOKE ALL ON FUNCTION Authorise_Payment_Request_3D(_PSP text, _MerchantAccount text, _URL text, _Username text, _Password text, _HTTP_ACCEPT text, _HTTP_USER_AGENT text, _MD text, _PaRes text, _ShopperIP inet) FROM PUBLIC;
GRANT  ALL ON FUNCTION Authorise_Payment_Request_3D(_PSP text, _MerchantAccount text, _URL text, _Username text, _Password text, _HTTP_ACCEPT text, _HTTP_USER_AGENT text, _MD text, _PaRes text, _ShopperIP inet) TO GROUP pci_api;
