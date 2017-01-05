--- Procedimiento para Calculo Fecha Diferencia
CREATE PROCEDURE diferencia(@antes DATETIME)
AS
BEGIN
	DECLARE @ahora DATETIME
	SET @ahora = SYSDATETIME()
	PRINT 'Tardo ' + CONVERT(varchar, DATEDIFF( millisecond , @antes , @ahora )) + ' MiliSegundos'
END;
GO

/* ESTADO PRUEBAS
 - Tablas con la cual Probe: tienen unos 436800 filas la mas grande y la mas chica 142080 (rango)
 - Tablas sin Indices ademas de los creados automaticamente por el motor para PK y FK.
 - Motor Base Datos con la Configuracion por Defecto
*/




/*	PRUEBA 1
	SELECT * contra SELECT algunos campos
*/
PRINT 'PRUEBA 1'
DECLARE @hora_antes DATETIME = SYSDATETIME()
SELECT TOP 1000 *  FROM [GD2C2016].[gd_esquema].[Maestra]
EXECUTE diferencia @hora_antes;
GO
DECLARE @hora_antes DATETIME = SYSDATETIME()
SELECT TOP 1000 Medico_Apellido, Medico_Apellido, Medico_Direccion, Medico_Dni  FROM [GD2C2016].[gd_esquema].[Maestra]
EXECUTE diferencia @hora_antes;
GO
/*		RESULTADOS
110 Milisegundos la Primera Consulta contra 33 Milisegundos la 2da
Confirmado que Select Campos tarda menos
*/




/*		PRUEBA 2
	Chequear existencia Registro por IF SELECT COUNT VS por IF EXISTS
*/
PRINT ''
PRINT 'PRUEBA 2'
DECLARE @hora_antes DATETIME = SYSDATETIME()
IF (SELECT COUNT(1) FROM [GD2C2016].[gd_esquema].[Maestra] WHERE Paciente_Nombre LIKE '%ROMULO%') > 0
 	PRINT 'YES' 
EXECUTE diferencia @hora_antes;
GO
DECLARE @hora_antes DATETIME = SYSDATETIME()
IF EXISTS (SELECT Paciente_Nombre FROM [GD2C2016].[gd_esquema].[Maestra] WHERE Paciente_Nombre LIKE '%ROMULO%')
 	PRINT 'YES' 
EXECUTE diferencia @hora_antes;
GO
/*  RESULTADOS
3 Milisegundos VS 3 Milisegundos
Tardo Exactamente lo mismo, no cambia nada.
Si es por legibilidad es mejor usar EXISTS, pero no por performance.
*/



/*		PRUEBA 3
	Subqueries en Select VS JOIN Auto por Planificador VS JOIN Manual
*/
PRINT ''
PRINT 'PRUEBA 3'
DECLARE @hora_antes DATETIME = SYSDATETIME()
SELECT 
		a.nombre
		, a.apellido
		, (SELECT  p.descripcion FROM KFC.planes p WHERE a.plan_id = p.plan_id )
FROM	KFC.afiliados a
EXECUTE diferencia @hora_antes;
GO
DECLARE @hora_antes DATETIME = SYSDATETIME()
SELECT 
		a.nombre
		, a.apellido
		, p.descripcion
FROM	KFC.afiliados a
		, KFC.planes p
WHERE	a.plan_id = p.plan_id
EXECUTE diferencia @hora_antes;
GO
DECLARE @hora_antes DATETIME = SYSDATETIME()
SELECT 
		a.nombre
		, a.apellido
		, p.descripcion
FROM	KFC.afiliados a
		INNER JOIN KFC.planes p
		ON	a.plan_id = p.plan_id
EXECUTE diferencia @hora_antes;
GO
/*	RESULTADOS
Subqueries en Select y Join Manual tienen siempre performance parecida (diferencia menor a 3 milisegundos).
Auto Join por el Optimizador siempre tiene una performance distinta a los otros 2.
Es raro, porque a veces la 1era y 3era tardan 110 y la 3da 50. Y a veces es al reves, la 1era y 3era tardan 50 y la 2da 110.
Resultado: No es Concluyente como Joinear. No es buena decision usar INNER JOINs (y otros tipos) por performance, pero si es buena decision por facilidad de lectura, mantenibilidad y facil predecir ejecucion del motor (ejecuta orden inverso: 1ero JOINS mas internos, luego externos)
*/



/*		PRUEBA 4
	Variaciones de LIKE y OR
*/
PRINT ''
PRINT 'PRUEBA 4'
DECLARE @hora_antes DATETIME = SYSDATETIME()
SELECT 
		nombre
		, apellido
FROM	KFC.afiliados a
WHERE nombre LIKE 'M%a'
OR nombre LIKE 'N%a'
OR nombre LIKE 'L%a'
EXECUTE diferencia @hora_antes;
GO
DECLARE @hora_antes DATETIME = SYSDATETIME()
SELECT *
FROM	(
		SELECT 
				nombre
				, apellido
		FROM	KFC.afiliados a
		WHERE a.nombre LIKE '%a'
		) AS a
WHERE a.nombre LIKE 'M%'
OR a.nombre LIKE 'N%'
OR a.nombre LIKE 'L%'
EXECUTE diferencia @hora_antes;
GO
DECLARE @hora_antes DATETIME = SYSDATETIME()
SELECT *
FROM	(
		SELECT 
				nombre
				, apellido
		FROM	KFC.afiliados a
		WHERE a.nombre LIKE 'M%'
			OR a.nombre LIKE 'N%'
			OR a.nombre LIKE 'L%'
		) AS a
WHERE a.nombre LIKE '%a'
EXECUTE diferencia @hora_antes;
GO
/*	RESULTADOS	
Los tiempos de ejecucion son iguales de las 3 variantes, no hay un cambio de performance.
Puede usarse la forma deseada.
*/



/*	PRUEBA 5
	Busqueda por  campo fecha sin Indice con y sin funciones de conversion
*/
PRINT ''
PRINT 'PRUEBA 5'
DECLARE @hora_antes DATETIME = SYSDATETIME()
SELECT *  FROM [GD2C2016].[gd_esquema].[Maestra]
WHERE Paciente_Fecha_Nac >= '19870218' AND Paciente_Fecha_Nac < '19870219'
EXECUTE diferencia @hora_antes;
GO
DECLARE @hora_antes DATETIME = SYSDATETIME()
SELECT *  FROM [GD2C2016].[gd_esquema].[Maestra]
WHERE Paciente_Fecha_Nac BETWEEN '19870218' AND '19870219'
EXECUTE diferencia @hora_antes;
GO
DECLARE @hora_antes DATETIME = SYSDATETIME()
SELECT *  FROM [GD2C2016].[gd_esquema].[Maestra]
WHERE YEAR(Paciente_Fecha_Nac) = '1987'
EXECUTE diferencia @hora_antes;
GO
/*		RESULTADOS
PEOR: Uso de Funcion. 143 MiliSegundos
MEDIO: Uso de >= y =. 76 MiliSegundos
MEJOR: Uso de Between. 56 MiliSegundos
*/


/*	PRUEBA 6
	Uso de TOP 1 al encontrar resultado unico, contra no usarlo
*/
PRINT ''
PRINT 'PRUEBA 6'
DECLARE @hora_antes DATETIME = SYSDATETIME()
SELECT TOP 1 *  FROM [GD2C2016].[gd_esquema].[Maestra]
WHERE Paciente_Nombre = 'ETELVINA' AND Paciente_Apellido = 'Ríos' AND Turno_Numero = 90437 AND Consulta_Sintomas IS NULL AND Compra_Bono_Fecha IS NULL
EXECUTE diferencia @hora_antes;
GO
DECLARE @hora_antes DATETIME = SYSDATETIME()
SELECT *  FROM [GD2C2016].[gd_esquema].[Maestra]
WHERE Paciente_Nombre = 'ETELVINA' AND Paciente_Apellido = 'Ríos' AND Turno_Numero = 90437 AND Consulta_Sintomas IS NULL AND Compra_Bono_Fecha IS NULL
EXECUTE diferencia @hora_antes;
GO
/*		RESULTADOS
USO TOP 1:	3 MiliSegundos
SIN USAR:	73 MiliSegundos
*/







--Drop Procedure
DROP PROCEDURE diferencia