CREATE OR REPLACE FUNCTION Decrypt_CVC(
OUT CardCVC text,
_CVCKey text
) RETURNS TEXT AS $BODY$
DECLARE
_CVCKeyHash bytea;
_CVCData bytea;
_OK boolean;
BEGIN
_CVCKeyHash := digest(_CVCKey,'sha512');

PERFORM memcache_server_add('localhost');

_CVCData := decode(memcache_get(encode(_CVCKeyHash,'hex')),'hex');

PERFORM memcache_delete(encode(_CVCKeyHash,'hex'));

CardCVC := pgp_sym_decrypt(_CVCData,_CVCKey);

IF CardCVC ~ '^[0-9]{3,4}$' THEN
    -- OK
ELSE
    RAISE EXCEPTION 'ERROR_INVALID_CVC_KEY';
END IF;

RETURN;
END;
$BODY$ LANGUAGE plpgsql VOLATILE;

REVOKE ALL ON FUNCTION Decrypt_CVC(_CVCKey text) FROM PUBLIC;
GRANT  ALL ON FUNCTION Decrypt_CVC(_CVCKey text) TO GROUP pci_api;
