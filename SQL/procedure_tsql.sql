-- El proceso para crear una tabla de historificación podría calcularse ejecutando el siguiente procedure cada vez que
-- se ejecute (añadir o modificar) algún elemento de la tabla staging de precios.

CREATE PROCEDURE HistorificarPrecios
AS
BEGIN
    -- Iniciar una transacción para garantizar la consistencia de los datos
    BEGIN TRANSACTION;

    -- Insertar los nuevos registros de staging en la tabla de historificación.
    INSERT INTO FACT_PRECIOS (fecha_inicio_vigencia, fecha_fin_vigencia, id_articulo, precio_coste, precio_venta)
    SELECT
        GETDATE() AS fecha_inicio_vigencia,
        NULL AS fecha_fin_vigencia,
        s.id_articulo,
        s.precio_coste,
        s.precio_venta
    FROM
        STG_PRECIOS s
    LEFT JOIN
        FACT_PRECIOS h ON s.id_articulo = h.id_articulo
                              AND s.precio_coste = h.precio_coste
                              AND s.precio_venta = h.precio_venta
                              AND h.fecha_vigencia_fin IS NULL
    WHERE
        h.id_articulo IS NULL;

    -- Actualizar fecha fin de vigencia existentes en la tabla de historificación para los artículos con precios modificados.
    UPDATE
        FACT_PRECIOS
    SET
        fecha_fin_vigencia = DATEADD(DAY, -1, GETDATE())
    FROM
        FACT_PRECIOS h
    INNER JOIN
        STG_PRECIOS s ON h.id_articulo = s.id_articulo
    WHERE
        (h.precio_coste <> s.precio_coste
        OR h.precio_venta <> s.precio_venta)
        AND h.fecha_vigencia_fin IS NULL;


    -- Una vez el registro anterior esta completo con un precio modificado y la fecha de vigencia del precio anterior
    -- Insertar nuevos registros para los artículos con precios modificados ya existentes en historificación.
    INSERT INTO FACT_PRECIOS (fecha_inicio_vigencia, fecha_fin_vigencia, id_articulo, precio_coste, precio_venta)
    SELECT
        GETDATE() AS fecha_inicio_vigencia,
        NULL AS fecha_fin_vigencia,
        s.id_articulo,
        s.precio_coste,
        s.precio_venta
    FROM
        staging_precios s
    LEFT JOIN
        historico_precios h ON s.id_articulo = h.id_articulo
                              AND s.precio_coste = h.precio_coste
                              AND s.precio_venta = h.precio_venta
                              AND h.fecha_vigencia_fin IS NOT NULL
    WHERE
        h.id_articulo IS NULL;


    -- Confirmar la transacción
    COMMIT TRANSACTION;
END;
