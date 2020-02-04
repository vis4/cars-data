needs(dplyr, readr, ggplot2)

d <- read_csv('weights.csv') %>% 
  mutate(weight.num=as.numeric(sub('([0-9]+) +kg', '\\1', weight))) %>% 
  filter(from_year > 0)
  
d %>% ggplot(aes(x=from_year, y=weight.num)) +
  geom_point(shape=1) +
  geom_smooth()

avg <- d %>%
  group_by(year=from_year) %>% 
  summarise(weight = median(weight.num, na.rm = T),
            low=quantile(weight.num, c(0.05), na.rm = T),
            high=quantile(weight.num, c(0.95), na.rm = T))

avg %>% ggplot(aes(x=year, y=weight)) +
  geom_ribbon(aes(ymin=low, ymax=high), alpha=0.2) +
  geom_line() 
