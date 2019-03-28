Tratamento dos dados brutos
===========================

Esse arquivo tem como objetivo tratar os dados brutos do projeto de
acesso a oportunidades. As bases de dados tratadas aqui são:

-   `Municípios`
-   `Censo escolar`
-   `Grade censo`
-   `Hospitais`
-   `GTFS`

Municípios
----------

Os dados de município estão compactados em formato de *shapefile*,
divididos por UF. O tratamento desse dados consiste em:

-   Descompactação dos arquivos;
-   Leitura dos shapefiles municipais;
-   Salvos em disco em formato `rds`.

<!-- -->

    # ajeitar os municipios


    arquivos <- dir("../data-raw/municipios", full.names = T, pattern = "_municipios.zip", recursive = T)


    out_dir <- paste0("../data-raw/municipios/", str_sub(arquivos, -17, -16))

    walk2(arquivos, out_dir, ~unzip(zipfile = .x, exdir = .y))

    # # criar pastas
    # walk(str_sub(arquivos, -17, -16), ~dir.create(paste0("../data/municipios/", .)))

    # nome dos arquivos .shp para abrir
    arquivos_shp <- dir("../data-raw/municipios", full.names = T, pattern = "*.shp", recursive = T)

    # # arquivo com output
    # out_dir_data <- paste0("../data/municipios/", str_sub(arquivos, -17, -16))

    # funcao

    shp_to_rds <- function(shp) {
      
      shp_files <- st_read(shp, crs = 4326, options = "ENCODING=WINDOWS-1252")
      
      uf <- gsub(".+/(\\D{2})/.+", "\\1", shp)
      
      out_dir <- paste0("../data/municipios/municipios_", uf, ".rds")
      
      write_rds(shp_files, out_dir)
      
      
    }


    walk(arquivos_shp, shp_to_rds)

Censo escolar
-------------

    source("R/converter_censo_coords.R")
    # ABRIR ARQUIVO


    censo_escolar <- 
      # Abrir e selecionar as colunas de interesse
      fread("data-raw/censo_escolar/CAD_ESC_MAT_DOC_2015.csv", sep = ";",
            select = c(17,3,6,14,128,138,144,150,165,187,196,201,206,27,28)) %>%
      # Renomear as colunas
      rename(cod_escola = CO_ENTIDADE,uf = SIGLA, municipio = NO_MUNICIPIO, rede = REDE, num_funcionarios = NU_FUNCIONARIOS,
             presencial = IN_MEDIACAO_PRESENCIAL, mat_infantil = MAT_INF, mat_fundamental = MAT_FUND,
             mat_medio = MAT_MED, mat_profissional = MAT_PROF, mat_eja = MAT_EJA, mat_especial = MAT_ESP, 
             docentes = DOCTOTAL, lon = NU_LONGITUDE, lat = NU_LATITUDE) %>%
      # Tratar as coordenadas
      mutate(lon = convert_coords(lon),
             lat = convert_coords(lat))


    # SALVAR

    write_csv(censo_escolar, "data/censo_escolar/censo_escolar_2015.csv")


    # # TIDYING UP!!!
    # 
    # censo_escolar_long <- censo_escolar %>%
    #   gather(key = "tipo", value = "total", mat_infantil:docentes)
    # 
    # write_csv(censo_escolar_long, "data/censo_escolar/censo_escolar_2015_long.csv")

Grade censo
-----------

As grades do censo são divididas por ID, onde cada um desses pode
encorporar vários municípios. O arquivo `Tabela_UF_ID.csv` contém uma
tabela auxiliar que identifica os IDs contidos em cada estado. O
tratamento dessa arquivo corrige alguns erros e cria uma correspondência
entre o nome e a sigla de cada UF, salvando o arquivo tratado em disco.

    # TRATAMENTO DO ARQUIVO COM OS IDs

    # criar encoding para abrir arquivo
    brazil <- locale("pt", encoding = "Windows-1252")

    # abrir tabela de ids
    ids_corresp <- read_delim("../data-raw/Tabela_UF_ID.csv", delim = ";", locale = brazil) %>%
      arrange(Estados) %>%
      mutate(Estados = ifelse(Estados == "Pernanbuco", "Pernambuco", Estados))

    lookup_ufs <- data.frame(stringsAsFactors=FALSE,
                          Estados = c("Acre", "Alagoas", "Amazonas",
                                              "Amapá", "Bahia", "Ceará",
                                              "Distrito Federal", "Espírito Santo", "Goiás",
                                              "Maranhão", "Minas Gerais",
                                              "Mato Grosso do Sul", "Mato Grosso", "Pará",
                                              "Paraíba", "Pernambuco", "Piauí", "Paraná",
                                              "Rio de Janeiro", "Rio Grande do Norte",
                                              "Rondônia", "Roraima",
                                              "Rio Grande do Sul", "Santa Catarina", "Sergipe",
                                              "São Paulo", "Tocantins"),
                             uf = c("AC", "AL", "AM", "AP", "BA", "CE",
                                              "DF", "ES", "GO", "MA", "MG", "MS",
                                              "MT", "PA", "PB", "PE", "PI", "PR",
                                              "RJ", "RN", "RO", "RR", "RS", "SC", "SE",
                                              "SP", "TO")
    )



    ids_corresp_v1 <- ids_corresp %>%
      left_join(lookup_ufs) %>%
      mutate(uf = tolower(uf),
             Quadrante = tolower(Quadrante)) %>%
      mutate(Quadrante = gsub("_", "", Quadrante))

    write_csv(ids_corresp_v1, "../data-raw/lookup_grade_ufs.csv")
    # write_rds(ids_corresp_v1, "../data-raw/lookup_grade_ufs.rds")

A função para extrair os municípios das grades do IBGE requer dois
inputs: o `municipio` e a `uf`:

-   Com a `uf` é feita uma seleção dos IDs que estão presentes na uf
    desejada daquele município;
-   É aberto então o shape do `municipio` desejado;
-   O geoprocessamento extrai somente as grades que estão inseridas
    dentro dos limites do município;
-   O resultado é salvo em disco.

<!-- -->

    grade_para_municipio <- function(muni, uf_input) {
      
      files <- read_csv("../data-raw/lookup_grade_ufs.csv") %>%
        filter(uf == uf_input) %>%
        mutate(Quadrante = paste0("grade_", Quadrante)) %>%
        .$Quadrante
      
      arquivos <- paste0("../data-raw/dadosrds/", files, ".rds")
      
      # abrir quadrantes da uf
      
      grades <- map_dfr(arquivos, read_rds) %>%
        as_tibble() %>%
        st_sf(crs = 4326)
      
      # extrair municipio -------------------------------------------------------
      
      municipio_ok <- toupper(muni)
      
      
      # abrir arquivos ----------------------------------------------------------
      
      dir_muni <- paste0("../data/municipios/municipios_", uf_input, ".rds")
      
      grade_estado <- grades %>%
        mutate(id_grade = 1:n()) %>%
        select(id_grade, MASC, FEM, POP, DOM_OCU)
      
      grade_estado_centroids <- grade_estado %>%
        st_centroid()
      
      cidade <- read_rds(dir_muni) %>%
        filter(NM_MUNICIP == municipio_ok) %>%
        select(municipio = NM_MUNICIP)
      
      
      # geoprocessamento --------------------------------------------------------
      
      vai <- st_join(grade_estado_centroids, cidade) %>%
        filter(!is.na(municipio))
      
      
      grade_municipio <- grade_estado %>%
        filter(id_grade %in% vai$id_grade) %>%
        mutate(municipio = municipio_ok)
      
      
      # salvar ------------------------------------------------------------------
      
      # tirar os espaços e colocar underscore
      municipio_nome_salvar <- substring(municipio_ok, 1, 3)
      
      # # criar pasta para o municipio
      # dir.create(paste0("data/grade_municipio/", municipio_nome_salvar))
      
      # salvar no disco
      write_rds(grade_municipio, 
               paste0("../data/grade_municipio/grade_", tolower(municipio_nome_salvar), ".rds"))
      
      
      
    }

A função é então aplicada primeiramente para três cidades: Fortaleza,
Rio de Janeiro e Belo Horizonte.

    municipios <- c("fortaleza", "rio de janeiro", "belo horizonte")
    ufs <- c("ce", "rj", "mg")

    walk2(municipios, ufs, grade_para_municipio)

Hospitais
---------

    # hospitais <- read_csv("../data-raw/hospitais/cnesnone_2018.csv") %>%
    #   st_as_sf(coords = c("long", "lat"), crs = 4326)

GTFS
----

O GTFS do Rio de Janeiro apresenta algumas inconsistências no arquivo
`stop_times.txt`.

    # OTP RIO!!!!!!!!!1 -------------------------------------------------------

    # path_otp <- "otp/programs/otp.jar" # On Linux
    # 
    # path_data <- "otp"
    # 
    # log <- otp_build_graph(otp = path_otp, dir = path_data, router = "rio",
    #                        memory = 16)
    # 
    # 
    # otpcon <- otp_connect()
    # 
    # 
    # system("java -Xmx4G -jar \"otp/programs/otp.jar\" --build \"otp/graphs/rio")

    # Error:
    # Caused by: org.onebusaway.gtfs.serialization.mappings.InvalidStopTimeException: invalid stop time: 00:00:-6


    # VERIFICAR O ERRO --------------------------------------------------------

    stop_times <- fread("gtfs_teste/gtfs_rio_00_20171218/stop_times.txt", sep = ",") 

    teste1 <- stop_times %>%
      select(arrival_time, departure_time) %>%
      filter(!grepl("\\d{2}:\\d{2}:\\d{2}", arrival_time))



    # CORRIGIR O ERRO ---------------------------------------------------------


    stop_times_new <- stop_times %>%
      mutate(arrival_time = ifelse(grepl("\\d{2}:\\d{2}:\\d{2}", arrival_time), arrival_time, "00:00:06")) %>%
      mutate(departure_time = ifelse(grepl("\\d{2}:\\d{2}:\\d{2}", departure_time), departure_time, "00:00:06"))


    # TESTAR SE A CORREÇÃO FUNCIONOU ------------------------------------------


    stop_times_new %>%
      filter(!grepl("\\d{2}:\\d{2}:\\d{2}", arrival_time))

    # OK!!!!!!!!!!

    # SALVAR, ENTAO! ----------------------------------------------------------


    data.table::fwrite(stop_times_new, "gtfs_teste/gtfs_rio_novo/stop_times.txt", quote = TRUE)