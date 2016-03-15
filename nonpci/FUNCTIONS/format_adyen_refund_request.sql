CREATE OR REPLACE FUNCTION Format_Adyen_Refund_Request(
_MerchantAccount text,
_URL text,
_Username text,
_Password text,
_CurrencyCode char(3),
_PaymentAmount numeric,
_PSPReference text
) RETURNS xml AS $BODY$
DECLARE
BEGIN

RETURN xmlelement(
    name "soap:Envelope",
    xmlattributes(
        'http://schemas.xmlsoap.org/soap/envelope/' AS "xmlns:soap",
        'http://www.w3.org/2001/XMLSchema' AS "xmlns:xsd",
        'http://www.w3.org/2001/XMLSchema-instance' AS "xmlns:xsi"
    ),
    xmlelement(
        name "soap:Body",
        xmlelement(
            name "ns1:refund",
            xmlattributes('http://payment.services.adyen.com' AS "xmlns:ns1"),
            xmlelement(
                name "ns1:modificationRequest",
                xmlelement(
                    name "merchantAccount",
                    xmlattributes('http://payment.services.adyen.com' AS "xmlns"),
                    _MerchantAccount
                ),
                xmlelement(
                    name "modificationAmount",
                    xmlattributes('http://payment.services.adyen.com' AS "xmlns"),
                    xmlelement(
                        name "currency",
                        xmlattributes('http://common.services.adyen.com' AS "xmlns"),
                        _CurrencyCode
                    ),
                    xmlelement(
                        name "value",
                        xmlattributes('http://common.services.adyen.com' AS "xmlns"),
                        _PaymentAmount
                    )
                ),
                xmlelement(
                    name "originalReference",
                    xmlattributes('http://payment.services.adyen.com' AS "xmlns"),
                    _PSPReference
                )
            )
        )
    )
);
END;
$BODY$ LANGUAGE plpgsql;

REVOKE ALL ON FUNCTION Format_Adyen_Refund_Request(_MerchantAccount text, _URL text, _Username text, _Password text, _CurrencyCode char(3), _PaymentAmount numeric, _PSPReference text) FROM PUBLIC;
GRANT  ALL ON FUNCTION Format_Adyen_Refund_Request(_MerchantAccount text, _URL text, _Username text, _Password text, _CurrencyCode char(3), _PaymentAmount numeric, _PSPReference text) TO GROUP nonpci_api;
