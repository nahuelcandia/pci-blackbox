CREATE OR REPLACE FUNCTION Encrypt_CVC(
OUT CVCKey text,
_CardCVC text
) RETURNS TEXT AS $BODY$
DECLARE
_CVCKeyHash bytea;
_CVCData bytea;
_OK boolean;
_Expire interval := '10 minutes'::interval;
BEGIN

IF _CardCVC ~ '^[0-9]{3}$' THEN
    -- OK
ELSE
    RAISE EXCEPTION 'ERROR_INVALID_INPUT';
END IF;

CVCKey := encode(gen_random_bytes(32),'hex'); -- 32 bytes = 256 bits
_CVCKeyHash := digest(CVCKey,'sha512');
_CVCData := pgp_sym_encrypt(_CardCVC,CVCKey,'cipher-algo=aes256');

PERFORM memcache_server_add('localhost');
PERFORM memcache_set(encode(_CVCKeyHash,'hex'),encode(_CVCData,'hex'),_Expire);

RETURN;
END;
$BODY$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

REVOKE ALL ON FUNCTION Encrypt_CVC(_CardCVC text) FROM PUBLIC;
GRANT  ALL ON FUNCTION Encrypt_CVC(_CardCVC text) TO GROUP pci_api;
