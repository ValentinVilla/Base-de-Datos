/*
1.  Hacer una función que dado un artículo y un deposito devuelva un string que
    indique el estado del depósito según el artículo. 
    Si la cantidad almacenada es menor al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el
    % de ocupación. Si la cantidad almacenada es mayor o igual al límite retornar
    “DEPOSITO COMPLETO”
*/
CREATE FUNCTION estado_deposito(@articulo char(8), @deposito char(2))
RETURNS varchar(50)
AS
BEGIN
    DECLARE @stock numeric(12,2)
    DECLARE @limite numeric(12,2)

    SELECT @stock = isnull(stoc_cantidad,0), @limite = isnull(stoc_stock_maximo,0)
    FROM STOCK
    WHERE stoc_producto = @articulo AND stoc_deposito = @deposito

    IF(@stock >= @limite)
        RETURN 'DEPOSITO COMPLETO'

    RETURN 'OCUPACION DEL DEPOSITO ' +@deposito + ' ' + STR(@stock/@limite*100,5,2) + '%'
END    
GO

--SELECT estado_deposito('00000030','03')

--drop function reporte_stock

/*
2. Realizar una función que dado un artículo y una fecha, retorne el stock que
existía a esa fecha
*/

CREATE FUNCTION reporte_stock(@articulo char(8), @fecha smalldatetime)
RETURNS varchar(50)
AS
BEGIN
    DECLARE @stock_actual DECIMAL(12,2)
    DECLARE @vendido_despues DECIMAL(12,2)
    DECLARE @stock_fecha DECIMAL(12,2)

    -- Paso 1: obtener el stock actual del artículo (sumando de todos los depósitos)
    SELECT @stock_actual = SUM(stoc_cantidad)
    FROM STOCK
    WHERE stoc_producto = @articulo

    -- Paso 2: calcular lo que se vendió **después** de la fecha dada
    SELECT @vendido_despues = SUM(I.item_cantidad)
    FROM Item_Factura I
        JOIN Factura F ON F.fact_tipo+F.fact_sucursal+F.fact_numero = I.item_tipo +I.item_sucursal+I.item_numero
    WHERE I.item_producto = @articulo
        AND F.fact_fecha > @fecha

    -- Si no se vendió nada después, poner 0
    SET @vendido_despues = ISNULL(@vendido_despues, 0)

    -- Paso 3: stock a la fecha = stock actual + lo que se vendió después
    SET @stock_fecha = @stock_actual + @vendido_despues

    RETURN 'STOCK EN ' + CONVERT(varchar, @fecha, 120) + ' fue de ' + CAST(@stock_fecha AS varchar(20))

END
GO

--SELECT dbo.reporte_stock('00000030', '2011-06-01') as stoc_enfecha

--drop function reporte_stock

/*
3. Cree el/los objetos de base de datos necesarios para corregir la tabla empleado
    en caso que sea necesario. 
    Se sabe que debería existir un único gerente general (debería ser el único empleado sin jefe).
    Si detecta que hay más de un empleado sin jefe deberá elegir entre ellos el gerente general, 
    el cual será seleccionado por mayor salario. 
    Si hay más de uno se seleccionara el de mayor antigüedad en la
    empresa. 
    Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla
    de un único empleado sin jefe (el gerente general) y deberá retornar la cantidad
    de empleados que había sin jefe antes de la ejecución.
*/

CREATE PROCEDURE corregir_tabla_empleados
    @cantidad int OUTPUT
AS
BEGIN
    declare @jefe numeric(6)
    select @jefe = (select top 1
            empl_codigo
        from Empleado
        where empl_jefe is null
        ORDER BY empl_salario desc, empl_ingreso asc)
    select @cantidad = count(*)
    from empleado
    where empl_jefe is null
    print @cantidad
    if @cantidad > 1
        update empleado set empl_jefe = @jefe where empl_jefe is null and empl_codigo <> @jefe
    return

END
GO

BEGIN
    declare @cant INT
    select @cant = 0
    exec dbo.corregir_tabla_empleados @cant
    print @cant
end

select count(*)
from empleado
where empl_jefe is NULL
update empleado set empl_jefe = null where empl_jefe = 1 
GO
-- drop PROCEDURE corregir_tabla_empleados

/*
    4. Cree el/los objetos de base de datos necesarios para --->
    -actualizar la columna de empleado empl_comision con la sumatoria del total 
     de lo vendido por ese empleado a lo largo del último año.
    -Se deberá retornar el código del vendedor
     que más vendió (en monto) a lo largo del último año.
*/
CREATE PROCEDURE actualizar_col_empl
    @vend numeric(6) OUTPUT
AS
BEGIN
    UPDATE Empleado SET empl_comision = (select isnull(sum(fact_total),0)
    from Factura
    where empl_codigo = fact_vendedor
        AND YEAR(fact_fecha) = (select max(year(fact_fecha))
        from Factura))
    set @vend = (select top 1
        empl_codigo
    from empleado
    order by empl_comision desc)
    RETURN
END
GO

select *
from Empleado
update Empleado set empl_comision = 0

declare @vend numeric(6)
exec dbo.actualizar_col_empl @vend output
select @vend 
GO
/*
5. Realizar un procedimiento que complete con los datos existentes en el modelo
    provisto la tabla de hechos denominada Fact_table tiene las siguiente definición:

    Create table Fact_table
    ( anio char(4),
    mes char(2),
    familia char(3),
    rubro char(4),
    zona char(3),
    cliente char(6),
    producto char(8),
    cantidad decimal(12,2),
    monto decimal(12,2)
    )
    Alter table Fact_table
    Add constraint primary key(anio,mes,familia,rubro,zona,cliente,producto)

*/

select *
from dbo.Fact_table

create table dbo.Fact_table
(
    anio char(4) NOT NULL,
    mes char(2) NOT NULL,
    familia char(3) NOT NULL,
    rubro char(4) NOT NULL,
    zona char(3) NOT NULL,
    cliente char(6) NOT NULL,
    producto char(8) NOT NULL,
    cantidad decimal(12,2) NOT NULL,
    monto decimal(12,2) NOT NULL
);
Alter table Fact_table
Add constraint PK_fact_table primary key(anio,mes,familia,rubro,zona,cliente,producto)
GO

CREATE PROCEDURE ej5
AS
BEGIN
    DELETE FROM dbo.fact_table
    INSERT INTO dbo.fact_table
        (anio,mes,familia,rubro,zona,cliente,producto,cantidad, monto)
    SELECT DISTINCT year(fact_fecha), month(fact_fecha), prod_familia, prod_rubro, depa_zona,
        fact_cliente, prod_codigo, sum(item_cantidad), sum(item_precio*item_cantidad)
    FROM Factura JOIN Item_Factura ON fact_tipo+fact_sucursal+fact_numero=item_tipo+item_sucursal+item_numero
        JOIN Producto ON prod_codigo = item_producto
        JOIN Empleado ON empl_codigo = fact_vendedor
        JOIN Departamento ON depa_codigo = empl_departamento
    GROUP BY year(fact_fecha), month(fact_fecha), prod_familia, prod_rubro, prod_codigo, depa_zona, fact_cliente
END
GO

exec dbo.ej5
go

/*
6.  Realizar un procedimiento que si en alguna factura se facturaron componentes
    que conforman un combo determinado (o sea que juntos componen otro
    producto de mayor nivel), en cuyo caso deberá reemplazar las filas
    correspondientes a dichos productos por una sola fila con el producto que
    componen con la cantidad de dicho producto que corresponda.
*/

CREATE PROCEDURE ej6
AS
BEGIN
    DECLARE @tipo CHAR(1), @sucursal CHAR(4), @numero INT
    DECLARE @combo CHAR(8)
    DECLARE @cantidad_combos INT

    DECLARE cursor_facturas CURSOR FOR SELECT DISTINCT item_tipo, item_sucursal, item_numero
    FROM Item_Factura
    OPEN cursor_facturas

    FETCH NEXT FROM cursor_facturas INTO @tipo, @sucursal, @numero

    WHILE @@FETCH_STATUS = 0

    BEGIN
        -- Cursor que recorre todos los combos posibles
        DECLARE cursor_combos CURSOR FOR
            SELECT DISTINCT comp_producto
        FROM Composicion

        OPEN cursor_combos
        FETCH NEXT FROM cursor_combos INTO @combo

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Paso 1: calcular cuántos combos se pueden formar en esta factura
            SELECT @cantidad_combos = MIN(FLOOR(1.0 * I.item_cantidad / C.comp_cantidad))
            FROM Composicion C
                JOIN Item_Factura I
                ON I.item_producto = C.comp_componente
            WHERE C.comp_producto = @combo
                AND I.item_tipo = @tipo
                AND I.item_sucursal = @sucursal
                AND I.item_numero = @numero

            IF @cantidad_combos >= 1
            BEGIN
                -- Paso 2: eliminar los componentes de la factura
                DELETE FROM Item_Factura
                WHERE item_tipo = @tipo AND item_sucursal = @sucursal AND item_numero = @numero
                    AND item_producto IN (
                      SELECT comp_componente
                    FROM Composicion
                    WHERE comp_producto = @combo
                  )

                IF EXISTS (
                 SELECT 1
                FROM Factura
                WHERE fact_tipo = @tipo
                    AND fact_sucursal = @sucursal
                    AND fact_numero = @numero
                )
                BEGIN
                    INSERT INTO Item_Factura
                        (item_tipo, item_sucursal, item_numero, item_producto, item_cantidad)
                    VALUES
                        (@tipo, @sucursal, @numero, @combo, @cantidad_combos);
                END
            END
            FETCH NEXT FROM cursor_combos INTO @combo
        END
        CLOSE cursor_combos
        DEALLOCATE cursor_combos

        FETCH NEXT FROM cursor_facturas INTO @tipo, @sucursal, @numero;
    END
    CLOSE cursor_facturas
    DEALLOCATE cursor_facturas
END
GO

/*
7.  Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. Debe
    insertar una línea por cada artículo con los movimientos de stock generados por
    las ventas entre esas fechas. La tabla se encuentra creada y vacía.
    seindo la tabl:
    -codigo (codigo dl articulo)
    -detalle (detalle del articulo)
    -cant_mov (Cantidad de movimientos de ventas (Item factura))
    -precio_venta (Precio promedio de venta)
    -renglon (Nro. de linea de la tabla)
    -ganancia (precio de venta - cantidad * costo actual)
*/

SELECT TOP 1000
    *
-- entonces hay 22 facturas entre esas fechas
FROM Factura
WHERE fact_fecha BETWEEN '2012-01-01' AND '2012-01-02';

exec dbo.ej7 '2012-01-01', '2012-01-02';
-- luego de ejecutar dbo.ventas tiene 128 filas, pues era por cada artículo vendido

select *
from dbo.ventas

create table dbo.ventas
(
    codigo char(8),
    detalle char(50),
    cant_mov BIGINT,
    precio_venta BIGINT,
    renglon INT,
    ganancia BIGINT
);
GO

CREATE PROCEDURE ej7
    @fechaDesde smalldatetime,
    @fechaHasta smalldatetime
AS
BEGIN
    INSERT INTO VENTAS
        (
        codigo,
        detalle,
        cant_mov,
        precio_venta,
        renglon,
        ganancia
        )
    SELECT
        I.item_producto,
        P.prod_detalle,
        COUNT(*) AS cantidad_movimientos,
        AVG(I.item_precio) AS precio_promedio,
        ROW_NUMBER() OVER (ORDER BY I.item_producto) AS renglon,
        AVG(I.item_precio) - (I.item_cantidad * P.prod_precio) AS ganancia
    FROM Item_Factura I
        JOIN Factura F
        ON F.fact_tipo = I.item_tipo
            AND F.fact_sucursal = I.item_sucursal
            AND F.fact_numero = I.item_numero
        JOIN Producto P ON P.prod_codigo = I.item_producto
    WHERE F.fact_fecha BETWEEN @fechaDesde AND @fechaHasta
    GROUP BY I.item_producto, P.prod_detalle, P.prod_precio, 
             I.item_cantidad
END
GO

/*
8.  Realizar un procedimiento que complete la tabla Diferencias de precios, para los
    productos facturados que tengan composición y en los cuales el precio de
    facturación sea diferente al precio del cálculo de los precios unitarios por
    cantidad de sus componentes, se aclara que un producto que compone a otro,
    también puede estar compuesto por otros y así sucesivamente, la tabla se debe
    crear y está formada por las siguientes columnas:
    -Código (Código del artículo)
    -Detalle (Detalle del artículo)
    -Cantidad (Cantidad de productos que conforman el combo)
    -Precio_generado (Precio que se compone a través de sus componentes)
    -Precio_facturado (precio del producto)
*/
select *
from Diferencias

DROP table diferencias
drop procedure ej8
drop FUNCTION precio_compuesto

exec dbo.ej8

create table dbo.Diferencias
(
    codigo char(8),
    detalle char(50),
    cantidad BIGINT,
    precio_generado BIGINT,
    precio_facturado INT
);
GO

CREATE FUNCTION precio_compuesto (@prod CHAR(8))
RETURNS decimal(12,2)
AS
BEGIN
    DECLARE @precio_producto decimal(12,2), @comp char(8), @cantidad decimal(12,2)
    if (select count(*)
    from composicion
    where comp_producto = @prod) = 0
        select @precio_producto = (select prod_precio
        from producto
        where prod_codigo = @prod)
        else
        BEGIN
        DECLARE compo cursor for select comp_componente, comp_cantidad
        from composicion
            JOIN producto on prod_codigo = comp_componente
        WHERE comp_producto = @prod
        OPEN compo
        FETCH NEXT FROM compo INTO @comp, @cantidad
        select @precio_producto = 0
        WHILE @@FETCH_STATUS = 0
            BEGIN
            SELECT @precio_producto = @precio_producto + @cantidad * dbo.precio_compuesto(@comp)
            FETCH compo into @comp, @cantidad
        END
        CLOSE compo
        DEALLOCATE compo
    END
    RETURN @precio_producto
END
GO

CREATE PROCEDURE ej8
AS
BEGIN
    INSERT INTO dbo.Diferencias
        (
        codigo,
        detalle,
        cantidad,
        precio_generado,
        precio_facturado
        )
    SELECT
        prod_codigo,
        prod_detalle,
        (select count(*)
        from composicion
        where comp_producto = prod_codigo) as precio_generado,
        dbo.precio_compuesto(item_producto),
        item_precio
    FROM Item_Factura
        JOIN Producto ON item_producto = prod_codigo
        JOIN composicion on item_producto = comp_producto
    where item_precio <> dbo.precio_compuesto(item_producto)
    group by prod_codigo, item_producto, prod_detalle, item_precio
    RETURN
END
GO

/*
9.  Crear el/los objetos de base de datos que ante alguna modificación de un ítem de
    factura de un artículo con composición realice el movimiento de sus
    correspondientes componentes.
*/

CREATE TRIGGER ej9
ON Item_Factura
FOR INSERT, DELETE
AS
BEGIN
    DECLARE @compo char(8), @cantidad decimal(12,2), @depo char(2)
    if (select count(*)
    from inserted) > 0
        BEGIN
        DECLARE c1 CURSOR FOR SELECT comp_componente, comp_cantidad*item_cantidad
        FROM inserted JOIN composicion ON item_producto = comp_producto
        OPEN c1
        FETCH c1 INTO @compo, @cantidad
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SELECT @depo = (SELECT TOP 1
                    stoc_deposito
                FROM stock
                WHERE stoc_producto = @compo
                ORDER BY stoc_cantidad DESC)
            if @depo is null
                BEGIN
                print 'No hay stock del producto'
                close c1
                deallocate c1
                ROLLBACK
            END
            else 
                UPDATE stock SET stoc_Cantidad = stoc_cantidad - @cantidad WHERE stoc_producto = @compo AND stoc_deposito = @depo
            FETCH c1 INTO @compo, @cantidad
        END
    END
     ELSE
        BEGIN
        DECLARE c1 CURSOR FOR SELECT comp_componente, comp_cantidad*item_cantidad
        FROM deleted JOIN composicion ON item_producto = comp_producto
        OPEN c1
        FETCH c1 INTO @compo, @cantidad
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SELECT @depo = (SELECT TOP 1
                    stoc_deposito
                FROM stock
                WHERE stoc_producto = @compo
                ORDER BY stoc_cantidad DESC)
            if @depo is null
                BEGIN
                print 'No hay stock del producto'
                close c1
                deallocate c1
                ROLLBACK
            END
            else 
                UPDATE stock SET stoc_Cantidad = stoc_cantidad + @cantidad WHERE stoc_producto = @compo AND stoc_deposito = @depo
            FETCH c1 INTO @compo, @cantidad
        END
    END
    CLOSE c1
    DEALLOCATE c1
END
GO

/*
10. Crear el/los objetos de base de datos que ante el intento de borrar un artículo
    verifique que no exista stock y si es así lo borre en caso contrario que emita un
    mensaje de error.
*/
CREATE TRIGGER ej10 ON producto 
INSTEAD OF DELETE
AS
BEGIN
    if (select count(*)
    from stock join deleted on stoc_producto = prod_codigo) > 0 
        print 'No se puede borrar porque tiene stock'  
    else 
        delete producto where prod_codigo in (select prod_codigo
    from deleted)
END
GO

/*
11. Cree el/los objetos de base de datos necesarios para que dado un código de
    empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o
    indirectamente). Solo contar aquellos empleados (directos o indirectos) que
    tengan un código mayor que su jefe directo.
*/

CREATE FUNCTION calcular_cant_empleados(@empleado numeric(6,0))
RETURNS INT
AS
BEGIN
    DECLARE @cantidad int
    DECLARE @emp_jefe numeric(6,0)
    DECLARE @emp_codigo numeric (6,0)

    SET @cantidad = 0

    IF NOT EXISTS(SELECT *
    FROM Empleado
    WHERE @empleado = empl_jefe)
    BEGIN
        RETURN @cantidad
    END

    -- cantidad de empleados que tiene directamente a su cargo
    SET @cantidad = (SELECT COUNT(*)
    FROM Empleado
    WHERE @empleado = empl_jefe AND empl_codigo > empl_jefe)

    -- cantidad de empleados que tiene indirectamente a su cargo
    DECLARE cursorEmp CURSOR FOR SELECT empl_jefe, empl_codigo
    FROM Empleado
    WHERE @empleado = empl_jefe
    OPEN cursorEmp
    FETCH NEXT FROM cursorEmp into @emp_jefe, @emp_codigo
    WHILE @@FETCH_STATUS = 0
    BEGIN
        set @cantidad = @cantidad + dbo.calcular_cant_empleados(@emp_codigo)
        FETCH NEXT FROM cursorEmp into @emp_jefe, @emp_codigo
    END
    CLOSE cursorEmp
    DEALLOCATE cursorEmp
    RETURN @cantidad
END
GO

/*
12. Cree el/los objetos de base de datos necesarios para que nunca un producto
    pueda ser compuesto por sí mismo.Se sabe que en la actualidad dicha regla se
    cumple y que la base de datos es accedida por 'n' aplicaciones de diferentes tipos
    y tecnologías. No se conoce la cantidad de niveles de composición existentes.
*/

CREATE FUNCTION dbo.Ejercicio12Func(@producto CHAR(8),@Componente char(8))
RETURNS int
AS
BEGIN
    IF @producto = @Componente 
		RETURN 1
	ELSE
		BEGIN
        DECLARE @ProdAux char(8)
        DECLARE cursor_componente CURSOR FOR SELECT comp_componente
        FROM Composicion
        WHERE comp_producto = @Componente
        OPEN cursor_componente
        FETCH NEXT from cursor_componente INTO @ProdAux
        WHILE @@FETCH_STATUS = 0
			BEGIN
            IF dbo.Ejercicio12Func(@producto,@prodaux) = 1
					RETURN 1
            FETCH NEXT from cursor_componente INTO @ProdAux
        END
        CLOSE cursor_componente
        DEALLOCATE cursor_componente
        RETURN 0
    END
    RETURN 0
END
GO

CREATE TRIGGER ej12
ON Composicion
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    IF ((SELECT COUNT(*)
    FROM DELETED) = 0)
		IF ((SELECT COUNT(*)
    FROM INSERTED
    WHERE dbo.Ejercicio12Func(comp_producto,comp_componente) = 1) > 0)  -- ACA ME FIJO SI ALGUNO NO CUMPLE LA REGLA
			PRINT 'No puede ingresarse un producto compuesto por si mismo'
		ELSE
			INSERT Composicion
    SELECT *
    FROM Inserted
    WHERE dbo.Ejercicio12Func(comp_producto,comp_componente) = 0  -- ACA METO LOS QUE CUMPLEN LA REGLA
	ELSE
-- se crea otro cursor igual para deleted
		BEGIN
        DECLARE @productodel char(8)
        DECLARE @componentedel char(8)
        DECLARE @cantidaddel decimal (12,2)
        DECLARE cur_productosdel CURSOR FOR SELECT comp_cantidad, comp_producto, comp_componente
        FROM deleted
        DECLARE @producto char(8)
        DECLARE @componente char(8)
        DECLARE @cantidad decimal (12,2)
        DECLARE cur_productos CURSOR FOR SELECT comp_cantidad, comp_producto, comp_componente
        FROM inserted
        OPEN cur_productosdel
        OPEN cur_productos
        FETCH NEXT FROM cur_productosdel INTO @cantidaddel, @productodel, @componentedel
        FETCH NEXT FROM cur_productos INTO @cantidad, @producto, @componente
        -- avanzan juntos
        WHILE @@FETCH_STATUS = 0
		BEGIN
            -- me fijo si cumple la condicion 
            IF dbo.Ejercicio12Fun(@producto,@componente) = 1
				PRINT 'No puede moficarse un producto compuesto por si mismo'
			ELSE
				BEGIN
                -- hago el update borrando y cargando
                -- borro el viejo
                DELETE Composicion WHERE comp_producto = @productodel and comp_componente = @componentedel
                -- inserto el nuevo
                insert composicion
                values(@producto, @componente, @cantidad)
            END
            -- avanzan los dos cursores juntos
            FETCH NEXT FROM cur_productosdel INTO @cantidaddel, @productodel, @componentedel
            FETCH NEXT FROM cur_productos INTO @cantidad, @producto, @componente
        END
        CLOSE cur_productosdel
        DEALLOCATE cur_productosdel
        CLOSE cur_productos
        DEALLOCATE cur_productos
    END
END
GO

/*
14. Agregar el/los objetos necesarios para que: 
    si un cliente compra un producto compuesto a un precio menor que la suma de los 
    precios de sus componentes ==> imprima la fecha, que cliente, que productos y a
    qué precio se realizó la compra.
    No se deberá permitir que dicho precio sea menor a la mitad de la suma de los componentes.
*/
CREATE TRIGGER ej14
ON Item_Factura
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @producto char(8)
    DECLARE @precio decimal(12,2)
    DECLARE @cantidad decimal(12,2)
    DECLARE @fecha smalldatetime, @cliente char(6)
    DECLARE @tipo char, @sucursal  char(4), @numero char(8)

    DECLARE cursorProd CURSOR FOR SELECT item_tipo, item_sucursal, item_numero, item_producto,
        item_precio, item_cantidad
    FROM Inserted
    OPEN cursorProd
    FETCH NEXT FROM cursorProd INTO @tipo, @sucursal, @numero, @producto, @cantidad, @precio
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF(@PRECIO < dbo.precio_compuesto (@producto) / 2)
            BEGIN
            DELETE FROM Item_factura WHERE item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@numero
            DELETE FROM Factura WHERE fact_tipo+fact_sucursal+fact_numero = @tipo+@sucursal+@numero
            PRINT 'El precio no puede ser menor a la mitad'
        END
        ELSE
            BEGIN
            INSERT item_factura
            VALUES(@tipo, @sucursal, @numero, @producto, @cantidad, @precio)
            PRINT 'FECHA: ' +@fecha + ' CLIENTE: '+ @CLIENTE + 'PRECIO: ' + @PRECIO + 'PRODUCTO: ' + @PRODUCTO
        END
        FETCH NEXT FROM cursorProd INTO @tipo, @sucursal, @numero, @producto, @precio, @cantidad
    END
    CLOSE cursorProd
    DEALLOCATE cursosProd
END
GO

/*
16. Desarrolle el/los elementos de base de datos necesarios para que ante una venta
    automaticamante se descuenten del stock los articulos vendidos. Se descontaran
    del deposito que mas producto poseea y se supone que el stock se almacena
    tanto de productos simples como compuestos (si se acaba el stock de los
    compuestos no se arman combos)
    En caso que no alcance el stock de un deposito se descontara del siguiente y asi
    hasta agotar los depositos posibles. En ultima instancia se dejara stock negativo
    en el ultimo deposito que se desconto.
*/

CREATE TRIGGER EJ16
ON ITEM_FACTURA
AFTER INSERT, DELETE
AS
BEGIN
    DECLARE @PRODUCTO CHAR(8), @CANTIDAD DECIMAL(12,2)
    IF (SELECT COUNT(*)
    FROM INSERTED) > 0
    	DECLARE ITEMS CURSOR 
        	FOR
        	SELECT item_producto, item_cantidad
    FROM inserted
    ELSE 
    	DECLARE ITEMS CURSOR 
        	FOR
        	SELECT item_producto, item_cantidad*(-1)
    FROM deleted
    OPEN ITEMS
    FETCH ITEMS INTO @PRODUCTO, @CANTIDAD
    WHILE @@FETCH_STATUS=0
	BEGIN
        DECLARE @DEPO CHAR(2), @CANT_DEPO DECIMAL(12,2)
        DECLARE @ULTIMO_DEPO CHAR(2)
        DECLARE @CANT_DESCONTAR DECIMAL(12,2)

        DECLARE DEPOS CURSOR
	    	FOR --DEPOSITOS DONDE TIENE STOCK Y SU CANTIDAD
    		SELECT stoc_deposito, stoc_cantidad
        FROM STOCK
        WHERE stoc_producto = @PRODUCTO
        ORDER BY stoc_cantidad DESC
        OPEN DEPOS
        FETCH DEPOS INTO @DEPO, @CANT_DEPO
        SET @ULTIMO_DEPO = @DEPO
        SET @CANT_DESCONTAR=@CANTIDAD
        WHILE @@FETCH_STATUS=0 AND (@CANT_DESCONTAR != 0)
			BEGIN
            IF (@CANT_DEPO >= @CANT_DESCONTAR) -- ENTRA EN UN SOLO DEPOSITO
					BEGIN
                UPDATE STOCK SET stoc_cantidad = (@CANT_DEPO-@CANT_DESCONTAR) WHERE stoc_producto=@PRODUCTO AND @DEPO=stoc_deposito
                SET @CANT_DESCONTAR = 0
                BREAK
            END
					ELSE -- NO ENTRA EN UN SOLO DEPOSITO, EL STOCK PASA A 0 Y BUSCO OTRO DEPOSITO 
					BEGIN
                UPDATE STOCK SET stoc_cantidad =0 WHERE stoc_producto=@PRODUCTO AND @DEPO=stoc_deposito
                FETCH DEPOS INTO @DEPO, @CANT_DEPO
                SET @ULTIMO_DEPO = @DEPO
                SET @CANT_DESCONTAR = @CANT_DESCONTAR - @CANT_DEPO
            END
        END
        --ES EL ULTIMO DEPOSITO, PUEDE SER NEGATIVO
        IF @ULTIMO_DEPO IS NULL
                BEGIN
            PRINT 'NO HAY STOCK DEL PRODUCTO'
            ROLLBACK
        END
        IF (@CANT_DESCONTAR !=0) -- SALE DEL WHILE Y ENTRA ACA
				BEGIN
            UPDATE STOCK SET stoc_cantidad = (@CANT_DEPO-@CANT_DESCONTAR) 
                    WHERE stoc_producto=@PRODUCTO AND stoc_deposito=@ULTIMO_DEPO
        END
        CLOSE DEPOS
        DEALLOCATE DEPOS
    END
    FETCH ITEMS INTO @PRODUCTO, @CANTIDAD
    END
	CLOSE ITEMS
	DEALLOCATE ITEMS  
END
		
/*
19. Cree el/los objetos de base de datos necesarios para que se cumpla la siguiente
    regla de negocio automáticamente “Ningún jefe puede tener menos de 5 años de
    antigüedad y tampoco puede tener más del 50% del personal a su cargo
    (contando directos e indirectos) a excepción del gerente general”. Se sabe que en
    la actualidad la regla se cumple y existe un único gerente general.
*/



