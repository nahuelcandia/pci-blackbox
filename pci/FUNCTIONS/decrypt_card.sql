CREATE OR REPLACE FUNCTION Decrypt_Card(
OUT CardNumber text,
OUT CardExpiryMonth integer,
OUT CardExpiryYear integer,
OUT CardHolderName text,
OUT CardIssueNumber integer,
OUT CardStartMonth integer,
OUT CardStartYear integer,
_CardKey text
) RETURNS RECORD AS $BODY$
DECLARE
_CardKeyHash bytea;
_CardJSON text;
_CardData bytea;
_OK boolean;
BEGIN
_CardKeyHash := digest(_CardKey,'sha512');
SELECT CardData INTO STRICT _CardData FROM EncryptedCards
INNER JOIN CardNumberReferences ON (CardNumberReferences.CardNumberReference = EncryptedCards.CardNumberReference)
WHERE CardKeyHash = _CardKeyHash;
_CardJSON := pgp_sym_decrypt(_CardData,_CardKey);

SELECT
    Card_From_JSON.CardNumber,
    Card_From_JSON.CardExpiryMonth,
    Card_From_JSON.CardExpiryYear,
    Card_From_JSON.CardHolderName,
    Card_From_JSON.CardIssueNumber,
    Card_From_JSON.CardStartMonth,
    Card_From_JSON.CardStartYear
INTO STRICT
    Decrypt_Card.CardNumber,
    Decrypt_Card.CardExpiryMonth,
    Decrypt_Card.CardExpiryYear,
    Decrypt_Card.CardHolderName,
    Decrypt_Card.CardIssueNumber,
    Decrypt_Card.CardStartMonth,
    Decrypt_Card.CardStartYear
FROM Card_From_JSON(_CardJSON);

RETURN;
END;
$BODY$ LANGUAGE plpgsql VOLATILE;

REVOKE ALL ON FUNCTION Decrypt_Card(_CardKey text) FROM PUBLIC;
GRANT  ALL ON FUNCTION Decrypt_Card(_CardKey text) TO GROUP pci_api;
