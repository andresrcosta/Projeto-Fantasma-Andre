#########################################################################
# Definindo as cores dos gráficos de acordo com a Padronização da ESTAT #
#########################################################################

cores_estat <- c("#A11D21", "#003366", "#CC9900", "#663333", "#FF6600", "#CC9966", "#999966", "#006606", "#008091", "#041835", "#666666")
theme_estat <- function(...) {
  theme <- ggplot2:: theme_bw() +
    ggplot2:: theme(
      axis.title.y = ggplot2:: element_text(colour = "black",
                                            size = 12),
      axis.title.x = ggplot2:: element_text(colour = "black",
                                            size = 12),
      axis.text = ggplot2:: element_text(colour = "black", size
                                         = 9.5),
      panel.border = ggplot2:: element_blank (),
      axis.line = ggplot2:: element_line(colour = "black"),
      legend.position = "top",
      ...
    )
  return(
    list(
      theme ,
      scale_fill_manual(values = cores_estat),
      scale_colour_manual(values = cores_estat)
    )
  )
}

#########################
# Carregando os Pacotes #
#########################

# Lista de pacotes a serem verificados e carregados

pacotes <- c("tidyverse", "xtable", "broom", "nortest", "car", "reshape2", "vcd")

# Verificando se os pacotes não estão instalados e instalá-los se necessário

pacotes_instalados <- pacotes[!(pacotes %in% installed.packages())]
if (length(pacotes_instalados) > 0) {
  install.packages(pacotes_instalados)
}

# Carregando os pacotes já instalados

pacotes_carregados <- pacotes[!(pacotes %in% pacotes_instalados)]
if (length(pacotes_carregados) > 0) {
  invisible(lapply(pacotes_carregados, library, character.only = TRUE))
}

# Defindo o Diretório

setwd("")

################################
# Organizando o banco de dados #
################################

# Importando os arquivos

vendas <- read.csv("vendas.csv", encoding = "UTF-8")
vendas_secundario <- vendas
devolução <- read.csv("devolução_atualizado.csv" , encoding = "UTF-8")
devolucao_secundario <- devolução

# Confirmando que todas as compras são de 2022

# Filtrando as compras de 2022 usando expressoes regulares

vendas_secundario <- vendas_secundario %>%
  filter(grepl("2022", Data.Venda))

# Formatando as as colunas

novo_nome_colunas_1 <- c(
  "X" = "X",
  "...1.x" = "Índice X",
  "Data.Venda" = "Data da venda",
  "User.ID" = "ID do usuário",
  "Product.ID" = "ID do produto",
  "Product.Name" = "Nome do produto",
  "Brand" = "Marca",
  "Category" = "Categoria",
  "Price" = "Preço",
  "Rating" = "Avaliação",
  "Color" = "Cor",
  "Size" = "Tamanho",
  "Unique.ID" = "ID exclusivo",
  "...1.y" = "Índice Y",
  "Motivo.devolução" = "Motivo de devolução"
)

colnames(vendas_secundario) <- novo_nome_colunas_1


# Formatando as datas das vendas

# Função para padronizar as datas

padronizar_data <- function(data) {
  if (is.na(data)) {
    return(NA)  # Se a data for NA, retorne NA
  } else if (nchar(data) == 10) {
    return(data)  # Já está no formato desejado
  } else {
    partes_data <- unlist(strsplit(data, "/"))
    if (length(partes_data) == 3) {
      mes <- sprintf("%02d", as.numeric(partes_data[1]))
      dia <- sprintf("%02d", as.numeric(partes_data[2]))
      ano <- partes_data[3]
      data_formatada <- paste(mes, dia, ano, sep = "/")
      return(data_formatada)
    } else {
      return(NA)  # Se os componentes da data não puderem ser extraídos, retorne NA
    }
  }
}

# Aplicando a função de padronização na coluna "Data_da_venda"

vendas_secundario$`Data da venda` <- sapply(vendas_secundario$`Data da venda`, padronizar_data)

# Função para extrair o nome do mês
extrair_nome_mes <- function(data) {
  data <- mdy(data)  # Converte a data para o formato padrão mês/dia/ano
  nome_mes <- month(data, label = TRUE)
  return(nome_mes)
}

# Aplicando a função e criando uma coluna com o mês da compra

vendas_secundario$`Mês da compra` <- sapply(vendas_secundario$`Data da venda`, extrair_nome_mes)

# Garatindo que os valores da coluna preço sejam numéricos

vendas_secundario$Preço <- as.numeric(vendas_secundario$Preço)

# Criando um dataset sem devolução

vendas_sem_devolucao <- vendas_secundario[is.na(vendas_secundario$`Motivo de devolução`), ]

vendas_sem_devolucao <- vendas_sem_devolucao[, !(names(vendas_sem_devolucao) %in% c("Índice Y", "Motivo de devolução"))]

# Incluindo o novo arquivo de devoluluções enviado pela cliente
# A cliente enviou um email de errata informando que as devoluções do primeiro
# banco estavam incorretas

# Formatando o banco de devolução

novo_nome_colunas_2 <- c(
  "X" = "X",
  "Unique.ID" = "ID exclusivo",
  "Motivo.devolução" = "Motivo de devolução 2"
)

colnames(devolucao_secundario) <- novo_nome_colunas_2

# Juntando os bancos (com e sem devolução - após a correção da cliente)

# Unindo os dataframes com base na coluna "ID Exclusivo"

vendas_final_teste <- left_join(vendas_secundario, devolucao_secundario, by = "ID exclusivo")

# Dataset completo formatado

vendas_final <- vendas_final_teste

######################
##### Importante ##### 
######################

# 1 - o banco de dados utilizado foi formatado no código formatacao.R
# 2 - O tema dos gráficos está no começo do código completo do github

######################################################
#### Analise 1 - Faturamento anual por categoria #####
######################################################

# Está sendo utilizado o datset sem as devoluções, pois os produtos devolvidos
# não entram no faturamento #

# Clonando o dataset para não aplicar erros aos dados originais

vendas_analise_1 <-vendas_sem_devolucao

# Listando as categorias

tipos_categorias <- unique(vendas_analise_1$Categoria)

print(tipos_categorias)

# Retirando os NAS#

vendas_analise_1 <- subset(vendas_analise_1, complete.cases(`Data da venda`,Categoria,Preço))

# Garantido (novamente) que os valores da coluna preço sejam numericos #

vendas_analise_1$Preço <- as.numeric(vendas_analise_1$Preço)
vendas_analise_1$Preço

# Agrupando o faturamento anual por categoria
faturamento_anual <- vendas_analise_1 %>%
  group_by(Categoria) %>%
  summarise(Faturamento = sum(Preço))

# Gráfico de barras para o faturamento anual por categoria

ggplot(faturamento_anual, aes(x = Categoria, y = Faturamento)) +
  geom_bar(stat = "identity", fill = "#A11D21", width = 0.7) +
  geom_text(
    aes(label = paste(Faturamento, " (", scales::percent(Faturamento / sum(Faturamento)), ")"),
        group = Categoria),
    position = position_dodge(width = 0.9),
    vjust = -0.5,
    size = 3
  ) +
  labs(x = "Categoria", y = "Faturamento") +
  scale_y_continuous(limits = c(0, 15000), breaks = seq(0, 15000, by = 5000)) +
  theme_estat()
ggsave("faturamento_anual_categoria.pdf", width = 158, height = 93, units = "mm")

# Agrupar o dataframe por Mês da compra e Categoria
# para calcular o faturamento mensal #

faturamento_mensal <- vendas_analise_1 %>%
  group_by(`Mês da compra`, Categoria) %>%
  summarise(Faturamento = sum(Preço))

# Gráfico de linhas multivariado para o fafturamento mensal por categoria

ggplot(faturamento_mensal) +
  aes(x = `Mês da compra`, y = Faturamento, group = Categoria, color = Categoria) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  labs(x = "Mês", y = "Faturamento", color = "Categoria") +
  scale_y_continuous(limits = c(0, 3000), breaks = seq(0, 3000, by = 500)) +
  theme_estat()
ggsave("faturamento_mensal_categoria.pdf", width = 158, height = 93, units = "mm")

# Quadro de medidas resumo

quadro_resumo_analise_1 <- faturamento_mensal %>%
  group_by( Categoria ) %>% # caso mais de uma categoria
  summarize (Média = round(mean(Faturamento),2),
             `Desvio Padrão ` = round(sd(Faturamento),2),
             `Mínimo ` = round(min(Faturamento),2),
             `1º Quartil ` = round(quantile(Faturamento , probs = .25),2),
             Mediana = round(quantile(Faturamento , probs = .5),2),
             `3º Quartil ` = round(quantile(Faturamento , probs = .75),2),
             `Máximo ` = round(max(Faturamento),2)) %>% t() %>% as.data.frame()

xtable :: xtable(quadro_resumo_analise_1)

# Teste

# Testando a normalidade dos dados para implementar a ANOVA

categorias_analise_1 <- unique(vendas_analise_1$Categoria)

for (marca in Categorias_analise_1) {
  subset_data <- vendas_analise_2$Preço[vendas_analise_2$Marca == marca]
  result_ad_test <- ad.test(subset_data)
  print(paste("Teste Anderson-Darling para", marca))
  print(result_ad_test)
}

# Critério de normalidade satisfeito

#Anova para a média de preços entre as marcas

modelo_anova <- aov(Preço ~ Marca, data = vendas_analise_2)
resultado_anova <- summary(modelo_anova)

# Exibir os resultados da ANOVA
print(resultado_anova)

# Analisando as devoluções de produtos com defeito

# Usando o dataset completo

vendas_analise_1_parte_2 <-vendas_final

# Retirando NAS

vendas_analise_1_parte_2 <- subset(vendas_analise_1_parte_2, complete.cases(Categoria,`Motivo de devolução 2`,`Mês da compra`))

# Tipos de devoluções

tipos_devolucao <- unique(vendas_analise_1_parte_2$`Motivo de devolução 2`)

print(tipos_devolucao)

# Agrupando as devoluções

devolucoes_mensais_defeito <- vendas_analise_1_parte_2 %>%
  filter(`Motivo de devolução 2` == "Produto com defeito") %>%
  group_by(`Mês da compra`, Categoria) %>%
  summarise(Total_Devolucoes = n()) %>%
  ungroup()

xtable :: xtable(devolucoes_mensais_defeito)

# Gráfico de linhas multivariado para o total de devoluções por mês para cada motivo

ggplot(devolucoes_mensais_defeito) +
  aes(x = `Mês da compra`, y = Total_Devolucoes, group = Categoria, color = Categoria) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  labs(x = "Mês", y = "Total de devoluções", color = "Categoria") +
  scale_y_continuous(limits = c(0, max(devolucoes_mensais_defeito$Total_Devolucoes) + 5), breaks = seq(0, max(devolucoes_mensais_defeito$Total_Devolucoes) + 5, by = 5)) +
  theme_estat()
ggsave("devolucoes_mensais_defeito_final.pdf", width = 158, height = 93, units = "mm")

# Somando todos os preço

soma_precos_defeito_por_categoria <- vendas_analise_1_parte_2 %>%
  filter(`Motivo de devolução 2` == "Produto com defeito") %>%
  group_by(Categoria) %>%
  summarise(Total_Preco = sum(Preço, na.rm = TRUE)) %>%
  ungroup()

# Exibindo a soma dos preços por categoria

print(soma_precos_defeito_por_categoria)

xtable :: xtable(soma_precos_defeito_por_categoria)

# Análise das marcas, cores e tamanhos inidividualmente

# Retirando NAS

vendas_analise_1_marcas_parte_setores <- subset(vendas_analise_1, complete.cases(Categoria,Marca))

# Grafico de setores para categoria de marca, cor e tamanho

# Função para criar contagem e gráfico de barras para Marca, Cor ou Tamanho

gerar_contagem_grafico <- function(dataset, variavel) {
  contagem <- dataset %>%
    group_by(Categoria, !!sym(variavel)) %>%
    summarise(Freq = n()) %>%
    mutate(Prop = round(100 * (Freq / sum(Freq)), 2)) %>%
    arrange(desc(!!sym(variavel))) %>%
    mutate(posicao = cumsum(Prop) - 0.5 * Prop)

  ggplot(contagem, aes(x = factor(""), y = Prop, fill = !!sym(variavel))) +
    geom_bar(width = 1, stat = "identity") +
    facet_wrap(~ Categoria) +
    coord_polar("y", start = 0) +
    geom_text(
      aes(x = 2, y = posicao, label = paste0(Prop, "%")),
      color = "black") +
    theme_estat() +
    theme(legend.position = "top") +
    scale_fill_manual(values = cores_estat, name = variavel)
}

# Uso da função para criar contagem e gráfico de barras para Marca, Cor e Tamanho

contagem_marca <- gerar_contagem_grafico(vendas_analise_1_marcas_setores, "Marca")
ggsave("setor_final_marca.pdf", plot = contagem_marca, width = 180, height = 93, units = "mm")

contagem_cor <- gerar_contagem_grafico(vendas_analise_1_marcas_setores, "Cor")
ggsave("setor_final_cor.pdf", plot = contagem_cor, width = 180, height = 93, units = "mm")

contagem_tamanho <- gerar_contagem_grafico(vendas_analise_1_marcas_setores, "Tamanho")
ggsave("setor_final_tamanho.pdf", plot = contagem_tamanho, width = 180, height = 93, units = "mm")

# Função para criar conjuntos de dados e gráficos com base em uma variável (Marca, Cor ou Tamanho)
# Ou seja um grafico de linha multivariado para cada categoria em marca, cor e tamanho

gerar_grafico <- function(dataset, variavel) {
  lista_faturamento_anual <- dataset %>%
    group_split(Categoria) %>%
    map(~ .x %>%
          group_by(`Mês da compra`, !!sym(variavel)) %>%
          summarise(Faturamento = sum(Preço)))

  nomes_categorias <- unique(dataset$Categoria)
  nomes_lista <- paste0("faturamento_anual_", gsub("'", "", nomes_categorias), "_", variavel)
  names(lista_faturamento_anual) <- nomes_lista

  lista_graficos <- map(lista_faturamento_anual, ~ ggplot(.x) +
                          aes(x = `Mês da compra`, y = Faturamento, group = !!sym(variavel), color = !!sym(variavel)) +
                          geom_line(size = 1) +
                          geom_point(size = 2) +
                          labs(x = "Mês", y = "Faturamento", color = variavel) +
                          scale_y_continuous(limits = c(0, max(.x$Faturamento) + 100), breaks = seq(0, max(.x$Faturamento) + 100, by = 100)) +
                          theme_estat())

  nomes_graficos <- names(lista_faturamento_anual)
  names(lista_graficos) <- paste0("grafico_", nomes_graficos)

  map(names(lista_graficos), ~ ggsave(paste0(.x, "_", variavel, ".pdf"), plot = lista_graficos[[.x]], width = 158, height = 93, units = "mm"))
}

# Uso da função para criar conjuntos de dados e gráficos para Marca, Cor e Tamanho

vendas_analise_1_marcas_linhas <- subset(vendas_analise_1, complete.cases(Categoria,Cor))

gerar_grafico(vendas_analise_1_marcas_linhas, "Marca")
gerar_grafico(vendas_analise_1_marcas_linhas, "Cor")
gerar_grafico(vendas_analise_1_marcas_linhas, "Tamanho")

#################################################
####Analise 2 - Variação do preço por marca #####
#################################################

# Clonando o dataset para não aplicar erros aos dados originais
# Dataset completo, pois as devoluções não impactam nesta análise

vendas_analise_2 <- vendas_final

# Retirando NAs

vendas_analise_2 <- subset(vendas_analise_2, complete.cases(Marca, Preço))

# Gartantindo que os valores da coluna Preço sejam numéricos

vendas_analise_2$Preço <- as.numeric(vendas_analise_2$Preço)

# Listando as marcas

nomes_marcas <- unique(vendas_analise_2$`Marca`)
print(nomes_marcas)

# Boxplot multivaria do preço por marca

ggplot(vendas_analise_2) +
  aes(x = Marca , y = Preço) +
  geom_boxplot(fill = c("#A11D21"), width = 0.5) +
  stat_summary(
    fun = "mean", geom = "point", shape = 23, size = 3, fill = "white"
  ) +
  labs(x = "Marca", y = "Preço") +
  theme_estat ()
ggsave("box_multi_marca_preço.pdf", width = 158, height = 93, units = "mm")

# Quadro de medidas resumo

quadro_resumo_analise_2 <- vendas_analise_2 %>%
  group_by( Marca ) %>% # caso mais de uma categoria
  summarize (Média = round(mean(Preço),2),
             `Desvio Padrão ` = round(sd(Preço),2),
             `Mínimo ` = round(min(Preço),2),
             `1º Quartil ` = round(quantile(Preço , probs = .25),2),
             Mediana = round(quantile(Preço , probs = .5),2),
             `3º Quartil ` = round(quantile(Preço , probs = .75),2),
             `Máximo` = round(max(Preço),2))  %>% t() %>% as.data.frame()

xtable :: xtable(quadro_resumo_analise_2)

# Testando se as médias dos preços em cada uma das marcas são diferentes

# Testando a normalidade dos dados para implementar a ANOVA

marcas_analise_2 <- unique(vendas_analise_2$Marca)

for (marca in marcas_analise_2) {
  subset_data <- vendas_analise_2$Preço[vendas_analise_2$Marca == marca]
  result_ad_test <- ad.test(subset_data)
  print(paste("Teste Anderson-Darling para", marca))
  print(result_ad_test)
}

# Critério de normalidade satisfeito

#Anova para a média de preços entre as marcas

modelo_anova <- aov(Preço ~ Marca, data = vendas_analise_2)
resultado_anova <- summary(modelo_anova)

# Exibir os resultados da ANOVA
print(resultado_anova)

# Lista de marcas de interesse
marcas_interesse <- c("Adidas", "H&M", "Gucci", "Zara", "Nike")

# Criando uma lista vazia para armazenar os dataframes filtrados
lista_vendas_por_marca <- list()

# Loop para criar um dataframe para cada marca
for (marca in marcas_interesse) {
  nome_dataset <- paste("vendas_", tolower(gsub("&", "", gsub("'", "", gsub(" ", "_", marca)))), sep = "")
  dataset_filtrado <- vendas_analise_2 %>%
    filter(Marca == marca)
  
  # Armazenando o dataframe na lista usando o nome da marca como identificação
  lista_vendas_por_marca[[nome_dataset]] <- dataset_filtrado
}

# Graficos e testes para cada marca

# Lista de marcas de interesse

marcas_interesse <- c("Nike", "H&M", "Adidas", "Gucci")

# Lista de categorias de interesse

categorias_interesse <- c("Cor", "Categoria", "Tamanho")

# Função para criar boxplots e realizar testes ANOVA

gerar_boxplot_anova <- function(data, var_x, var_y, nome_arquivo) {
  ggplot(data) +
    aes_string(x = var_x, y = var_y) +
    geom_boxplot(fill = c("#A11D21"), width = 0.5) +
    stat_summary(fun = "mean", geom = "point", shape = 23, size = 3, fill = "white") +
    labs(x = var_x, y = var_y) +
    theme_minimal()
  
  ggsave(nome_arquivo, width = 158, height = 93, units = "mm")
  
  modelo_anova <- aov(as.formula(paste(var_y, "~", var_x)), data = data)
  resultado_anova <- summary(modelo_anova)
  print(resultado_anova)
}

# Loop para criar boxplots e realizar testes ANOVA para cada marca e categoria

for (marca in marcas_interesse) {
  for (categoria in categorias_interesse) {
    nome_dataset <- paste("vendas_", tolower(gsub("&", "", gsub("'", "", gsub(" ", "_", marca)))), sep = "")
    dataset_filtrado <- subset(vendas_analise_2, Marca == marca & complete.cases({{categoria}}, Preço))
    
    nome_arquivo <- paste("box_", tolower(gsub("&", "", gsub("'", "", gsub(" ", "_", marca)))), "_", categoria, ".pdf", sep = "")
    
    gerar_boxplot_anova(dataset_filtrado, categoria, "Preço", nome_arquivo)
  }
}

############################################################################
#### Análise 3 - Relação entre categoira (Masculino e feminino) e marca ####
############################################################################

# Clonando os dataset para não corromper o banco original

vendas_analise_3 <- vendas_final

# Retirando NAs

vendas_analise_3 <- subset(vendas_analise_3, complete.cases(Cor,Categoria))

# Listando as cores e Categorias

nomes_cores <- unique(vendas_analise_3$`Cor`)

nomes_categorias <- unique(vendas_analise_3$Categoria)

print(nomes_cores)

print(nomes_categorias)

# Retirando a categoria infatil

vendas_analise_3 <- subset(vendas_analise_3, Categoria != "Kids' Fashion")

# Criando a tabela de frequência entre Categoria e Cor

tabela_frequencia_analise_3 <- table(vendas_analise_3$Categoria, vendas_analise_3$Cor)

tabela_freq_com_margens_3 <- addmargins(tabela_frequencia_analise_3, FUN = list(Total = sum))

print(tabela_frequencia_analise_3)

print(tabela_freq_com_margens_3)

xtable :: xtable(tabela_frequencia_analise_3)

xtable :: xtable(tabela_freq_com_margens_3)

# Criando uma tabela de proporções

PT = prop.table(tabela_frequencia_analise_3, margin=1)

round(PT, 3)

xtable :: xtable(PT)

# Coeficiente V de cramer

if(!require(vcd)){install.packages("vcd")}

library(vcd)

assocstats(tabela_frequencia_analise_3)

# Teste qui-quadrado

resultado_chisq <- chisq.test(tabela_frequencia_analise_3)

print(resultado_chisq)

#####################################################
#### Análise 4 - Relação entre preço e avaliação ####
#####################################################

# Clonando os datasets

vendas_analise_4 <- vendas_final

# Retirando NAs

vendas_analise_4 <- subset(vendas_analise_4, complete.cases(Preço,Avaliação))

# Testando a normalidade dos dados

# Teste de normalidade para a variável Preço

resultado_preco_4 <- ad.test(vendas_analise_4$Preço)

print(resultado_preco_4)

# Teste de normalidade para a variável Avaliação

resultado_avaliacao_4 <- ad.test(vendas_analise_4$Avaliação)

print(resultado_avaliacao_4)

# Calculando a correlação de Pearson e realizando o teste

correlacao <- cor.test(vendas_analise_4$Preço, vendas_analise_4$Avaliação, method = "pearson")

print(correlacao)

# Gráfico de disperção

ggplot(vendas_analise_4) +
  aes(x = Preço , y = Avaliação) +
  geom_point(colour = "#A11D21", size = 2) +
  labs(
    x = "Preço",
    y = "Avaliação"
  ) +
  theme_estat ()
ggsave("disperção_analise_4.pdf", width = 158, height = 93, units = "mm")


####################################################################
#### Análise 5 - Frequência de cada tipo de devolução por marca ####
####################################################################

# Clonando os datasets para não corromper o banco original

devolução_analise_5 <- devolução_atualizado_secundário
vendas_analise_5_inicio <- vendas_final

# Formatando o banco de devolução

novo_nome_colunas_5 <- c(
  "X" = "X",
  "Unique.ID" = "ID exclusivo",
  "Motivo.devolução" = "Motivo de devolução 2"
)

colnames(devolução_analise_5) <- novo_nome_colunas_5

# Juntando os bancos (com e sem devolução - após a correção da cliente)

# Unindo os dataframes com base na coluna "ID Exclusivo"

vendas_analise_5<- merge(vendas_analise_5_inicio, devolução_analise_5, by = "ID exclusivo")

# Listando tipos de motivos de devolução

nomes_motivos_5 <- unique(vendas_analise_5$`Motivo de devolução 2`)

print(nomes_motivos_5)

# Tabela de frequência

tabela_freqequencia_5 <- table(vendas_analise_5$Marca, vendas_analise_5$`Motivo de devolução 2`)

tabela_freq_com_margens_5 <- addmargins(tabela_freqequencia_5, FUN = list(Total = sum))

# Visualizar a tabela de frequências com margens

print(tabela_freq_com_margens_5)

xtable :: xtable(tabela_freq_com_margens_5)

# Criando uma tabela de proporções

PT = prop.table(tabela_freqequencia_5, margin=1)

round(PT, 3)

xtable :: xtable(tabela_freqequencia_5)

# Teste qui-quadrado

resultado_chisq <- chisq.test(tabela_freqequencia_5)

print(resultado_chisq)

###############################################
#### Análise 6 - Avaliação média por marca ####
###############################################

# Clonando os datasets

vendas_analise_6 <- vendas_final

# Retirando Nas

vendas_analise_6 <- subset(vendas_analise_6, complete.cases(Marca, Avaliação))

# Calculando a média das avaliações por marca

media_avaliacao_por_marca_6 <- aggregate(vendas_analise_6$Avaliação, by = list(Marca = vendas_analise_6$Marca), FUN = mean)

# Renomeando as colunas

colnames(media_avaliacao_por_marca_6) <- c("Marca", "Media Avaliacao")

# Mostrando o resultado

print(media_avaliacao_por_marca_6)

xtable :: xtable(media_avaliacao_por_marca_6)

# Testando a normalidade dos dados

marcas_analise_6 <- unique(vendas_analise_6$Marca)

for (marca in marcas_analise_6) {
  subset_data <- vendas_analise_6$Avaliação[vendas_analise_2$Marca == marca]
  result_ad_test <- ad.test(subset_data)
  print(paste("Teste Anderson-Darling para", marca))
  print(result_ad_test)
}

# Normalidade satisfeita

# Anova para a média de avaliação entre as marcas

modelo_anova_6 <- aov(Avaliação ~ Marca, data = vendas_analise_6)

resultado_anova_6 <- summary(modelo_anova_6)

print(resultado_anova_6)
