-- SQL:

--1) 

select 
ROW_NUMBER() OVER (
	order by ( 
		ISNULL(
			(select sum(if2.item_cantidad) 
			from item_factura if2 
			inner join Factura f2 
			on f2.fact_numero = if2.item_numero 
			and f2.fact_sucursal = if2.item_sucursal 
			and f2.fact_tipo = if2.item_tipo
			where f2.fact_cliente = c.clie_codigo)
		,0)			
	) DESC
) row_num,
c.clie_codigo,
c.clie_razon_social,
ISNULL(
	(select sum(if2.item_cantidad) 
	from item_factura if2 
	inner join Factura f2 
	on f2.fact_numero = if2.item_numero 
	and f2.fact_sucursal = if2.item_sucursal 
	and f2.fact_tipo = if2.item_tipo
	where f2.fact_cliente = c.clie_codigo)
,0) as cantidad_total_comprada,
( 
	select TOP 1 p.prod_rubro
		from Item_Factura if2 
		inner join Producto p
		on if2.item_producto = p.prod_codigo 
		inner join Factura f2
		on f2.fact_numero = if2.item_numero and f2.fact_tipo = if2.item_tipo and f2.fact_sucursal = if2.item_sucursal and f2.fact_cliente = c.clie_codigo
		where YEAR(f2.fact_fecha) = 2012
		group by p.prod_rubro 
		order by sum(if2.item_cantidad) DESC
) as rubro_mas_comprado_en_2012
from Cliente c
inner join Factura f1
on f1.fact_cliente = c.clie_codigo
inner join Item_Factura if1
on f1.fact_numero = if1.item_numero and f1.fact_tipo = if1.item_tipo and f1.fact_sucursal = if1.item_sucursal
where YEAR(f1.fact_fecha) % 2 = 0
group by c.clie_codigo, c.clie_razon_social
having (select count(distinct p.prod_rubro) 
		from Producto p 
		inner join Item_Factura if2
		on if2.item_producto = p.prod_codigo
		inner join Factura f2
		on f2.fact_numero = if2.item_numero and f2.fact_tipo = if2.item_tipo and f2.fact_sucursal = if2.item_sucursal and f2.fact_cliente = c.clie_codigo
		where YEAR(f2.fact_fecha) = 2012) > 3
order by ( 
	ISNULL(
		(select sum(if2.item_cantidad) 
		from item_factura if2 
		inner join Factura f2 
		on f2.fact_numero = if2.item_numero 
		and f2.fact_sucursal = if2.item_sucursal 
		and f2.fact_tipo = if2.item_tipo
		where f2.fact_cliente = c.clie_codigo)
	,0)			
) DESC


--- TSQL:

--2)

create table productos_mas_vendidos (producto char(50), anio_venta int)

ALTER TRIGGER trigger_productos_mas_vendidos
ON item_factura 
AFTER INSERT, UPDATE, DELETE
AS
BEGIN 
    BEGIN TRANSACTION;
    
    delete from productos_mas_vendidos;
    
    with CantidadVendidaPorAnio as (
        select 
        YEAR(f1.fact_fecha) as anio, p.prod_detalle, 
        sum(if1.item_cantidad) AS cantidad_vendida_en_anio,
        ROW_NUMBER () OVER (PARTITION BY YEAR(f1.fact_fecha) 
        					ORDER BY sum(if1.item_cantidad) DESC
        					) as numero_de_fila
        from Producto p
        inner join Item_Factura if1 
        on if1.item_producto = p.prod_codigo
        inner join Factura f1 
        on f1.fact_numero = if1.item_numero 
		and f1.fact_sucursal = if1.item_sucursal 
		and f1.fact_tipo = if1.item_tipo
        group by YEAR(f1.fact_fecha), p.prod_detalle
    )
    
    insert into productos_mas_vendidos (producto, anio_venta)
    select prod_detalle, anio
    from CantidadVendidaPorAnio
    where numero_de_fila <= 10
    order by cantidad_vendida_en_anio desc;
    
    COMMIT TRANSACTION;
END;
