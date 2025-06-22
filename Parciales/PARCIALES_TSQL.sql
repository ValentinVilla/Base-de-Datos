/*
25-06-2024

Dado el contexto inflacionario se tiene que aplicar un control en el cual:
nunca se permita vender un producto a un precio que no esté entre 0%-5% del
precio de venta del producto el mes anterior,
ni tampoco que esté en más de un 50% el precio del mismo producto que hace 
12 meses atrás. 
Aquellos productos nuevos, o que no tuvieron ventas en meses anteriores no 
debe considerar esta regla ya que no hay precio de referencia.
*/

CREATE TRIGGER ejParcial
ON Item_Factura
INSTEAD OF INSERT
AS
BEGIN
     DECLARE @tipo CHAR(1), @suc CHAR(4), @num CHAR(8),
            @prod CHAR(8), @precio DECIMAL(12,2), @cantidad DECIMAL(12,2)

    DECLARE items CURSOR FOR
    SELECT item_tipo, item_sucursal, item_numero,
           item_producto, item_precio, item_cantidad
    FROM INSERTED

    OPEN items
      FETCH NEXT FROM items INTO @tipo, @suc, @num, @prod, @precio, @cantidad

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @avg_last_month DECIMAL(12,2) = NULL,
                @avg_last_year DECIMAL(12,2) = NULL

        -- 1. Promedio mes anterior
        SELECT @avg_last_month = AVG(I.item_precio)
        FROM Item_Factura I
        JOIN Factura F ON F.fact_tipo+F.fact_sucursal+F.fact_numero=I.item_tipo+I.item_sucursal+I.item_numero
        WHERE I.item_producto = @prod
          AND F.fact_fecha >= DATEADD(month, -1, GETDATE()) 
          AND F.fact_fecha < GETDATE()

        -- 2. Promedio hace 12 meses
        SELECT @avg_last_year = AVG(I.item_precio)
        FROM Item_Factura I
        JOIN Factura F ON F.fact_tipo+F.fact_sucursal+F.fact_numero=I.item_tipo+I.item_sucursal+I.item_numero
        WHERE I.item_producto = @prod
          AND F.fact_fecha >= DATEADD(month, -12, GETDATE())
          AND F.fact_fecha < DATEADD(month, -11, GETDATE())

        -- 3. Validación
        IF (
             (@avg_last_month IS NOT NULL AND
                 (@precio < @avg_last_month * 0.95 OR @precio > @avg_last_month * 1.05))
             OR
             (@avg_last_year IS NOT NULL AND
                 @precio > @avg_last_year * 1.5)
           )
        BEGIN
            PRINT 'Precio fuera del rango permitido según inflación.'
            ROLLBACK
            RETURN
        END

        -- 4. Insertar finalmente
        INSERT INTO Item_Factura(item_tipo, item_sucursal, item_numero,
                                 item_producto, item_cantidad, item_precio)
        VALUES(@tipo, @suc, @num, @prod, @cantidad, @precio)

        FETCH NEXT FROM items INTO @tipo, @suc, @num, @prod, @precio, @cantidad
    END

    CLOSE items
    DEALLOCATE items
END
GO