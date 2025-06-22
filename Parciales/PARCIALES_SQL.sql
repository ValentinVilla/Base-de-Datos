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
