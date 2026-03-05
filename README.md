# Ubimia - Prueba Técnica

Repositorio con las dos pruebas técnicas: el script SQL y la parte ASP.NET.

---

## Parte SQL

El script es `UbimiaSqlChallenge.sql`. Antes de ejecutarlo hay que ajustar las rutas de los dos `BULK INSERT` (líneas ~32 y ~45) para que apunten a donde estén los archivos CSV en la máquina:

```sql
FROM 'C:\Users\<tu-usuario>\Desktop\Clientes.csv'
FROM 'C:\Users\<tu-usuario>\Desktop\Transacciones.csv'
```

Los CSV se exportan desde el Excel `Ubimia - Prueba Técnica Análisis.xls.xlsx`, pestañas "BD prueba Clientes" y "BD prueba Transacciones", con separador `;` y codificación UTF-8.

Para ejecutar: abrir SSMS, conectarse, crear o seleccionar una base de datos y correr el script completo con F5.

El script crea las tablas de staging, importa los datos, los carga limpios en las tablas definitivas y arma la tabla de resumen. Al final hace un SELECT para verificar los conteos.

---

## Parte ASP.NET

Requiere .NET 10 SDK instalado. Para correrlo desde Visual Studio abrir `UbimiaAspTest.slnx` y presionar F5. Desde consola:

```bash
dotnet run
```

La app queda disponible en `http://localhost:5179`. Ahí se puede usar la página web para calcular factoriales y ordenar números, o ir a `/swagger` para probar los endpoints de la API directamente.

Endpoints disponibles:
- `GET /api/calculator/factorial/{n}` — calcula el factorial de n (entre 0 y 20)
- `POST /api/calculator/sort` — ordena 5 números, body: `{ "numbers": [3, 1, 4, 1, 5] }`
