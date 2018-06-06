#-------------------------------------------------------------------------------------------------------------------
#-- Lendo, processando e gerando grÃ¡ficos das medidas de hailpads
#-------------------------------------------------------------------------------------------------------------------

#-- Carregando pacotes necessÃ¡rios
require(readr); require(tidyverse); require(reshape2)

#-- Lendo e prÃ©-processando os dados
hailpads <- read.csv2(file = "Medidas_Hailpads.csv", sep = ";", dec = ",") %>% .[colSums(!is.na(.)) > 0] %>% 
  melt(.) %>% separate(variable, into = c("placa", "medido_por", "#"), sep = "_") %>% 
  mutate(placa = toupper(placa), medido_por = toupper(medido_por)) %>% 
  na.omit %>% 
  mutate(value = ifelse(medido_por == "IAG", (value + 3.7207)/1.0349, value)) %>% 
  unite(medido_por, "#", col = "medido_por") %>% 
  filter(placa == "C001" | placa == "R002" | placa == "R004")

#--- DiÃ¢metros mÃ©dios [mm] por bins (de 1 mm) e quantidade de pontos [1/mÂ²]
hailpads_diams <- hailpads %>% mutate(bin = value - value %% 1) %>% 
  group_by(placa, medido_por, bin) %>% 
  summarise(diam_bin = mean(value), sd_bin = sd(value), qte = n()) %>%
  ungroup() %>% group_by(placa, bin) %>% 
  summarise(diam_placa = mean(diam_bin), sd_placa = sqrt(sum(sd_bin^2, na.rm = T)), n = mean(qte)/(0.399*0.298)) %>% 
  ungroup()

#--- DiÃ¢metros tÃ­picos (medianas) e mÃ¡ximos de cada placa
tmp <- hailpads %>% group_by(medido_por, placa) %>% 
  mutate(tipico = median(value), maximo = max(value)) %>% ungroup() %>% 
  group_by(placa) %>% 
  summarise(diam_tipico = mean(tipico), sd_tipico = sd(tipico), diam_max = mean(maximo), sd_max = sd(maximo))

#--- Energia cinÃ©tica [J/mÂ²] de cada placa
tmp2 <- hailpads_diams %>% group_by(placa) %>% 
  mutate(encin = 4.58e-6 * sum(n * diam_placa^4), 
         sd_encin = sqrt(sum(4.58e-6 * n * 4 * diam_placa^3 * sd_placa, na.rm = T))) %>% 
  ungroup() %>% 
  distinct(encin, sd_encin)

hailpads_porplaca <- bind_cols(tmp, tmp2); rm(tmp, tmp2)
  
#-- Plotando os dados

#--- Definindo os tÃ­tulos no centro da figura
theme_update(plot.title = element_text(hjust = 0.5))

#--- GRÃFICO 1: DISTRIBUIÃÃO DE TODOS OS DADOS
ggplot(data = hailpads) +
  geom_boxplot(aes(x = placa, y = value, color = medido_por)) +
  labs(x = "Hailpad", y = "Diameter [mm]") + ggtitle("Distributions of All Measures") +
  scale_color_brewer(name = "Measured by", palette = "Set1") +
  scale_x_discrete(labels = c("C001\n2017-03-14", "R002\n2017-03-14", "R004\n2017-11-15"))
ggsave("distribuicao_medidas.png", width = 6, height = 3)

#--- GRÃFICO 2: DIÃMETRO X ENERGIA CINÃTICA (TORRO)
ggplot(data = hailpads_porplaca, aes(x = diam_tipico, y = encin)) +
  scale_x_continuous(limits = c(4,11)) + #scale_y_log10() +
  geom_hline(yintercept = c(20,100), color = "darkgray") +
  geom_vline(xintercept = c(5,10), color = "darkgray") +
  annotate("text", label = c("H0", "H1", "H2"), x = c(4, 7.5, 11), y = c(10, 60, 125)) +
  geom_point(aes(color = placa)) +
  geom_errorbar(aes(ymin = encin-sd_encin, ymax = encin+sd_encin, color = placa), size = 1, width = 0.1) +
  geom_errorbarh(aes(xmin = diam_tipico-sd_tipico, xmax = diam_tipico+sd_tipico, color = placa), size = 1) +
  labs(x = "Typical Diameter [mm]", y = "Kinetic Energy [J/mÂ²]") + ggtitle("Hailstorm Intensity - TORRO Scale") +
  scale_color_brewer(name = "Hailpad", palette = "Dark2", labels = c("C001\n2017-03-14", "R002\n2017-03-14", "R004\n2017-11-15")) +
  theme(legend.position = "bottom")
ggsave("dados_torro.png", width = 4, height = 3)

#--- GRÃFICO 3: DIÃMETRO X ENERGIA CINÃTICA (ANELFA)
ggplot(data = hailpads_porplaca, aes(x = diam_max, y = encin)) +
  scale_x_continuous(limits = c(9,23)) + #scale_y_log10() +
  geom_hline(yintercept = c(30,100), color = "darkgray") +
  geom_vline(xintercept = c(10, 20), color = "darkgray") +
  annotate("text", label = c("A0", "A1", "A2"), x = c(9, 15, 22), y = c(15, 65, 125)) +
  geom_point(aes(color = placa)) +
  geom_errorbar(aes(ymin = encin-sd_encin, ymax = encin+sd_encin, color = placa), size = 1, width = 0.2) +
  geom_errorbarh(aes(xmin = diam_max-sd_max, xmax = diam_max+sd_max, color = placa), size = 1) +
  labs(x = "Maximum Diameter [mm]", y = "Kinetic Energy [J/mÂ²]") + ggtitle("Hailstorm Intensity - ANELFA Scale") +
  scale_color_brewer(name = "Hailpad", palette = "Dark2", labels = c("C001\n2017-03-14", "R002\n2017-03-14", "R004\n2017-11-15")) +
  theme(legend.position = "bottom")
ggsave("dados_anelfa.png", width = 4, height = 3)
