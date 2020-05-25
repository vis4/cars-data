needs(readr, dplyr, ggplot2, stringr)

setwd("~/projects/datawrapper/weekly-charts/cars")

models <- read_csv('models.csv')
specs <- read_csv('specs.csv')

specs %>%
  unique() %>%
  pivot_wider(names_from = metric, values_from = value) %>%
  left_join(models, by = c('type' = 'key')) %>% 
  mutate(`CO2 emissions (g/km)`=as.numeric(str_replace(`CO2 emissions`, ' g/km', '')),
         `length (mm)`=as.numeric(str_replace(`length`, ' mm', '')),
         `width (mm)`=as.numeric(str_replace(`width`, ' mm', '')),
         `height (mm)`=as.numeric(str_replace(`height`, ' mm', ''))) %>% 
  select(model, group, year, type=type.y, `CO2 emissions (g/km)`,
        `length (mm)`, `width (mm)`, `height (mm)`) %>% 
  filter(`CO2 emissions (g/km)` > 0) %>% 
  arrange(model, group, year, `CO2 emissions (g/km)`) %>% 
  write_csv('co2-emissions.csv')

