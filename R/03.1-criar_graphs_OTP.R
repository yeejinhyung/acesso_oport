#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###### 0.3.3 Criacao de graphs no OpenTripPlanner

# Programa OpenTripPlanner.jar deve ser baixado manual desse link
# https://repo1.maven.org/maven2/org/opentripplanner/otp/1.4.0/




# carregar bibliotecas
source('./R/fun/setup.R')



# FUNCAO PARA CONSTRUIR GRAPH (SO RODAR UMA VEZ!) -------------------------
# graph.obj é salvo na pasta './otp/graphs/cidade

construir_graph_muni <- function(sigla_muni, ano, otp = "../../otp/programs/otp-1.4.0-shaded.jar",
                                 memory = 12000) {
  
  if (file.exists(sprintf("../../otp/graphs/%s/%s/Graph.obj", ano, sigla_muni))) {
    file.remove(sprintf("../../otp/graphs/%s/%s/Graph.obj", ano, sigla_muni))
  }
  
  dir <-  "../../otp"
  router <-  sprintf("%s/%s", ano, sigla_muni)
  
  message(paste0("Criando Graph da cidade ",sigla_muni, " para o ano ", ano, "\n"))
  
  text <- paste0("java8 -Xmx", memory, "M -jar \"", otp, "\" --build \"", 
                 dir, "/graphs/", router, "\"")
  
  options(max.print = 10000000)
  
  a <- system(text, intern = TRUE)
  
  sink(file = sprintf("../../otp/graphs/%s/%s/graph_log_%s_%s.txt", ano, sigla_muni, sigla_muni, ano))
  print(a)
  sink()
  
  options(max.print = 1000)
}


# aplicar funcao ------------------------------------------------------------------------------
lapply(munis_df$abrev_muni, construir_graph_muni, ano = 2017)
lapply(munis_df$abrev_muni, construir_graph_muni, ano = 2018)
lapply(munis_df$abrev_muni, construir_graph_muni, ano = 2019)

construir_graph_muni('poa', 2018)
construir_graph_muni('poa', 2017)
construir_graph_muni('for', 2017)
construir_graph_muni('spo', 2019)
construir_graph_muni('cam', 2019)


