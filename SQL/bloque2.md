##  Razone sobre la coherencia y el rendimiento de los siguientes índices, y explique cómo podrían mejorarse.

#### Case 1. 
#### CREATE INDEX tbl_idx ON tbl (date_column)
#### SELECT COUNT(*) FROM tbl WHERE DATEPART(YEAR, date_column) = 2017

- El índice es creado en la columna 'date_column', lo cual facilitaría las queries en las que existiese filtrado por este campo.
- Esta columna es posteriormente utilizada en la query para filtrar los resultados según el año extraído de la fecha dada.
- Inicialmente, este índice podría ser de utilidad ya que puede acotar la búsqueda a la hora de devolver datos, aunque deberíamos tener en cuenta la distribución de los mismos, ya que únicamente usando el año de la fecha la granularidad del índice se ve afectada.
- Si, por ejemplo, toda la tabla tuviese fechas comprendidas solo en el año 2017, este índice no nos sería de utilidad ya que tampoco estaríamos filtrando por un valor que fuese interesante. En ese caso el índice se debería usar para filtrar por día o por mes completo al menos.
- En cambio, si existiese un volumen grande con fechas distribuídas en el tiempo, este índice sí podría eficienciar la consulta. Si tuviesemos un rango de años amplio, también se podría diseñar un índice directamente en el año de la fecha: CREATE INDEX tbl_idx ON tbl (DATEPART(YEAR, date_column))

#### Case 2.
#### CREATE INDEX tbl_idx ON tbl (a, date_column)
#### SELECT TOP 1 * FROM tbl WHERE a = 12 ORDER BY date_column DESC

- El índice en este caso es un índice compuesto por dos columnas. Esto indica que la estructura del índice se ordenará primeramente por los valores de la columna 'a' y posteriormente según los valores de 'date_column'.
- Este orden es algo importante a tener en cuenta a la hora de consultar a la tabla ya que existe un orden dado en las columnas que conforman el índice.
- En la query posterior en la que se filtra por el valor de 'a' y luego se ordena según la columna 'date_column' el índice se usa de manera efectiva ya que es útil a la hora de filtrar por el valor dado (a=12) y al igual que también lo es posteriormente a la hora de ordenar los resultados.
- Todo ello teniendo en cuenta que la cardinalidad de las columnas es suficiente como para que la distribución de los datos precisen de un índice diseñado de esta manera.
- Si se filtra indistintamente por una o por otra y no se espera que las dos columnas siempre vayan a ir acompañadas, se podría considerar hacer dos índices por separado en vez de un índice conjunto.

#### Case 3.
#### CREATE INDEX tbl_idx ON tbl (a, b)
#### SELECT * FROM tbl WHERE a = 38 AND b = 1
#### SELECT * FROM tbl WHERE b = 1

- De igual manera que en el caso anterior, el índice calculado en este ejemplo es un índice compuesto por dos columnas, 'a' y 'b'. La estructura de las queries debe tener en cuenta que existe un orden entre ellas para eficienciar las consultas, siempre y cuando la cardinalidad y distribución de los datos se adecúe también a la decisión por implementar este índice.
- En el caso de la primera query, en el que se filtra tanto primeramente por la columna a=38 como seguidamente por b=1, el diseño del índice y su funcionalidad a priori es buena ya que evita el escaneo completo de la tabla y directamente filtra primero según el índice en 'a' y luego en 'b'.
- En el caso de la segunda query en la que el valor de 'a' no se tiene en cuenta a la hora de filtrar, dependiendo de la distribución de los valores de 'b' tendremos una mayor eficiencia o no. En general, se espera que la query no sea tan eficiente en comparación con la primera consulta ya que existe una alta probabilidad de necesitar escanear la tabla al completo o la mayor parte de la tabla para buscar todas las filas en las que el valor de b sea igual a 1, y desestimar el uso del índice.
- Si esperamos tener más filtrados por la columna 'b' ya que la distribución de los datos es mayor, o la cardinalidad de la columna a no es suficiente, se podría estudiar hacer directamente un índice sobre la columna 'b' y otro sobre la 'a' por separado, o al menos cambiar el orden del índice anterior. CREATE INDEX tbl_idx ON tbl (b) o CREATE INDEX tbl_idx ON tbl (b, a)

#### Case 4.
#### CREATE INDEX tbl_idx ON tbl (text)
#### SELECT * FROM tbl WHERE text LIKE 'TJ%'

- En este caso el índice es creado en una columna que es de tipo texto. Al igual que en las columnas anteriores, tanto numéricas como por fecha, las columnas de tipo texto también se pueden indexar.
- En la consulta posterior en la que se desea filtrar por el contenido del texto, este índice actua de manera efectiva filtrado aquellas filas en las que el existe el prefijo dado 'TJ%'.
- Sin embargo, existen diferentes maneras de consultar columnas de texto como rangos, igualdades o como en este caso con las llamadas 'wildcard'. A la hora de investigar acerca de los índices para columnas de texto, las recomendaciones indican que existen varias formas de indexar que se adecúan de diferente manera a los tipos de queries mencionadas anteriormente que se esperan.
- En este caso con un índice standard en las que se busca por un prefijo se esperaría, como se ha comentado antes, que la búsqueda sea más efectiva en el caso en el que la distribución de los datos fuese adecuada.