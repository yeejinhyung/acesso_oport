#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###### 0.1.5 Download dos dados geolocalizados dos estabelecimentos de saude
##info
# fonte: Cadastro Nacionl dos Estabelecimentos de Saude (CNES) - DataSus



health_filter_estabs <- function(ano) {
  
  
  ### 1) Ler os dados do CNES ---------------------------------
  
  
  if(ano %in% c("2017", "2018")) {
    
    
    cnes19 <- readxl::read_xlsx(path = '../../data-raw/hospitais/2017-2018/BANCO_BANCO_ESTAB_10_2017_E_10_2018_02_10_2020.xlsx',
                                sheet = 'BANCO', skip = 13, 
                                col_types = "text")
    
    
    # format column names
    cnes19 <- janitor::clean_names(cnes19)
    
    # filter year 
    cnes19 <- setDT(cnes19)[competencia %like% ano]
    
    # rename columns
    names(cnes19)[16:32] <- c("instal_fisica_ambu", "instal_fisica_hospt", "instal_fisica_urgencia",
                              "complex_alta_ambu_est", "complex_alta_ambu_mun", "complex_baix_ambu_est", "complex_baix_ambu_mun", "complex_medi_ambu_est", "complex_medi_ambu_mun", 
                              "complex_alta_hosp_est", "complex_alta_hosp_mun", "complex_baix_hosp_est", "complex_baix_hosp_mun", "complex_medi_hosp_est", "complex_medi_hosp_mun", 
                              "complex_nao_aplic_est", "complex_nao_aplic_mun")
    # nrow(cnes19) # 328631 obs
    # colnames(cnes19)
    
    
  } else if (ano == 2019) {
    
    cnes19 <- readxl::read_xlsx(path = '../../data-raw/hospitais/2019/CNES_NDIS_01_10_2019_BANCO_COMP_08_2019.xlsx',
                                sheet = 'BANCO', skip = 14, 
                                col_types = "text")
    
    # format column names
    cnes19 <- janitor::clean_names(cnes19)
    
    # remove 1st NA rows
    cnes19 <- cnes19[-c(1:3),]
    
    # rename columns
    names(cnes19)[15:30] <- c("instal_fisica_ambu", "instal_fisica_hospt", 
                              "complex_alta_ambu_est", "complex_alta_ambu_mun", 
                              "complex_baix_ambu_est", "complex_baix_ambu_mun", 
                              "complex_medi_ambu_est", "complex_medi_ambu_mun", 
                              "complex_alta_hosp_est", "complex_alta_hosp_mun", 
                              "complex_baix_hosp_est", "complex_baix_hosp_mun", 
                              "complex_medi_hosp_est", "complex_medi_hosp_mun", 
                              "complex_nao_aplic_est", "complex_nao_aplic_mun")
    # nrow(cnes19) # 340115 obs
    # colnames(cnes19)
    
    
    
  } 
    

  
  ### 2) Limpar os dados do CNES ---------------------------------
  
  
  # Filter 0: healthcare nao aplica (pq nao tem servicos de alta/baixa complexidade, e.g. academias de saude, secretarias de saude etc)
  cnes_filter0 <- setDT(cnes19)[is.na(complex_nao_aplic_est)] 
  cnes_filter0 <- cnes_filter0[is.na(complex_nao_aplic_mun)]
  
  
  # Filter 1: healthcare facilities operating with the public health system
  cnes_filter1 <- setDT(cnes_filter0)[ atende_sus == 'SIM']
  
  
  # Filter 2: Pessoa juridica
  cnes_filter2 <- cnes_filter1[ pessoa_fisica_ou_pessoa_juridi == 'PESSOA_JURÍDICA']
  
  
  # filter 3: Only municipalities in the project
  cnes_filter3 <- cnes_filter2[ibge %in% substr(munis_df$code_muni, 1,6)]
  
  
  # filter 4: Only atendimento hospitalar ou ambulatorial
  install_ambu <- ifelse(ano %in% c(2017, 2018), "X", "SIM")
  cnes_filter4 <- cnes_filter3[ instal_fisica_ambu==install_ambu | instal_fisica_hospt==install_ambu]
  
  
  # filter 5. Remove special categories of facilities 
  
  # 5.1 Delete prison hospitals, research centers, police hospitals etc
  to_remove1 <- 'ZOONOSES|CENTRO DE ESTUDOS|PSIQUIAT|PRESIDIO|PENAL|JUDICIARIO|PENITENCIARIA|PENITENCIARIO|SEDIT|DETENCAO|PROVISORIA|SANATORIO|POLICIA| PADI|DE REGULACAO|VIGILANCIA|SAMU |ACADEMIA|DEPEND QUIMICO|REEDUCACAO SOCIAL|CAPS|CENTRO DE ATENCAO PSICOSSOCIAL|DISTRIB DE ORGAOS|MILITAR|CADEIA PUBLICA|DOMICILIAR|ARTES MARCIAIS|UBS IPAT|UBS CDPM II'
  # PADI = Programa de Atenção Domiciliar ao Idoso
  # DE REGULACAO = gestora de servico
  # CAPS - CENTRO DE ATENCAO PSICOSSOCIAL - saude mental e drogas
  # UBS IPAT e UBS CDPM II - vinculatos a policia
  
  
  
  # 5.2 Delete Home care, tele saude, unidades moveis de saude
  to_remove2 <- 'TELESSAUDE|UNIDADE MOVEL|DOMICILIAR|PSICOSSOCIAL|FARMACIA|DE ORGAOS'
  
  # apply filter 5
  cnes_filter5 <- cnes_filter4[ estabelecimento %nlike% to_remove1 ]
  cnes_filter5 <- cnes_filter5[ tipo_unidade %nlike% to_remove2 ]
  # test >>> cnes_filter6[ CNES =='6771963']
  
  
  
  # table(cnes_filter5$complex_baix_ambu_est, useNA = "always")
  # table(cnes_filter5$complex_baix_hosp_mun, useNA = "always")
  # table(cnes_filter5$health_low, useNA = "always")
  
  ### Organiza Nivel de atencao criando dummy
  
  
  # convert health facilities Hierarchy into dummy variables
  cnes_filter5[, health_low := ifelse(complex_baix_ambu_est=='X'|
                                        complex_baix_ambu_mun=='X' |
                                        complex_baix_hosp_est=='X' |
                                        complex_baix_hosp_mun=='X' , 1, 0)]
  
  cnes_filter5[, health_med := ifelse(complex_medi_ambu_est=='X'|
                                        complex_medi_ambu_mun=='X' |
                                        complex_medi_hosp_est=='X' |
                                        complex_medi_hosp_mun=='X' , 1, 0)]
  
  cnes_filter5[, health_high := ifelse(complex_alta_ambu_est=='X'|
                                         complex_alta_ambu_mun=='X' |
                                         complex_alta_hosp_est=='X' |
                                         complex_alta_hosp_mun=='X' , 1, 0)]
  
  
  # table(cnes_filter5$health_low, useNA = "always")  # 3593
  # table(cnes_filter5$health_med, useNA = "always")  # 4224
  # table(cnes_filter5$health_high, useNA = "always") # 858
  
  # nrow(cnes_filter5) # 4872 obs
  
  
  cnes_filter5[, cnes := str_pad(cnes, width = 7, side = "left", pad = 0)]
  
  
  # save it
  write_rds(cnes_filter5, sprintf("../../data/acesso_oport/hospitais/%s/hospitais_filter_%s.rds", ano, ano))
  
  
}













health_geocode <- function(ano, run_gmaps = FALSE) {
  
  ### Open filtered data -----------------------------
  
  cnes_filtered <- read_rds(sprintf("../../data/acesso_oport/hospitais/%s/hospitais_filter_%s.rds", ano, ano))
  
  # table(nchar(cnes_filtered$cnes))
  
  
  if (ano != 2017) {
    
    # geocode only estabs that werent geocoded in the previous year
    cnes_previous <- read_rds(sprintf("../../data/acesso_oport/hospitais/%i/hospitais_filter_geocoded_pmaq_%i.rds", ano-1, ano-1)) %>%
      select(cnes, lat_digits, lon, lat, ndigitos, latlon, MatchedAddress, SearchedAddress, PrecisionDepth, geocode_engine, year_geocode)
    
    cnes_filtered_togeo <- cnes_filtered %>% filter(cnes %nin% cnes_previous$cnes)
  
    } else {cnes_filtered_togeo <- cnes_filtered}
  
  
  ### Corrigir latitude e  longitude  ---------------------------------
  
  # identificar cidades do projeto com dois digitos de latitude
  munis <- purrr::map_dfr(dir("../../data-raw/municipios/2017/", full.names = TRUE), read_rds) %>%
    as_tibble() %>%
    st_sf() %>%
    st_centroid() %>%
    # transformar para lon-lat %>%
    sfc_as_cols() %>%
    # quantos digitos as latitudes tem antes da virgula?
    mutate(lat_digits = sub("^-?(\\d+)[[:punct:]]{1}\\d+$", "\\1", lat)) %>%
    mutate(lat_digits = nchar(lat_digits)) %>%
    # municipio so tem 6 digitos
    mutate(code_muni = substr(code_muni, 1,6)) %>%
    # selecionar so as colunas necessarias
    dplyr::select(code_muni, lat_digits)
  
  # trazer a quantidade de digitos para o cnes19
  cnes19_df_digitos <- cnes_filtered_togeo %>%
    rename(code_muni = ibge) %>%
    # selecionar so os municipios do projeto
    filter(code_muni %in% substr(munis_df$code_muni, 1, 6)) %>%
    mutate(code_muni = as.character(code_muni)) %>%
    left_join(munis, by = "code_muni")
  
  # criar dataframe com as coordenadas ajeitadas
  cnes19_df_coords_fixed <- cnes19_df_digitos %>%
    # primeiro, tirar tudo que for ponto ou virgula
    mutate(lon = gsub("(\\.|,)", "", longitude),
           lat = gsub("(\\.|,)", "", latitude)) %>%
    # tirar sinal de negativo
    mutate(lon = gsub("-", "", lon),
           lat = gsub("-", "", lat)) %>%
    # o ponto na longitude vai ser sempre depois do segundo numerico, e vai ser sempre negativo
    mutate(lon = sub("(^\\d{2})(\\d+)", "-\\1\\.\\2", lon)) %>%
    # o ponto na latitude vai depender do nchar
    mutate(lat = ifelse(lat_digits == 1, sub("(^\\d{1})(\\d+)", "-\\1\\.\\2", lat),
                        sub("(^\\d{2})(\\d+)", "-\\1\\.\\2", lat))) %>%
    # delete E+16 from coords
    mutate(lon = str_replace(lon, "E\\+\\d{2}", ""),
           lat = str_replace(lon, "E\\+\\d{2}", "")) %>%
    # delete undefined
    mutate(lon = ifelse(lon == "undefined", NA, lon),
           lat = ifelse(lat == "undefined", NA, lat)) %>%
    mutate(lon = as.numeric(lon),
           lat = as.numeric(lat))
  
  
  
  
  ###### Identificar CNES com lat/long problematicos
  
  # A - poucos digitos
  # B - fora dos limites do municipio
  # C - com coordenadas NA
  # D - mais de 5 estabelecimentos com coordenadas iguais
  
  
  # qual o nivel de precisao das coordenadas deve ser aceito?
  # 0.01 = 1113.2 m
  # 0.001 = 111.32 m
  # 0.0001 = 11.132 m
  # 0.00001 = 1.1132 m
  
  
  # A) Numero de digitos de lat/long apos ponto
  setDT(cnes19_df_coords_fixed)[, ndigitos := nchar(sub("(-\\d+)\\.(\\d+)", "\\2", lat))]
  A_estbs_pouco_digito <- cnes19_df_coords_fixed[ ndigitos <=2,]
  
  
  # B) fora dos limites do municipio
  
  # carrega shapes
  shps <- purrr::map_dfr(dir("../../data-raw/municipios/", recursive = TRUE, full.names = TRUE), read_rds) %>% as_tibble() %>% st_sf() %>%
    st_transform(4326)
  
  # convert para sf
  cnes19_df_coords_fixed_df <- cnes19_df_coords_fixed[!(is.na(lat))] %>% st_as_sf( coords = c('lon', 'lat'), crs = 4326)
  temp_intersect <- sf::st_join(cnes19_df_coords_fixed_df, shps)
  
  # CNES que cairam fora de algum municipio
  B_muni_fora <- subset(temp_intersect, is.na(name_muni))
  
  
  # C) Lat lon NA (feito mais a frente)
  
  
  # D) mais de 5 estabelecimentos com coordenadas iguais
  
  # junta lat lon
  cnes19_df_coords_fixed$latlon <- paste0(cnes19_df_coords_fixed$lat, '/', cnes19_df_coords_fixed$lon)
  
  # freq de lat lon repetido
  tab_latlon <- cnes19_df_coords_fixed %>% count(latlon, sort = T)
  C_latlon_problema <- subset(tab_latlon, n >3 & latlon != "NA/NA")
  
  
  
  # juntar todas municipios com erro de lat/lon
  munis_problemaA <- subset(cnes19_df_coords_fixed, cnes %in% A_estbs_pouco_digito$cnes ) 
  munis_problemaB <- subset(cnes19_df_coords_fixed, cnes %in% B_muni_fora$cnes )
  munis_problemaC <- cnes19_df_coords_fixed[ is.na(lat), ]
  munis_problemaD <- subset(cnes19_df_coords_fixed, latlon %in% C_latlon_problema$latlon)
  
  
  
  munis_problema <- rbind(munis_problemaA, munis_problemaB, munis_problemaC, munis_problemaD)
  munis_problema <- dplyr::distinct(munis_problema, cnes, .keep_all=T) # remove duplicates
  
  # lista de enderecos com problema
  enderecos <- munis_problema %>% mutate(fim = paste0(logradouro, ", ", numero, " - ", municipio, ", ", uf, " - CEP ", cep)) %>% .$fim
  
  # registrar Google API Key
  my_api <- data.table::fread("../../data-raw/google_key.txt", header = F)
  register_google(key = my_api$V1[4])
  
  if (run_gmaps) {
    
    a <- menu(choices = c("Yes", "No"), title = sprintf("Are  you sure you wanna send %s address to Google Maps?", length(enderecos)))
    
    if (a == 1) {
      
      message("Running gmaps, this may take a while")
  
  # geocode
  coordenadas_google1 <- ggmap::geocode(enderecos, output = "all")
  
  # identify list names as cnes
  names(coordenadas_google1) <- munis_problema$cnes
  
  # save
  write_rds(coordenadas_google1, sprintf("../../data/acesso_oport/hospitais/%s/geocode/hospitais_geocode_%s_output_google1.rds", ano, ano))
  
  
    }
    
  } else {
  
    coordenadas_google1 <- read_rds(sprintf("../../data/acesso_oport/hospitais/%s/geocode/hospitais_geocode_%s_output_google1.rds", ano, ano))
  
  }
  
  create_dt <- function(x) {
    
    precision_depth0 <- ifelse(length(x[["results"]][[1]][["address_components"]]) > 0, 
                               x[["results"]][[1]][["address_components"]], 
                               NA)
    
    # check length from precision depth
    precision_depth <- ifelse(is.na(precision_depth0), NA,
                              ifelse(length(precision_depth0[[1]]$types) > 0,
                                     precision_depth0[[1]]$types[[1]], 
                                     NA))
    
    a <- data.table(
      MatchedAddress = ifelse(!is.null(x[["results"]][[1]][["formatted_address"]]), x[["results"]][[1]][["formatted_address"]], NA),
      # PrecisionDepth = ifelse(!is.null(x[["results"]][[1]][["address_components"]][[1]]$types[[1]]), x[["results"]][[1]][["address_components"]][[1]]$types[[1]], NA),
      PrecisionDepth = precision_depth,
      lon = ifelse(!is.null(x[["results"]][[1]][["geometry"]][["location"]][["lng"]]), x[["results"]][[1]][["geometry"]][["location"]][["lng"]], NA),
      lat = ifelse(!is.null(x[["results"]][[1]][["geometry"]][["location"]][["lat"]]), x[["results"]][[1]][["geometry"]][["location"]][["lat"]], NA)
    )
    
  }
  
  
  estabs_problema_geocoded <- lapply(coordenadas_google1, create_dt)
  # estabs_problema_geocoded <- lapply(coordenadas_google1, possibly(create_dt, otherwise = "erro"))
  
  # rbind as data.table
  estabs_problema_geocoded_dt <- rbindlist(estabs_problema_geocoded, idcol = "cnes",
                                           use.names = TRUE)
  
  # unique(estabs_problema_geocoded_dt$cnes) %>% length()
  
  # identify searchedaddress
  searchedaddress <- filter(munis_problema, cnes %in% names(coordenadas_google1)) %>%
    mutate(SearchedAddress =  paste0(logradouro, ", ", numero, " - ", municipio, ", ", uf, " - CEP ", cep)) %>% select(cnes, SearchedAddress) %>%
    distinct(cnes, .keep_all = TRUE)
  estabs_problema_geocoded_dt <- left_join(estabs_problema_geocoded_dt, searchedaddress, by = "cnes") %>% setDT()
  
  
  # identify problem
  estabs_problema_geocoded_dt[, geocode_engine := 'gmaps_prob1']
  # identify quality
  estabs_problema_geocoded_dt[is.na(lon), ':='(PrecisionDepth = "address_not_found")]
  
  # table(estabs_problema_geocoded_dt$PrecisionDepth, useNA = 'always')
  
  
  
  #### GOOGLE 2, so ceps ------------------------
  
  # ainda ha escolas mal georreferenciadas!
  # identificar essas escolas e separa-las
  # convert para sf
  hospitais_google_mal_geo <- estabs_problema_geocoded_dt %>%
    filter(!is.na(lat)) %>% 
    st_as_sf(coords = c('lon', 'lat'), crs = 4326) %>%
    sf::st_join(shps %>% st_buffer(0.0008)) %>%
    # escolas que cairam fora de algum municipio, a serem georreferenciadas na unha
    filter(is.na(name_muni)) %>%
    select(cnes, SearchedAddress)
  
  
  # identify these address as outside the city
  estabs_problema_geocoded_dt <- estabs_problema_geocoded_dt[cnes %in% hospitais_google_mal_geo$cnes,
                                                             PrecisionDepth := 'address_outside_city']
  
  # table(estabs_problema_geocoded_dt$PrecisionDepth, useNA = 'always')
  
  
  # bring to the original dataset
  # # bring CEP's fixed to the original fixed dataset problems 1 and 2
  # rais_problema1e2_geocoded[cep_problema_geocoded_dt_fixed, on = "id_estab",
  #                           c("MatchedAddress", "PrecisionDepth", "lon", "lat", "geocode_engine") := 
  #                             list(i.MatchedAddress, i.PrecisionDepth, i.lon, i.lat, i.geocode_engine)]
  
  # identify columns 
  # cnes19_df_coords_fixed[, co_entidade := as.character(co_entidade)]
  cnes19_df_coords_fixed[, MatchedAddress := paste0(logradouro, ", ", numero, " - ", municipio, ", ", uf, " - CEP ", cep)]
  cnes19_df_coords_fixed[, SearchedAddress := paste0(logradouro, ", ", numero, " - ", municipio, ", ", uf, " - CEP ", cep)]
  cnes19_df_coords_fixed[, PrecisionDepth := "cnes"]
  cnes19_df_coords_fixed[, geocode_engine := "cnes"]
  
  
  cnes19_df_coords_fixed[estabs_problema_geocoded_dt, on = "cnes",
                         c("MatchedAddress", "PrecisionDepth", "lon", "lat", "geocode_engine") := 
                           list(i.MatchedAddress, i.PrecisionDepth, i.lon, i.lat, i.geocode_engine)]  
  
  # identify year
  cnes19_df_coords_fixed[, year_geocode := ano]
  
  # table(cnes19_df_coords_fixed$PrecisionDepth, useNA = 'always')
  # table(cnes19_df_coords_fixed$geocode_engine, useNA = 'always')
  
  
  # bring new geocoded coordinates to the year
  cnes_filtered_fim <- merge(cnes_filtered,
                                 cnes19_df_coords_fixed[, .(cnes, lat_digits, lon, lat, ndigitos, latlon,
                                                            MatchedAddress, SearchedAddress, PrecisionDepth, geocode_engine, year_geocode)],
                                 by = "cnes",
                                 all.x = TRUE)
  
  # table(cnes_filtered_2018_fim$PrecisionDepth, useNA = 'always')
  
  
  if (ano != "2017") {
    
  # bring old coordinates from preivous year
  cnes_filtered_fim[cnes_previous, on = "cnes",
                    c('lat_digits', 'lon', 'lat', 'ndigitos', 'latlon',
                      'MatchedAddress', 'SearchedAddress', 'PrecisionDepth', 'geocode_engine', 'year_geocode') := 
                      list(i.lat_digits, i.lon, i.lat, i.ndigitos, i.latlon,
                           i.MatchedAddress, i.SearchedAddress, i.PrecisionDepth, i.geocode_engine, i.year_geocode)]
    
  }
  
  
  
  # Bring PMAQ data ---------------------------------
  
  attr(cnes_filtered_fim$cnes, "sorted") <- NULL
  
  
  # table(hospitais$geocode_engine, useNA = 'always')
  
  ###### Usar dados de lat/lon quando eles existirem na PMAQ (estabelecimentos de baixa complexidade)
  # Read PMAQ data
  pmaq_df_coords_fixed <- fread('../../data-raw/hospitais/2019/PMAQ/pmaq_df_coords_fixed.csv', colClasses = 'character') %>%
    select(code_muni, cnes = CNES_FINAL, lon, lat) %>%
    mutate(cnes = str_pad(cnes, width = 7, side = "left", pad = 0),
           PrecisionDepth = "PMAQ",
           geocode_engine = "PMAQ") %>%
    mutate(lon = as.numeric(lon),
           lat = as.numeric(lat)) %>% setDT()
  
  
  cnes_filtered_fim[pmaq_df_coords_fixed, on = "cnes",
                    c("PrecisionDepth", "lon", "lat", "geocode_engine") := 
                      list(i.PrecisionDepth, i.lon, i.lat, i.geocode_engine)]
  
  
  
  
  # 6) Salvar dados de saude ------------------------------------------------------------------
  
  cnes_filtered_fim %>%
    rename(code_muni = ibge) %>%
    # select(CNES, code_muni, health_low, health_med, health_high)
    readr::write_rds(sprintf("../../data/acesso_oport/hospitais/%s/hospitais_filter_geocoded_pmaq_%s.rds", ano, ano))
  
  
  
  
}

