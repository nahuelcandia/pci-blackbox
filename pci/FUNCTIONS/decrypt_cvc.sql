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
RETURN;
END;
$BODY$ LANGUAGE plpgsql VOLATILE;
