Indicadores de acessibilidade
================
Ipea
27 de março de 2019

Indicador de acesso cumulativo a oportunidades
==============================================

Com a quantidade de oportunidades (saúde, educação, empregos) e a matriz de tempo de viagem calculadas entre os hexágonos, é hora da etapa de calcular o indicador de acessibilidade. Como projeto piloto, será calculado o indicador para as cidades de Fortaleza, Belo Horizonte e Rio de Janeiro.

``` r
acess_acumu <- function(cidade, tempo, res = 8) {
  
  res1 <- sprintf("0%s", res)
  
  dir_matriz <- sprintf("../data/output_ttmatrix/traveltime_matrix_%s_python.csv", cidade)
    
  # abrir matriz
  matriz_for <- read_csv(dir_matriz) %>%
    select(origin, destination, travel_time) %>%
    mutate(travel_time = travel_time/60)
  
  dir_hex <- sprintf("../data/hex_agregados/hex_agregado_%s_%s.rds", cidade, res1)
  
  # abrir oportunidades com hexagonos
  hexagonos_for_sf <- read_rds(dir_hex) %>%
    ungroup()
  
  # so populacao
  hexagonos_for_pop <- hexagonos_for_sf %>%
    st_set_geometry(NULL) %>%
    select(id_hex, pop_total)
  
  # outras variaveis
  hexagonos_for_vars <- hexagonos_for_sf %>%
    st_set_geometry(NULL) %>%
    select(-pop_total)
  
  
  # quantas oportunidades de escolas podem ser acessadas em menos de 40 minutos?
  # IDEIA: em de escolas, nao seria melhor considerar matriculas?
  
  access_ac_for <- matriz_for %>%
    left_join(hexagonos_for_vars, by = c("destination" = "id_hex")) %>%
    left_join(hexagonos_for_pop, by = c("origin" = "id_hex")) %>%
    group_by(origin, pop_total) %>%
    filter(travel_time < tempo) %>%
    summarise_at(vars(saude_total, escolas_total), sum) %>%
    mutate(tempo_viagem = tempo)
  
  access_ac_for_fim <- hexagonos_for_sf %>%
    select(id_hex) %>%
    left_join(access_ac_for, by = c("id_hex" = "origin"))
}
```

Fortaleza
---------

``` r
acess_ac_for <- map_dfr(c(15, 30, 45, 60), ~ acess_acumu(cidade = "for", tempo = .x)) %>%
  as_tibble() %>%
  st_sf()

# acess_ac_for <- map_dfr(seq(15, 60, 5), ~ acess_acumu(cidade = "for", tempo = .x)) %>%
#   as_tibble() %>%
#   st_sf()


# write_rds(acess_ac_for, "../data/output_access/acess_ac_for.rds")


# adicionar competicao

# access_ac_for_fim %>%
#   select(id_hex, pop_total, saude_total) %>%
#   mutate(saude_por_pessoa = (saude_total/pop_total)*10) %>%
#   View()


# mapview(access_ac_for_fim, zcol = "saude_total")
```

Visualizar o indicador de acessibilidade para Fortaleza:

``` r
acess_ac_for %>%
 select(saude_total, tempo_viagem) %>%
  filter(!is.na(tempo_viagem)) %>%
  ggplot()+
  geom_sf(aes(fill = saude_total))+
  theme_bw()+
  theme(legend.position = "bottom")+
  scale_fill_gradientn(colors = RColorBrewer::brewer.pal(6, "PuRd")) +
  facet_wrap(~tempo_viagem) +
acess_ac_for %>%
 select(escolas_total, tempo_viagem) %>%
  filter(!is.na(tempo_viagem)) %>%
  ggplot()+
  geom_sf(aes(fill = escolas_total))+
  theme_bw()+
  theme(legend.position = "bottom")+
  scale_fill_gradientn(colors = RColorBrewer::brewer.pal(6, "PuRd")) +
  facet_wrap(~tempo_viagem)
```

![](05_acessibilidade_files/figure-markdown_github/viz%20for-1.png)

``` r
# library(gganimate)
# 
# acess_ac_for %>%
#  select(saude_total, tempo_viagem) %>%
#   filter(!is.na(tempo_viagem)) %>%
#   # filter(tempo_viagem %in% c(15, 20)) %>%
#   ggplot()+
#   geom_sf(aes(fill = saude_total))+
#   theme_bw()+
#   theme(legend.position = "bottom")+
#   scale_fill_gradientn(colors = RColorBrewer::brewer.pal(6, "PuRd")) +
#   labs(title = "Tempo de viagem: {frame_time} minutos")+
#   transition_time(as.integer(tempo_viagem))
```

Belo Horizonte
--------------

Para Belo Horizonte:

``` r
acess_ac_bel <- map_dfr(c(15, 30, 45, 60), ~ acess_acumu(cidade = "bel", tempo = .x)) %>%
  as_tibble() %>%
  st_sf()

# write_rds(acess_ac_bel, "../data/output_access/acess_ac_bel.rds")
```

Visualizar o indicador de acessibilidade para Belo Horizonte:

``` r
acess_ac_bel %>%
 select(saude_total, tempo_viagem) %>%
  filter(!is.na(tempo_viagem)) %>%
  ggplot()+
  geom_sf(aes(fill = saude_total))+
  theme_bw()+
  theme(legend.position = "bottom")+
  scale_fill_gradientn(colors = RColorBrewer::brewer.pal(6, "PuRd")) +
  facet_wrap(~tempo_viagem) +
acess_ac_bel %>%
  select(escolas_total, tempo_viagem) %>%
  filter(!is.na(tempo_viagem)) %>%
  ggplot()+
  geom_sf(aes(fill = escolas_total))+
  theme_bw()+
  theme(legend.position = "bottom")+
  scale_fill_gradientn(colors = RColorBrewer::brewer.pal(6, "PuRd")) +
  facet_wrap(~tempo_viagem)
```

![](05_acessibilidade_files/figure-markdown_github/viz%20bel-1.png)

Rio de Janeiro
--------------

Para o Rio de Janeiro:

``` r
acess_ac_rio <- map_dfr(c(15, 30, 45, 60), ~ acess_acumu(cidade = "rio", tempo = .x)) %>%
  as_tibble() %>%
  st_sf()


# write_rds(acess_ac_rio, "../data/output_access/acess_ac_rio.rds")
```

Visualizar o indicador de acessibilidade para Rio de Janeiro:

``` r
acess_ac_rio %>%
  select(saude_total, tempo_viagem) %>%
  filter(!is.na(tempo_viagem)) %>%
  ggplot()+
  geom_sf(aes(fill = saude_total))+
  theme_bw()+
  scale_fill_gradientn(colors = RColorBrewer::brewer.pal(6, "PuRd")) +
  # theme(legend.position = "bottom")+
  facet_wrap(~tempo_viagem) +
acess_ac_rio %>%
  select(escolas_total, tempo_viagem) %>%
  filter(!is.na(tempo_viagem)) %>%
  ggplot()+
  geom_sf(aes(fill = escolas_total))+
  theme_bw()+
  scale_fill_gradientn(colors = RColorBrewer::brewer.pal(6, "PuRd"))+
  # theme(legend.position = "bottom")+
  facet_wrap(~tempo_viagem)+
    plot_layout(ncol = 1)
```

![](05_acessibilidade_files/figure-markdown_github/viz%20rio-1.png)

Indicador de tempo mínimo até a oportunidade mais próxima
=========================================================

``` r
acess_min <- function(cidade, res = 8) {
  
  res1 <- sprintf("0%s", res)
  
  dir_matriz <- sprintf("../data/output_ttmatrix/traveltime_matrix_%s_python.csv", cidade)
    
  # abrir matriz
  matriz_for <- read_csv(dir_matriz) %>%
    select(origin, destination, travel_time) %>%
    mutate(travel_time = travel_time/60) %>%
    # filter(!(origin == destination))
    identity()
  
  dir_hex <- sprintf("../data/hex_agregados/hex_agregado_%s_%s.rds", cidade, res1)
  
  # abrir oportunidades com hexagonos
  hexagonos_for_sf <- read_rds(dir_hex) %>%
    ungroup()
  
  # so populacao
  hexagonos_for_pop <- hexagonos_for_sf %>%
    st_set_geometry(NULL) %>%
    select(id_hex, pop_total)
  
  # outras variaveis
  hexagonos_for_vars <- hexagonos_for_sf %>%
    st_set_geometry(NULL) %>%
    select(-pop_total)
  
  access_ac_for <- matriz_for %>%
    left_join(hexagonos_for_vars, by = c("destination" = "id_hex")) %>%
    left_join(hexagonos_for_pop, by = c("origin" = "id_hex"))
  
  access_ac_for_long <- access_ac_for %>%
    tidyr::gather(key = "atividade", value = "n", saude_total:escolas_total) %>%
    filter(n != 0) %>%
    group_by(origin, pop_total, atividade) %>%
    slice(which.min(travel_time)) %>%
    # se a atividade for na mesma zona, definir tempo de viagem de 10 minutos
    mutate(travel_time = ifelse(origin == destination, 10, travel_time))
  
  access_ac_for_fim <- hexagonos_for_sf %>%
    select(id_hex) %>%
    left_join(access_ac_for_long, by = c("id_hex" = "origin"))
  
}
# 
# cidade <- "rio"
# 
# teste <- acess_min("for")
# 
# teste %>%
#   filter(atividade == "saude_total") %>%
#   mapview(zcol = "travel_time")
```

Aplicar para Fortaleza
----------------------

``` r
acess_min_for <- acess_min("for")

# write_rds(acess_min_for, "../data/output_access/acess_min_for.rds")
```

Visualizar:

``` r
acess_min_for %>%
  filter(!is.na(travel_time)) %>%
  mutate(travel_time_v1 = ifelse(travel_time > 45, 45, travel_time)) %>%
  ggplot()+
  geom_sf(aes(fill = travel_time_v1))+
  theme_bw()+
  scale_fill_gradientn(colors = RColorBrewer::brewer.pal(6, "PuRd"),
                       breaks = c(0, 15, 30, 45),
                       labels = c("0", "15", "30", "45+")) +
  facet_wrap(~atividade)
```

![](05_acessibilidade_files/figure-markdown_github/viz%20acess_min_for-1.png)

Aplicar para Belo Horizonte
---------------------------

``` r
acess_min_bel <- acess_min("bel")

# write_rds(acess_min_bel, "../data/output_access/acess_min_bel.rds")
```

Visualizar:

``` r
acess_min_bel %>%
  filter(!is.na(travel_time)) %>%
  mutate(travel_time_v1 = ifelse(travel_time > 45, 45, travel_time)) %>%
  ggplot()+
  geom_sf(aes(fill = travel_time_v1))+
  theme_bw()+
  scale_fill_gradientn(colors = RColorBrewer::brewer.pal(6, "PuRd"),
                       breaks = c(0, 15, 30, 45),
                       labels = c("0", "15", "30", "45+")) +
  facet_wrap(~atividade)
```

![](05_acessibilidade_files/figure-markdown_github/viz%20acess_min_bel-1.png)

Aplicar para o Rio de Janeiro
-----------------------------

``` r
acess_min_rio <- acess_min("rio")

# write_rds(acess_min_rio, "../data/output_access/acess_min_rio.rds")
```

Visualizar:

``` r
acess_min_rio %>%
  filter(!is.na(travel_time)) %>%
  mutate(travel_time_v1 = ifelse(travel_time > 60, 60, travel_time)) %>%
  ggplot()+
  geom_sf(aes(fill = travel_time_v1))+
  theme_bw()+
  scale_fill_gradientn(colors = RColorBrewer::brewer.pal(6, "PuRd"),
                       breaks = c(0, 15, 30, 45, 60),
                       labels = c("0", "15", "30", "45","60+")) +
  facet_wrap(~atividade, ncol = 1)
```

![](05_acessibilidade_files/figure-markdown_github/viz%20acess_min_rio-1.png)
