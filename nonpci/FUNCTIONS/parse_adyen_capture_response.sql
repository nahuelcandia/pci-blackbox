CREATE OR REPLACE FUNCTION Parse_Adyen_Capture_Response(
OUT PSPReference text,
OUT Response text,
_XML xml
) RETURNS RECORD AS $BODY$
DECLARE
_ xml[];
_BasePath text;
_NSArray text[];
BEGIN
_NSArray := ARRAY[
    ['soap', 'http://schemas.xmlsoap.org/soap/envelope/'],
    ['xsd','http://www.w3.org/2001/XMLSchema'],
    ['xsi','http://www.w3.org/2001/XMLSchema-instance'],
    ['ns1','http://payment.services.adyen.com']
];

_BasePath := '/soap:Envelope/soap:Body/ns1:captureResponse/ns1:captureResult/ns1:';

PSPReference  := (xpath(_BasePath || 'pspReference/text()', _XML,_NSArray))[1]::text;
Response      := (xpath(_BasePath || 'response/text()',     _XML,_NSArray))[1]::text;

RETURN;
END;
$BODY$ LANGUAGE plpgsql;
