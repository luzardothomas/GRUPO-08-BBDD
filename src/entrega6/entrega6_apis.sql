USE mundial_2026
GO;

IF SCHEMA_ID('apis') IS NULL EXEC('CREATE SCHEMA apis');
GO;

CREATE OR ALTER PROCEDURE apis.habilitar_ole_automation_procedures
AS
BEGIN
    EXEC sp_configure 'show advanced options', 1;
    EXEC sp_configure 'Ole Automation Procedures', 1;
    RECONFIGURE;
END
GO;

CREATE OR ALTER PROCEDURE apis.api_get
    @url VARCHAR(512),
    @respuesta VARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Object INT;
    DECLARE @errores VARCHAR(2000);
    DECLARE @json TABLE(DATA varchar(MAX)); --c

    DECLARE @status INT;
    DECLARE @statusText VARCHAR(255);

    EXEC sp_OACreate 'MSXML2.ServerXMLHTTP.6.0', @Object OUT;
    EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE';
    EXEC sp_OAMethod @Object, 'SEND'; 

    EXEC sp_OAGetProperty @Object, 'status', @status OUT;
    EXEC sp_OAGetProperty @Object, 'statusText', @statusText OUT;

    INSERT INTO @json
        EXEC sp_OAGetProperty @Object, 'RESPONSETEXT';

    SELECT @respuesta = DATA
    FROM @json;

    EXEC sp_OADestroy @Object;

    IF @status <> 200
    BEGIN
        SET @errores = 'API retorno codigo de estatus ' + CAST(@status AS CHAR(3));
        THROW 50003, @errores, 1;
    END;
END;

