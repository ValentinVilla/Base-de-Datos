/*
1. Mostrar el c�digo, raz�n social de todos los clientes cuyo l�mite de cr�dito sea mayor o
     igual a $ 1000 ordenado por c�digo de cliente.
*/

SELECT clie_codigo, clie_razon_social FROM Cliente
where clie_limite_credito >=1000
order by clie_codigo

/*
2. Mostrar el c�digo, detalle de todos los art�culos vendidos en el a�o 2012 ordenados por
     cantidad vendida.
*/

SELECT item_producto, prod_detalle 
from Item_Factura join Producto on item_producto = prod_codigo 
join Factura on fact_tipo+fact_sucursal+fact_numero=item_tipo+item_sucursal+item_numero
where year(fact_fecha) = 2012
group by item_producto, prod_detalle
order by sum(item_cantidad)

/*
3. Realizar una consulta que muestre c�digo de producto, nombre de producto y el stock
    total, sin importar en que deposito se encuentre, los datos deben ser ordenados por
    nombre del art�culo de menor a mayor
*/
select prod_codigo, prod_detalle, sum(isnull(stoc_cantidad,0)) stoc_total
from Producto left join STOCK on prod_codigo = stoc_producto
group by prod_codigo, prod_detalle
order by prod_detalle

/*
4. Realizar una consulta que muestre para todos los art�culos c�digo, detalle y cantidad de
    art�culos que lo componen. Mostrar solo aquellos art�culos para los cuales el stock
    promedio por dep�sito sea mayor a 100.
*/

select prod_codigo, prod_detalle,  count(distinct comp_componente)
from Producto left join Composicion on prod_codigo = comp_producto 
join STOCK on stoc_producto = prod_codigo
group by prod_codigo, prod_detalle
having(avg(stoc_cantidad)) > 100


select prod_codigo, prod_detalle, count(comp_componente)
from producto left join Composicion on prod_codigo = comp_producto 
group by prod_codigo, prod_detalle
having prod_codigo in (select stoc_producto from stock group by stoc_producto having avg(stoc_Cantidad) > 100)

/*
5. Realizar una consulta que muestre c�digo de art�culo, detalle y cantidad de egresos de
    stock que se realizaron para ese art�culo en el a�o 2012 (egresan los productos que
    fueron vendidos). Mostrar solo aquellos que hayan tenido m�s egresos que en el 2011.
*/

select prod_codigo, prod_detalle, sum(item_cantidad) cantidad_egresos
from Producto 
join Item_Factura on prod_codigo = item_producto 
join Factura on fact_tipo+fact_sucursal+fact_numero=item_tipo+item_sucursal+item_numero
where year(fact_fecha) = 2012
group by prod_codigo, prod_detalle
having sum(item_cantidad)  >  (select sum(item_cantidad) from Item_Factura 
join Factura on fact_tipo+fact_sucursal+fact_numero=item_tipo+item_sucursal+item_numero
where year(fact_fecha) = 2011 and item_producto = prod_codigo)
order by prod_codigo


/*
6. Mostrar para todos los rubros de art�culos c�digo, detalle, cantidad de art�culos de ese
    rubro y stock total de ese rubro de art�culos. Solo tener en cuenta aquellos art�culos que
    tengan un stock mayor al del art�culo �00000000� en el dep�sito �00�.
*/

SELECT rubr_id, rubr_detalle, count(distinct prod_codigo), sum(isnull(stoc_cantidad,0))
FROM RUBRO left join Producto on prod_rubro = rubr_id and prod_codigo in (select stoc_producto from stock group by stoc_producto having sum(stoc_cantidad) >
(select isnull(stoc_cantidad,0) from stock where stoc_producto = '00000000' and stoc_deposito = '00'))
left join stock on prod_codigo = stoc_producto 
group by rubr_id, rubr_detalle
order by 4 

/*
7. Generar una consulta que muestre para cada artículo código, detalle, mayor precio
menor precio y % de la diferencia de precios (respecto del menor Ej.: menor precio =
10, mayor precio =12 => mostrar 20 %). Mostrar solo aquellos artículos que posean
stock.
*/

SELECT prod_codigo, prod_detalle, max(item_precio) as maximo_precio, min(item_precio) as minimo_precio,
    ((max(item_precio) - min(item_precio)) * 100 / min(item_precio)) as diferencia_de_precios
FROM Producto
JOIN Item_Factura ON item_producto = prod_codigo
JOIN STOCK ON stoc_producto = prod_codigo
group by prod_codigo, prod_detalle
having sum(stoc_cantidad) > 1
ORDER by 1


/*
8. Mostrar para el o los artículos que tengan stock en todos los depósitos, nombre del
artículo, stock del depósito que más stock tiene.
*/

select prod_detalle, max(stoc_cantidad)
from producto join stock on prod_codigo = stoc_producto
where stoc_cantidad > 0
group by prod_detalle 
having count(*) = (select count(*) from deposito)


/*
9. Mostrar el código del jefe, código del empleado que lo tiene como jefe, nombre del
mismo y la cantidad de depósitos que ambos tienen asignados.
*/

select 
    empl_jefe, 
    empl_codigo, 
    rtrim(empl_apellido)+' '+rtrim(empl_nombre),
    count(depo_codigo) AS cantidad_depositos_asignados
FROM Empleado
LEFT JOIN DEPOSITO on empl_codigo = depo_encargado
GROUP by empl_jefe, empl_codigo, rtrim(empl_apellido)+' '+rtrim(empl_nombre)

/*
10. Mostrar los 10 productos más vendidos en la historia y también los 10 productos menos
vendidos en la historia. Además mostrar de esos productos, quien fue el cliente que
mayor compra realizo.
*/

select prod_codigo, 
       prod_detalle,
       (select top 1 fact_cliente 
        from Factura
        join Item_Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
        where prod_codigo = item_producto
        group by fact_cliente
        order by sum(item_cantidad) DESC
        ) as cliente_que_mas_compro
from Producto
where prod_codigo in (select top 10 item_producto
                      from Item_Factura
                      group by item_producto
                      order by sum(item_cantidad) ASC
                      )
   or prod_codigo in (select top 10 item_producto
                      from Item_Factura
                      group by item_producto
                      order by sum(item_cantidad) DESC
                      )

/*
11. Realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de
productos vendidos y el monto de dichas ventas sin impuestos. Los datos se deberán
ordenar de mayor a menor, por la familia que más productos diferentes vendidos tenga,
solo se deberán mostrar las familias que tengan una venta superior a 20000 pesos para
el año 2012.
*/

select fami_detalle,
       count(distinct prod_codigo),
       sum(isnull(item_precio*item_cantidad,0)) as precio_ventas_sin_impuestos
from Familia
join Producto on prod_familia = fami_id
Join Item_Factura on item_producto = prod_codigo
where fami_id in (select prod_familia from Producto
                  join Item_Factura on prod_codigo = item_producto
                  join Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
                  where year(fact_fecha) = 2012
                  group by prod_familia
                  having sum(item_precio*item_cantidad) > 20000)
group by fami_id, fami_detalle
order by 2

-- se puede usar having en vez de where
select fami_detalle, count(distinct prod_codigo), sum(isnull(item_precio*item_cantidad,0))
from familia join Producto on fami_id = prod_familia join Item_Factura on prod_codigo = item_producto
group by fami_id, fami_detalle
having fami_id in 
(select prod_familia from producto join item_factura on item_producto = prod_codigo
                   join factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
where year(fact_fecha) = 2012 
group by prod_familia
having sum(item_cantidad*item_precio) > 20000)
order by 2

/*
12. Mostrar nombre de producto, cantidad de clientes distintos que lo compraron, importe
promedio pagado por el producto,cantidad de depósitos en los cuales hay stock del
producto y stock actual del producto en todos los depósitos. 

Se deberán mostrar aquellos productos que hayan tenido operaciones en el año 2012 y los datos deberán
ordenarse de mayor a menor por monto vendido del producto.
*/

select prod_detalle,
       count(distinct fact_cliente) as clientes_que_compraron,
       avg(item_precio) as promedio_pagado_producto,
       (select count(stoc_deposito) from stock where stoc_producto = prod_codigo) as cant_depo_hay_stock_producto,
       (select sum(stoc_cantidad) from STOCK where stoc_producto = prod_codigo) as stoc_actual_todos_depositos
from Producto
join Item_Factura on prod_codigo = item_producto
join Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
where prod_codigo in (select item_producto from Item_Factura 
                      join Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
                      where year(fact_fecha) = 2012)
group by prod_codigo, prod_detalle
order by sum(item_precio * item_cantidad) DESC

/*
13. Realizar una consulta que retorne para cada producto que posea composición nombre
del producto, precio del producto, precio de la sumatoria de los precios por la cantidad
de los productos que lo componen. Solo se deberán mostrar los productos que estén
compuestos por más de 2 productos y deben ser ordenados de mayor a menor por
cantidad de productos que lo componen.
*/

select p1.prod_detalle,
       p1.prod_precio, 
       sum(p2.prod_precio*comp_cantidad)  
from composicion 
join producto p1 on p1.prod_codigo = comp_producto 
join producto p2 on p2.prod_codigo = comp_componente
group by p1.prod_detalle, p1.prod_precio
having count(comp_componente) >= 2
order by count(comp_componente) DESC

/*
14. Escriba una consulta que retorne una estadística de ventas por cliente. Los campos que
debe retornar son:

Código del cliente
Cantidad de veces que compro en el último año
Promedio por compra en el último año
Cantidad de productos diferentes que compro en el último año
Monto de la mayor compra que realizo en el último año

Se deberán retornar todos los clientes ordenados por la cantidad de veces que compro en
el último año.
No se deberán visualizar NULLs en ninguna columna
*/

select clie_codigo,
       count(fact_numero) as cant_compro_ult_anio,
       avg(isnull(fact_total,0)) as promedio_compra_ult_anio,
       (select count(distinct item_producto) from Item_Factura 
        join factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
        where fact_cliente = clie_codigo
        and year(fact_fecha) = (Select max(year(fact_fecha))from factura)) as cant_prod_dif_comp_ult_anio,
        max(isnull(fact_total,0)) as monto_mayor_comp_ult_anio
from Cliente
left join Factura on clie_codigo = fact_cliente
and year(fact_fecha) = (Select max(year(fact_fecha))from factura)
group by clie_codigo
order by 2

/*
15. Escriba una consulta que retorne los pares de productos que hayan sido vendidos juntos
(en la misma factura) más de 500 veces. El resultado debe mostrar el código y
descripción de cada uno de los productos y la cantidad de veces que fueron vendidos
juntos. El resultado debe estar ordenado por la cantidad de veces que se vendieron
juntos dichos productos. Los distintos pares no deben retornarse más de una vez.

Ejemplo de lo que retornaría la consulta:

PROD1 DETALLE1 PROD2 DETALLE2 VECES
1731 MARLBORO KS 1 7 1 8 P H ILIPS MORRIS KS 5 0 7
1718 PHILIPS MORRIS KS 1 7 0 5 P H I L I P S MORRIS BOX 10 5 6 2
*/

SELECT 
    a.item_producto AS prod1_codigo,
    p1.prod_detalle AS prod1_detalle,
    b.item_producto AS prod2_codigo,
    p2.prod_detalle AS prod2_detalle,
    COUNT(*) AS veces_vendidos_juntos
FROM Item_Factura a
JOIN Item_Factura b ON a.item_tipo+a.item_sucursal+a.item_numero = b.item_tipo+b.item_sucursal+b.item_numero
JOIN Producto p1 ON a.item_producto = p1.prod_codigo
JOIN Producto p2 ON b.item_producto = p2.prod_codigo
where a.item_producto < b.item_producto
GROUP BY a.item_producto, p1.prod_detalle, b.item_producto, p2.prod_detalle
HAVING COUNT(*) > 500
ORDER BY veces_vendidos_juntos DESC

/*
16. Con el fin de lanzar una nueva campaña comercial para los clientes que menos compran
en la empresa, se pide una consulta SQL que retorne aquellos clientes cuyas compras
son inferiores a 1/3 del monto de ventas del producto que más se vendió en el 2012.
Además mostrar

1. Nombre del Cliente
2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
3. Código de producto que mayor venta tuvo en el 2012 (en caso de existir más de 1,
mostrar solamente el de menor código) para ese cliente. 

*/
SELECT clie_razon_social,
       SUM(ISNULL(item_cantidad,0)) AS unidades_vendidas_al_cliente_en_2012,
       ISNULL((SELECT TOP 1 item_producto FROM Item_Factura JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
               WHERE clie_codigo = fact_cliente AND YEAR(fact_fecha) = 2012
               GROUP BY item_producto
               ORDER BY sum(item_cantidad) DESC, item_producto), 'Ninguno') AS prod_mayor_venta_en_2012_del_cliente
FROM Cliente JOIN Factura ON clie_codigo = fact_cliente
JOIN Item_Factura ON item_tipo+item_sucursal+item_numero=fact_tipo+fact_sucursal+fact_numero
GROUP BY clie_codigo, clie_razon_social
HAVING isnull((select sum(fact_total - fact_total_impuestos) from factura where fact_cliente = clie_codigo),0) <
        (select top 1 sum(item_precio*item_cantidad) from item_factura join factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero   
                                                where year(fact_fecha) = 2012
                                                group by item_producto
                                                order by sum(item_cantidad) desc) / 3


/*
17. Escriba una consulta que retorne una estadística de ventas por año y mes para cada
producto, La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por periodo y código de producto.
La consulta debe retornar:

PERIODO: Año y mes de la estadística con el formato YYYYMM
PROD: Código de producto
DETALLE: Detalle del producto
CANTIDAD_VENDIDA= Cantidad vendida del producto en el periodo
VENTAS_AÑO_ANT= Cantidad vendida del producto en el mismo mes del periodo
pero del año anterior
CANT_FACTURAS= Cantidad de facturas en las que se vendió el producto en el
periodo

*/
SELECT str(year(f1.fact_fecha),4)+right('00'+ltrim(str(MONTH(f1.fact_fecha),2)),2) as periodo,
       prod_codigo,
       prod_detalle,
       sum(i1.item_cantidad) as cantidad_vendida,
       isnull((SELECT sum(i2.item_cantidad) from factura f2 
        join Item_Factura i2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
        where year(f1.fact_fecha) = year(f2.fact_fecha)+1 and MONTH(f1.fact_fecha) = month(f2.fact_fecha) and prod_codigo = i2.item_producto),0)as cantidad_vendida_año_anterior,
        count(distinct i1.item_tipo+i1.item_sucursal+i1.item_numero)as cant_facturas
FROM Factura f1 
JOIN Item_Factura i1 on f1.fact_tipo+f1.fact_sucursal+f1.fact_numero = i1.item_tipo+i1.item_sucursal+i1.item_numero
JOIN Producto on item_producto = prod_codigo
group by year(f1.fact_fecha),Month(f1.fact_fecha), prod_codigo, prod_detalle
order by 1, prod_codigo

/*
18. Escriba una consulta que retorne una estadística de ventas para todos los rubros.La consulta no
puede mostrar NULL en ninguna de sus columnas y debe estar ordenada por cantidad de productos diferentes 
vendidos del rubro.
La consulta debe retornar:

DETALLE_RUBRO: Detalle del rubro
VENTAS: Suma de las ventas en pesos de productos vendidos de dicho rubro
PROD1: Código del producto más vendido de dicho rubro
PROD2: Código del segundo producto más vendido de dicho rubro
CLIENTE: Código del cliente que compro más productos del rubro en los últimos 30
días
*/

SELECT rubr_detalle as detalle_rubro,
       isnull((SELECT sum(item_precio*item_cantidad) FROM Item_Factura 
               join Producto on prod_codigo = item_producto
               where prod_rubro = rubr_id
              ),0) as ventas,
       isnull(p1.prod_codigo,0) as prod1,
       isnull(p2.prod_codigo,0) as prod2,
       isnull((SELECT TOP 1 fact_cliente FROM Factura 
               JOIN Item_Factura ON item_tipo+item_sucursal+item_numero=fact_tipo+fact_sucursal+fact_numero
               JOIN Producto ON prod_codigo = item_producto
               WHERE prod_rubro = rubr_id AND fact_fecha >= DATEADD(DAY, -30, GETDATE())
               GROUP BY fact_cliente    
               ORDER BY SUM(item_cantidad) DESC),'Nadie') as cod_clie_mas_compro
FROM Rubro LEFT JOIN Producto p1 ON rubr_id = p1.prod_rubro AND p1.prod_codigo = (SELECT TOP 1 prod_codigo
                                                                                  FROM Producto
                                                                                  JOIN Item_Factura ON prod_codigo = item_producto
                                                                                  WHERE prod_rubro = rubr_id
                                                                                  GROUP BY prod_codigo
                                                                                  ORDER BY SUM(item_cantidad) DESC)

LEFT JOIN Producto p2 ON rubr_id = p2.prod_rubro AND p2.prod_codigo = (SELECT TOP 1 prod_codigo FROM Producto 
                                                                       JOIN Item_Factura on prod_codigo = item_producto
                                                                       WHERE prod_rubro = rubr_id AND prod_codigo <> p1.prod_codigo
                                                                       GROUP BY prod_codigo
                                                                       ORDER BY SUM(item_cantidad) DESC)
GROUP BY rubr_id, rubr_detalle, p1.prod_codigo, p2.prod_codigo
ORDER BY (
  SELECT COUNT(DISTINCT item_producto)
  FROM Item_Factura
  JOIN Producto ON prod_codigo = item_producto
  WHERE prod_rubro = rubr_id
) DESC

/*
19. En virtud de una recategorizacion de productos referida a la familia de los mismos se
solicita que desarrolle una consulta sql que retorne para todos los productos:

Codigo de producto
Detalle del producto
Codigo de la familia del producto
Detalle de la familia actual del producto

Codigo de la familia sugerido para el producto
Detalla de la familia sugerido para el producto

La familia sugerida para un producto es : la que poseen la mayoria de los productos cuyo
detalle coinciden en los primeros 5 caracteres.
En caso que 2 o mas familias pudieran ser sugeridas se debera seleccionar la de menor
codigo. Solo se deben mostrar los productos para los cuales la familia actual sea
diferente a la sugerida
Los resultados deben ser ordenados por detalle de producto de manera ascendente
*/

SELECT p1.prod_codigo,
       p1.prod_detalle,
       p1.prod_familia,
       fami_detalle,
       (SELECT TOP 1 f2.fami_id
        FROM Familia f2
        JOIN Producto p2 ON f2.fami_id = p2.prod_familia
        WHERE LEFT(p2.prod_detalle, 5) = LEFT(p1.prod_detalle, 5)
        GROUP BY f2.fami_id
        ORDER BY COUNT(*) DESC, f2.fami_id) as fami_id_sugerida,

        (SELECT TOP 1 f2.fami_detalle
        FROM Familia f2
        JOIN Producto p2 ON f2.fami_id = p2.prod_familia
        WHERE LEFT(p2.prod_detalle, 5) = LEFT(p1.prod_detalle, 5)
        GROUP BY f2.fami_id, f2.fami_detalle
        ORDER BY COUNT(*) DESC, f2.fami_id) as detalle_fami_sugerida

FROM Producto p1 LEFT JOIN Familia ON prod_familia = fami_id
WHERE p1.prod_familia <> (SELECT TOP 1 f2.fami_id
        FROM Familia f2
        JOIN Producto p2 ON f2.fami_id = p2.prod_familia
        WHERE LEFT(p2.prod_detalle, 5) = LEFT(p1.prod_detalle, 5)
        GROUP BY f2.fami_id
        ORDER BY COUNT(*) DESC, f2.fami_id)
ORDER BY 2 ASC

/*
20. Escriba una consulta sql que retorne un ranking de los mejores 3 empleados del 2012
Se debera retornar 
    legajo, 
    nombre y apellido, 
    anio de ingreso, 
    puntaje 2011, 
    puntaje 2012.
El puntaje de cada empleado se calculara de la siguiente manera: 
- Para los que hayan vendido al menos 50 facturas el puntaje se calculara como la 
  cantidad de facturas que superen los 100 pesos que haya vendido en el año.

- Para los que tengan menos de 50 facturas en el año el calculo del puntaje sera el 50% 
  de cantidad de facturas realizadas por sus subordinados directos en dicho año.
*/


SELECT TOP 3 empl_codigo as legajo,
       rtrim(empl_apellido)+' '+rtrim(empl_nombre) as nombre_apellido,
       year(empl_ingreso) as anio_ingreso,
       (CASE WHEN 
            (SELECT COUNT(fact_vendedor) FROM Factura 
             WHERE year(fact_fecha) = 2011 AND fact_vendedor = empl_codigo) >= 50
        THEN
            (SELECT COUNT(fact_vendedor) FROM Factura
             WHERE year(fact_fecha) = 2011 AND fact_vendedor = empl_codigo AND fact_total > 100)
        ELSE 
            (SELECT COUNT(fact_vendedor)/2 FROM Factura
             JOIN Empleado e2 ON e1.empl_codigo = e2.empl_jefe
             WHERE year(fact_fecha) = 2011 AND fact_vendedor = e2.empl_codigo)    
       END) as puntaje_2011,
       (CASE WHEN 
            (SELECT COUNT(fact_vendedor) FROM Factura 
             WHERE year(fact_fecha) = 2012 AND fact_vendedor = empl_codigo) >= 50
        THEN
            (SELECT COUNT(fact_vendedor) FROM Factura
             WHERE year(fact_fecha) = 2012 AND fact_vendedor = empl_codigo AND fact_total > 100)
        ELSE 
            (SELECT COUNT(fact_vendedor)/2 FROM Factura
             JOIN Empleado e2 ON e1.empl_codigo = e2.empl_jefe
             WHERE year(fact_fecha) = 2012 AND fact_vendedor = e2.empl_codigo)    
       END) as puntaje_2012
FROM Empleado e1
order by 5 desc

/*
21. Escriba una consulta sql que retorne:
     para todos los años, en los cuales se haya hecho al menos una factura:
        la cantidad de clientes a los que se les facturo de manera incorrecta al menos una factura 
        cantidad de facturas se realizaron de manera incorrecta.
Se considera que una factura es incorrecta cuando:
     la diferencia entre el total de la factura menos el total de impuesto tiene una diferencia mayor a $ 1 respecto a la 
     sumatoria de los costos de cada uno de los items de dicha factura.
     
Las columnas que se deben mostrar son:
    Año
    Clientes a los que se les facturo mal en ese año
    Facturas mal realizadas en ese año
*/

SELECT 
    año,
    COUNT(DISTINCT CASE WHEN diferencia > 1 THEN fact_cliente END) AS cantidad_clientes_con_factura_incorrecta,
    COUNT(CASE WHEN diferencia > 1 THEN 1 END) AS cantidad_facturas_incorrectas
FROM (
    SELECT 
        YEAR(f.fact_fecha) AS año,
        f.fact_cliente,
        f.fact_tipo,
        f.fact_sucursal,
        f.fact_numero,
        ABS((f.fact_total - f.fact_total_impuestos) - SUM(i.item_cantidad * i.item_precio)) AS diferencia
    FROM Factura f
    JOIN Item_Factura i 
      ON f.fact_tipo = i.item_tipo 
     AND f.fact_sucursal = i.item_sucursal 
     AND f.fact_numero = i.item_numero
    GROUP BY 
        YEAR(f.fact_fecha), 
        f.fact_cliente, 
        f.fact_tipo, 
        f.fact_sucursal, 
        f.fact_numero, 
        f.fact_total, 
        f.fact_total_impuestos
) t
GROUP BY año
ORDER BY año;

/*
22.



*/