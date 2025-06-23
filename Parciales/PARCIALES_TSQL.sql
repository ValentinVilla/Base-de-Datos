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

CREATE TRIGGER ejParcial1
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

/*
25-06-2024

La compañia cumple años y decidió a repartir algunas sorpresas entre sus
clientes. Se pide crear el/los objetos necesarios para que se imprima un cupón
con la leyenda "Recuerde solicitar su regalo sorpresa en su próxima compra" a
los clientes que, entre los productos comprados, hayan adquirido algún producto
de los siguientes rubros: PILAS y PASTILLAS y tengan un limite crediticio menor
a $ 15000.
*/

CREATE TRIGGER ejParcial2
ON Item_Factura
AFTER INSERT
AS
BEGIN
    DECLARE @cliente_id INT
    DECLARE @producto_rubro VARCHAR(50)
    DECLARE @limite_credito DECIMAL(12,2)

    DECLARE items CURSOR FOR
    SELECT DISTINCT C.clie_codigo, P.prod_rubro, C.clie_limite_credito
    FROM inserted
    JOIN Producto P ON item_producto = P.prod_codigo
    JOIN Factura F ON F.fact_tipo + F.fact_sucursal + F.fact_numero = item_tipo + item_sucursal + item_numero
    JOIN Cliente C ON F.fact_cliente = C.clie_codigo
    WHERE P.prod_rubro IN ('PILAS', 'PASTILLAS')
      AND C.clie_limite_credito < 15000

    OPEN items
    FETCH NEXT FROM items INTO @cliente_id, @producto_rubro, @limite_credito

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'Recuerde solicitar su regalo sorpresa en su próxima compra'
        FETCH NEXT FROM items INTO @cliente_id, @producto_rubro, @limite_credito
    END

    CLOSE items
    DEALLOCATE items
END
GO

/*
La compañía desea implementar una política para incrementar el consumo de
ciertos productos. Se pide crear el/los objetos necesarios para que se imprima
un cupón con la leyenda "Ud. accederá a un 5% de descuento del total de su
próxima factura" a los clientes que realicen compras superiores a los $5000 y
que entre los productos comprados haya adquirido algún producto de los
siguientes rubros:
· PILAS
· PASTILLAS
· ARTICULOS DE TOCADOR
*/

CREATE TRIGGER ejPArcial3
ON Item_Factura
AFTER INSERT
AS
BEGIN
    DECLARE @cliente_id INT
    DECLARE @total_factura DECIMAL(12,2)
    DECLARE @producto_rubro VARCHAR(50)

    DECLARE items CURSOR FOR
    SELECT clie_codigo, SUM(item_precio * item_cantidad) AS total_factura
    FROM inserted 
    JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
    JOIN Cliente ON fact_cliente = clie_codigo
    JOIN Producto ON item_producto = prod_codigo
    WHERE prod_rubro IN ('PILAS', 'PASTILLAS', 'ARTICULOS DE TOCADOR')
    GROUP BY clie_codigo
    HAVING SUM(item_precio * item_cantidad) > 5000

    OPEN items
    FETCH NEXT FROM items INTO @cliente_id, @total_factura

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'Ud. accederá a un 5% de descuento del total de su próxima factura'
        FETCH NEXT FROM items INTO @cliente_id, @total_factura
    END

    CLOSE items
    DEALLOCATE items
END
GO
