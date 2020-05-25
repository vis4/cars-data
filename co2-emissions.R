needs(readr, dplyr, ggplot2, stringr)

setwd("~/projects/datawrapper/weekly-charts/cars")

models <- read_csv('models.csv')
specs <- read_csv('specs.csv')

co2 <- specs %>%
  unique() %>%
  pivot_wider(names_from = metric, values_from = value) %>%
  left_join(models, by = c('type' = 'key')) %>% 
  mutate(`CO2 emissions (g/km)`=as.numeric(str_replace(`CO2 emissions`, ' g/km', '')),
         `weight (kg)`=as.numeric(str_replace(`mass empty`, ' kg', '')),
         `length (mm)`=as.numeric(str_replace(`length`, ' mm', '')),
         `width (mm)`=as.numeric(str_replace(`width`, ' mm', '')),
         `height (mm)`=as.numeric(str_replace(`height`, ' mm', ''))) %>% 
  select(model, group, year, type=type.y, `CO2 emissions (g/km)`, `weight (kg)`,
        `length (mm)`, `width (mm)`, `height (mm)`) %>% 
  filter(`CO2 emissions (g/km)` > 0) %>% 
  arrange(model, group, year, `CO2 emissions (g/km)`) 

co2 %>% 
  write_csv('co2-emissions.csv')

co2 %>%
  filter(year >= 2018) %>% 
  group_by(model) %>% 
  summarise(min.weight=min(`weight (kg)`, na.rm = T),
            max.weight=max(`weight (kg)`, na.rm = T),
            avg.emission=mean(`CO2 emissions (g/km)`, na.rm = T)) %>% 
  View
