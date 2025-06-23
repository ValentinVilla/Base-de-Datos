/*
25-06-2024

Sabiendo que si un producto no es vendido en un depósito determinado entonces
no posee registros en él.
Se requiere una consulta sql que para todos los productos que se quedaron sin
stock en un depósito (cantidad 0 o nula) y poseen un stock mayor al punto de
reposición en otro deposito devuelva:

1- Código de producto
2- Detalle del producto
3- Domicilio del depósito sin stock
4- Cantidad de depósitos con un stock superior al punto de reposición

La consulta debe ser ordenada por el código de producto.

NOTA: No se permite el uso de sub-selects en el FROM.
*/

SELECT p.prod_codigo, 
       p.prod_detalle,
       d1.depo_domicilio,
       (select count(*) from stock s2
        where s2.stoc_producto = p.prod_codigo 
        and s2.stoc_cantidad > s2.stoc_punto_reposicion)  AS cantidad_depositos_con_stock      
FROM Producto p
JOIN Stock s1 ON p.prod_codigo = s1.stoc_producto
JOIN Deposito d1 ON d1.depo_codigo = s1.stoc_deposito
WHERE ISNULL(s1.stoc_cantidad, 0) = 0  AND (SELECT COUNT(*)
                                            FROM Stock s3
                                            WHERE s3.stoc_producto = p.prod_codigo
                                            AND s3.stoc_cantidad > s3.stoc_punto_reposicion
                                            AND s3.stoc_deposito <> s1.stoc_deposito
                                            ) >= 1
ORDER BY p.prod_codigo 


/*
La empresa está muy comprometida con el desarrollo sustentable, y como
consecuencia de ello propone cambiar los envases de sus productos por
envases reciclados. Si bien entiende la importancia de este cambio, también es
consciente de los costos que esto conlleva por lo cual se realizará de manera
paulatina.

Por tal motivo se solicita un listado con los 5 productos más vendidos y los 5
productos menos vendidos durante el 2012. Comparar la cantidad vendida de
cada uno de estos productos con la cantidad vendida del año anterior e indicar
el string 'Más ventas' o 'Menos ventas', según corresponda. Además indicar el
envase.

A) Producto
B) Comparación año anterior
C) Detalle de Envase
*/
-- top 5 mas vendidos
SELECT TOP 5 prod_codigo,
             prod_detalle,
             CASE WHEN (
                        SELECT SUM(i2.item_cantidad) FROM Item_Factura i2
                        JOIN Factura f2 ON i2.item_tipo + i2.item_sucursal + i2.item_numero = f2.fact_tipo + f2.fact_sucursal + f2.fact_numero
                        WHERE i2.item_producto = i1.item_producto 
                        AND YEAR(f2.fact_fecha) = 2011
                  ) < SUM(i1.item_cantidad) THEN 'Más ventas'
                  ELSE 'Menos ventas' END AS comparacion,
             prod_envase
FROM Producto
JOIN Item_Factura i1 ON prod_codigo = i1.item_producto
JOIN Factura f1 ON i1.item_tipo + i1.item_sucursal + i1.item_numero = f1.fact_tipo + f1.fact_sucursal + f1.fact_numero
WHERE YEAR(f1.fact_fecha) = 2012
GROUP BY prod_codigo, prod_detalle, prod_envase, i1.item_producto
ORDER BY ISNULL(SUM(i1.item_cantidad), 0) DESC

-- top 5 menos vendidos (solo cambia el ORDER BY)
SELECT TOP 5 prod_codigo,
             prod_detalle,
             CASE WHEN (
                        SELECT SUM(i2.item_cantidad) FROM Item_Factura i2
                        JOIN Factura f2 ON i2.item_tipo + i2.item_sucursal + i2.item_numero = f2.fact_tipo + f2.fact_sucursal + f2.fact_numero
                        WHERE i2.item_producto = i1.item_producto 
                        AND YEAR(f2.fact_fecha) = 2011
                  ) < SUM(i1.item_cantidad) THEN 'Más ventas'
                  ELSE 'Menos ventas' END AS comparacion,
             prod_envase
FROM Producto
JOIN Item_Factura i1 ON prod_codigo = i1.item_producto
JOIN Factura f1 ON i1.item_tipo + i1.item_sucursal + i1.item_numero = f1.fact_tipo + f1.fact_sucursal + f1.fact_numero
WHERE YEAR(f1.fact_fecha) = 2012
GROUP BY prod_codigo, prod_detalle, prod_envase, i1.item_producto
ORDER BY ISNULL(SUM(i1.item_cantidad), 0) ASC , prod_detalle


/*
En pos de la mejora continua y poder optimizar el uso de los depósitos, se le pide
un informe con la siguiente información:

a) El depósito
b) El domicilio del depósito
c) Cantidad de productos compuestos con stock
d) Cantidad de productos no compuestos con stock
e) Indicar un string "Mayoría compuestos", en caso de que el
depósito tenga mayor cantidad de productos compuestos o
"Mayoría no compuestos", caso contrario.
f) Empleado más joven de todos los depósitos.

Solamente mostrar aquellos depósitos donde la cantidad total de productos en
stock este entre 0 y 1000.
*/
SELECT depo_codigo,
       depo_domicilio,
       (SELECT sum(stoc_cantidad) FROM STOCK
        JOIN Composicion ON stoc_producto = comp_producto
        WHERE stoc_deposito = depo_codigo) AS cant_prod_compuestos,
       (SELECT sum(stoc_cantidad) FROM STOCK
        WHERE stoc_producto NOT IN (SELECT comp_producto FROM Composicion
                                    JOIN Stock s2 on s2.stoc_producto = comp_producto
                                    WHERE s2.stoc_deposito = depo_codigo)
        AND stoc_deposito = depo_codigo) AS cant_prod_no_compuestos,
        CASE 
            WHEN 
                (SELECT COUNT(*) 
                 FROM Stock s
                 JOIN Composicion c ON s.stoc_producto = c.comp_producto
                 WHERE s.stoc_deposito = depo_codigo AND ISNULL(s.stoc_cantidad, 0) > 0
                ) >
                (SELECT COUNT(*) 
                 FROM Stock s
                 WHERE s.stoc_deposito = depo_codigo 
                   AND s.stoc_producto NOT IN (SELECT comp_producto FROM Composicion
                                               JOIN Stock s2 on s2.stoc_producto = comp_producto
                                               WHERE s2.stoc_deposito = depo_codigo)
                   AND ISNULL(s.stoc_cantidad, 0) > 0
                )
            THEN 'Mayoría compuestos'
            ELSE 'Mayoría no compuestos'
        END AS mayoria,
        (SELECT TOP 1 empl_nombre FROM Empleado
         WHERE depo_encargado = empl_codigo
         ORDER BY empl_nacimiento DESC) as empleado_mas_joven
FROM DEPOSITO
JOIN STOCK ON depo_codigo = stoc_deposito
GROUP BY depo_codigo, depo_domicilio, depo_encargado
HAVING SUM(ISNULL(stoc_cantidad, 0)) BETWEEN 1 AND 1000

