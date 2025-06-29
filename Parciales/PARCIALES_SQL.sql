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

/*
Dada la crisis que atraviesa la empresa, el directorio solicita un informe especial
para poder analizar y definir la nueva estrategia a adoptar.
Este informe consta de un listado de aquellos productos cuyas ventas de lo que
va del año 2012 fueron superiores al 15% del promedio de ventas de los
productos vendidos entre los años 2010 y 2011.
En base a lo solicitado, armar una consulta SQL que retorne la siguiente
información:

1. Detalle del producto
2. Mostrar la leyenda "Popular" si dicho producto figura en más de 100
facturas realizadas en el 2012. Caso contrario, mostrar la leyenda "Sin
interés".
3. Cantidad de facturas en las que aparece el producto en el año 2012.
4. Código del cliente que más compró dicho producto en el 2012. (en caso
de existir más de un cliente, mostrar solamente el de menor código)

NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas
por el usuario para este punto.
*/

SELECT p1.prod_detalle,
       CASE WHEN (
            SELECT COUNT(fact_tipo + fact_sucursal + fact_numero) FROM Factura f2
            JOIN Item_Factura i2 ON f2.fact_tipo + f2.fact_sucursal + f2.fact_numero = i2.item_tipo + i2.item_sucursal + i2.item_numero
            WHERE i2.item_producto = p1.prod_codigo 
              AND YEAR(f2.fact_fecha) = 2012
        ) > 100 THEN 'Popular'
                  ELSE 'Sin interés' END AS prod_popularidad,
       (SELECT COUNT(fact_tipo + fact_sucursal + fact_numero) FROM Factura f2
        JOIN Item_Factura i2 ON f2.fact_tipo + f2.fact_sucursal + f2.fact_numero = i2.item_tipo + i2.item_sucursal + i2.item_numero
        WHERE i2.item_producto = p1.prod_codigo 
          AND YEAR(f2.fact_fecha) = 2012
       ) AS cant_facturas,
       (SELECT TOP 1 clie_codigo FROM Cliente
        JOIN Factura ON clie_codigo = fact_cliente
        JOIN Item_Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
        WHERE item_producto = p1.prod_codigo AND YEAR(fact_fecha) = 2012
        GROUP BY clie_codigo
        ORDER BY SUM(item_cantidad) DESC, clie_codigo ASC ) AS cod_cliente_mas_compro
FROM Producto p1
JOIN Item_Factura i1 ON p1.prod_codigo = i1.item_producto
JOIN Factura f1 ON i1.item_tipo + i1.item_sucursal + i1.item_numero = f1.fact_tipo + f1.fact_sucursal + f1.fact_numero
GROUP BY prod_codigo, prod_detalle, item_producto
HAVING SUM(i1.item_cantidad) > 
      (SELECT 0.15 * AVG(i3.item_cantidad)
       FROM Item_Factura i3
       JOIN Factura f3 ON i3.item_tipo+i3.item_sucursal+i3.item_numero = f3.fact_tipo+f3.fact_sucursal+f3.fact_numero
       WHERE YEAR(f3.fact_fecha) IN (2010, 2011)
         AND i3.item_producto = i1.item_producto)


/*
MI PARCIAL - 

Realizar una consulta SQL que retorne para el último año, los 5 vendedores con menos
clientes asignados, que más vendieron en pesos (si hay varios con menos clientes
asignados debe traer el que más vendió), solo deben considerarse las facturas que
tengan más de dos items facturados:
1) Apellido y Nombre del Vendedor.
2) Total de unidades de Producto Vendidas.
3) Monto promedio de venta por factura.
4) Monto total de ventas.

El resultado deberá mostrar ordenado la cantidad de ventas descendente, en caso de
igualdad de cantidades, ordenar por código de vendedor.

NOTA: No se permite el uso de sub-selects en el FROM.
*/

SELECT TOP 5 
	rtrim(empl_apellido) + ' ' + rtrim(empl_nombre) AS NombreYApellido,
	SUM(item_cantidad)as totalUnidades,
	AVG(item_cantidad*item_precio) as montoPromedio,
	SUM(item_cantidad*item_precio) as montoTotal
FROM Empleado
JOIN Factura ON fact_vendedor = empl_codigo
JOIN Item_Factura ON item_tipo+item_sucursal+item_numero=fact_tipo+fact_sucursal+fact_numero
WHERE YEAR(fact_fecha) = (SELECT TOP 1 YEAR(fact_fecha) FROM Factura ORDER BY 1 DESC)
GROUP BY empl_apellido, empl_nombre, fact_vendedor
HAVING COUNT(item_tipo+item_sucursal+item_numero) > 2
ORDER BY COUNT(distinct fact_cliente) ASC, 
         SUM(fact_total) DESC,
         COUNT(fact_tipo+fact_sucursal+fact_numero) DESC,
         fact_vendedor


/*
Se requiere armar una estadística que retorne para cada año y familia, el cliente que
menos productos diferentes compro y que más monto compro para ese año y familia

Año, Razón Social Cliente, Familia, Cantidad de unidades compradas de esa familia

Los resultados deben ser ordenados por año de menor a mayor y para cada año
ordenados por la familia que menos productos tenga asignados

NOTA: No se permite el uso de sub-selects en el FROM.
*/
SELECT YEAR(fact_fecha) AS Año,
       clie_razon_social,
       fami_detalle,
       SUM(item_cantidad) AS CantidadUnidadesCompradas
FROM Cliente
JOIN Factura ON clie_codigo = fact_cliente
JOIN Item_Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
JOIN Producto ON item_producto = prod_codigo
JOIN Familia ON prod_familia = fami_id
GROUP BY YEAR(fact_fecha), clie_razon_social, fami_detalle
HAVING COUNT(DISTINCT item_producto) IN (
    SELECT TOP 1 COUNT(DISTINCT item_producto)
    FROM Cliente c2
    JOIN Factura f2 ON c2.clie_codigo = f2.fact_cliente
    JOIN Item_Factura i2 ON f2.fact_tipo + f2.fact_sucursal + f2.fact_numero = i2.item_tipo + i2.item_sucursal + i2.item_numero
    JOIN Producto p2 ON i2.item_producto = p2.prod_codigo
    WHERE YEAR(f2.fact_fecha) = YEAR(fact_fecha)
      AND p2.prod_familia = prod_familia
    GROUP BY c2.clie_codigo
    ORDER BY COUNT(DISTINCT item_producto) ASC
)
ORDER BY Año, 
         fami_detalle, 
         CantidadUnidadesCompradas DESC

------------------

SELECT 
    YEAR(f.fact_fecha) AS anio,
    c.clie_razon_social,
    p.prod_familia,
    SUM(i.item_cantidad) AS total_unidades
FROM Factura f
JOIN Item_Factura i 
  ON f.fact_tipo = i.item_tipo 
 AND f.fact_sucursal = i.item_sucursal 
 AND f.fact_numero = i.item_numero
JOIN Producto p ON p.prod_codigo = i.item_producto
JOIN Cliente c ON c.clie_codigo = f.fact_cliente
GROUP BY 
    YEAR(f.fact_fecha), 
    f.fact_cliente, 
    c.clie_razon_social, 
    p.prod_familia
HAVING 
    f.fact_cliente = (
        SELECT TOP 1 f2.fact_cliente
        FROM Factura f2
        JOIN Item_Factura i2 ON f2.fact_tipo = i2.item_tipo 
                             AND f2.fact_sucursal = i2.item_sucursal 
                             AND f2.fact_numero = i2.item_numero
        JOIN Producto p2 ON p2.prod_codigo = i2.item_producto
        WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)
          AND p2.prod_familia = p.prod_familia
        GROUP BY f2.fact_cliente
        ORDER BY 
            COUNT(DISTINCT i2.item_producto) ASC,
            SUM(i2.item_cantidad * i2.item_precio) DESC
    )
ORDER BY 
    YEAR(f.fact_fecha) ASC,
    (SELECT COUNT(*) FROM Producto p3 WHERE p3.prod_familia = p.prod_familia) ASC;


/*
Realizar una consulta SQL que retorne para los 10 clientes que más
compraron en el 2012 y que fueron atendidos por más de 3 vendedores
distintos:

· Apellido y Nombre del Cliente.
· Cantidad de Productos distintos comprados en el 2012.
· Cantidad de unidades compradas dentro del primer semestre del 2012.

El resultado deberá mostrar ordenado la cantidad de ventas descendente
del 2012 de cada cliente, en caso de igualdad de ventas, ordenar por
código de cliente.

NOTA: No se permite el uso de sub-selects en el FROM ni funciones
definidas por el usuario para este punto.
*/

SELECT TOP 10
  c1.clie_razon_social AS apellido_y_nombre,

  (SELECT COUNT(DISTINCT i1.item_producto) 
   FROM Item_Factura i1
   JOIN Factura f1 ON f1.fact_tipo + f1.fact_sucursal + f1.fact_numero = i1.item_tipo + i1.item_sucursal + i1.item_numero
   WHERE f1.fact_cliente = c1.clie_codigo 
   AND YEAR(f1.fact_fecha) = 2012
   ) AS cant_prod_comp_2012,

  (SELECT SUM(i2.item_cantidad) 
   FROM Item_Factura i2
   JOIN Factura f2 ON f2.fact_tipo + f2.fact_sucursal + f2.fact_numero = i2.item_tipo + i2.item_sucursal + i2.item_numero
   WHERE f2.fact_cliente = c1.clie_codigo 
   AND YEAR(f2.fact_fecha)= 2012 
   AND MONTH(f2.fact_fecha) BETWEEN 1 AND 6
   ) AS cant_prod_comp_primer_sem_2012
FROM Cliente c1
WHERE (SELECT COUNT(DISTINCT f3.fact_vendedor)
       FROM Factura f3
       WHERE f3.fact_cliente = c1.clie_codigo
       AND YEAR(f3.fact_fecha) = 2012
       ) > 3
ORDER BY
  -- Ordenar por total vendido en 2012 DESC, luego por código
    (SELECT SUM(i3.item_cantidad*i3.item_precio)
     FROM Factura f3
     JOIN Item_Factura i3 ON f3.fact_tipo + f3.fact_sucursal + f3.fact_numero = i3.item_tipo + i3.item_sucursal + i3.item_numero
     WHERE f3.fact_cliente = c1.clie_codigo
       AND YEAR(f3.fact_fecha) = 2012
    ) DESC,
    c1.clie_codigo ASC;

-- Devuelve cero filas, pero creo que esta bien ya que no hay clientes con mas de 3 vendedores distintos en 2012
