CREATE OR REPLACE FUNCTION Cancel_Payment_Request(
OUT PSPReference text,
OUT Response text,
_PSP text,
_MerchantAccount text,
_URL text,
_Username text,
_Password text,
_PSPReference text
) RETURNS RECORD AS $BODY$
DECLARE
_XMLRequest xml;
_XMLResponse xml;
BEGIN

IF _PSP = 'Adyen' THEN
    _XMLRequest := Format_Adyen_Cancel_Request(
        _MerchantAccount,
        _URL,
        _Username,
        _Password,
        _PSPReference
    );
ELSE
    RAISE EXCEPTION 'ERROR_UNSUPPORTED_PSP %', _PSP;
END IF;

_XMLResponse := HTTP_POST_XML(_URL, _Username, _Password, _XMLRequest);

IF _PSP = 'Adyen' THEN
    SELECT
        Parse_Adyen_Cancel_Response.PSPReference,
        Parse_Adyen_Cancel_Response.Response
    INTO STRICT
        Cancel_Payment_Request.PSPReference,
        Cancel_Payment_Request.Response
    FROM Parse_Adyen_Cancel_Response(_XMLResponse);
ELSE
    RAISE EXCEPTION 'ERROR_UNSUPPORTED_PSP %', _PSP;
END IF;

RETURN;
END;
$BODY$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

REVOKE ALL ON FUNCTION Cancel_Payment_Request(_PSP text, _MerchantAccount text, _URL text, _Username text, _Password text, _PSPReference text) FROM PUBLIC;
GRANT  ALL ON FUNCTION Cancel_Payment_Request(_PSP text, _MerchantAccount text, _URL text, _Username text, _Password text, _PSPReference text) TO GROUP nonpci;
