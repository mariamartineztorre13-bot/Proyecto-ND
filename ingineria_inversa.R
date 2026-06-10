setwd("C:\\PROYECTO_FINAL")

library(dplyr)

#ingenieria inversa
#subo los csv de hecho y dimensiones


library(readr)



library(writexl)

# read_csv2 es para archivos que usan ; como separador

primas <- read_delim(file = "primas.csv", delim = ";",locale = locale(encoding = "UTF-8", decimal_mark = ".", grouping_mark = ","),
                     col_types = cols(.default = col_character())) # Primero lee todo como texto)

# Ahora convertimos específicamente las columnas que deben ser numéricas
primas <- primas %>%
  mutate(
    Gross_written_premium = as.numeric(gsub(",", "", Gross_written_premium)),
    Number_insured = as.integer(Number_insured)
  )



dim_destino <- read_delim(file = "dim_destinos.csv", delim = ";",locale = locale(encoding = "UTF-8", decimal_mark = ".", grouping_mark = ","),
                     col_types = cols(.default = col_character())) # Primero lee todo como texto)
                     

dim_garantias <- read_delim(file = "dim_garantias.csv", delim = ";",locale = locale(encoding = "UTF-8", decimal_mark = ".", grouping_mark = ","),
                          col_types = cols(.default = col_character())) # Primero lee todo como texto)


dim_productos <- read_delim(file = "dim_productos.csv", delim = ";",locale = locale(encoding = "UTF-8", decimal_mark = ".", grouping_mark = ","),
                            col_types = cols(.default = col_character())) # Primero lee todo como texto)



siniestros <- read_delim(file = "dim_siniestros.csv", delim = ";",locale = locale(encoding = "UTF-8", decimal_mark = ".", grouping_mark = ","),
                            col_types = cols(.default = col_character())) # Primero lee todo como texto)



# Realizo la unión
primas_union <- primas %>%
  left_join(dim_productos, by = c("Product" = "nueva_formula")) %>%
  left_join(dim_destino, by = c("City_insured" = "city_insured"))


siniestros_union <- siniestros %>%
  # Primero unimos con garantías
  left_join(dim_garantias, by = c("Concatenacion_gar" = "Concatenacion_gar")) 



# Esto guardará el archivo en tu carpeta de trabajo (C:\PROYECTO_FINAL)
write_xlsx(siniestros_union, "siniestros_union.xlsx")
write_xlsx(primas_union, "primas_union.xlsx")



