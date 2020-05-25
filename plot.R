needs(dplyr, readr, ggplot2, httr, tidyr)

api_key <- 'b1229193860443cff29d57ba9e0095473fd3a1a5dea15ca4507267e597f56a6f'
chart_id <- 'DdRcj'

d <- read_csv('weights.csv') %>% 
  unique() %>% 
  mutate(weight.num=as.numeric(sub('([0-9]+) +kg', '\\1', weight))) %>% 
  mutate(length=as.numeric(sub('([0-9]+) +mm', '\\1', length))) %>% 
  mutate(width=as.numeric(sub('([0-9]+) +mm', '\\1', width))) %>%
  mutate(doors=as.numeric(sub('([0-9])-doors, .*', '\\1', body))) %>% 
  mutate(area=width*length/1e6) %>% 
  mutate(type=as.factor(sub('[0-9]-doors, (.*)', '\\1', body))) %>% 
  mutate(to_year=as.numeric(to_year)) %>% 
  select(-body) %>% 
  mutate(type=recode(type, coupe='coupé', bus='other', bestelwagen='other', van='other', `pick-up`='other')) %>% 
  filter(from_year > 1979)

d %>% ggplot(aes(x=width, y=length, color=type)) + geom_point()

d %>% filter(length<2000) %>% View

d.aggr %>% group_by(type) %>% summarise(count=n()) %>% View  

d.aggr <- d %>% 
  group_by(key) %>% 
  summarise(weight=mean(weight.num),
            model=first(model),
            group=first(group),
            type=first(type),
            count=n(),
            doors=first(doors),
            from_year=min(from_year),
            to_year=max(to_year, na.rm = F),
            weight.max=max(weight.num),
            weight.min=min(weight.num),
            weight.span=weight.max - weight.min,
            area.avg=mean(area),
            area.min=min(area),
            area.max=max(area),
            area.span=area.max-area.min) %>% 
  mutate(decade=floor(from_year/10)*10)

d.aggr %>% 
  ggplot(aes(x=as.character(decade), y=weight)) +
  geom_boxplot()

d.aggr %>% 
  filter(type != 'other' & is.na(to_year)) %>% 
  ggplot(aes(x=reorder(type, weight, FUN=median, na.rm=T), y=weight)) +
  geom_boxplot()


d %>% ggplot(aes(x=from_year, y=area)) +
  geom_point(shape=1) +
  geom_smooth()

d.aggr %>% filter(type != 'other' & is.na(to_year)) %>% 
  ggplot(aes(x=area.avg, y=weight, color=type, shape=type)) +
  geom_point() +
  geom_smooth(aes(), se=F) +
  scale_y_log10()

d.aggr %>% 
  select(from_year, area.avg, to_year, model, group, weight) %>%
  write_csv('cars-grouped.csv')

d %>% ggplot() +
  geom_rect(aes(xmin=from_year,
                ymin=weight.num,
                ymax=weight.num-10,
                xmax=replace_na(to_year, 2020)), alpha=0.2)

d.aggr %>% ggplot() +
  geom_rect(aes(xmin=from_year,
                ymin=weight.max,
                ymax=weight.max-10,
                xmax=replace_na(to_year, 2020)), alpha=0.2)

d.aggr %>% ggplot(aes(x=from_year, y=weight.min)) +
  geom_point(aes(color=type)) +
  geom_smooth()

d.aggr %>% write_csv('cars.csv')

rs <- PUT(url=paste0('https://api.datawrapper.de/v3/charts/', chart_id ,'/data'),
    body=format_csv(d),
    add_headers(Authorization = paste0('Bearer ', api_key)),
    content_type('text/csv'))

content(rs, 'text')


d.aggr.model <- d %>% 
  group_by(model, from_year) %>% 
  summarise(weight=mean(weight.num),
            to_year=max(to_year, na.rm = F),
            weight.max=max(weight.num),
            weight.min=min(weight.num),
            weight.span=weight.max - weight.min)

d.aggr.model %>% ggplot(aes(x=from_year, y=weight.max, color=model)) + geom_line()


avg <- d %>%
  group_by(doors, year=from_year) %>% 
  summarise(weight = median(weight.num, na.rm = T),
            low=quantile(weight.num, c(0.05), na.rm = T),
            high=quantile(weight.num, c(0.95), na.rm = T))

avg %>% ggplot(aes(x=year, y=weight)) +
  geom_ribbon(aes(ymin=low, ymax=high), alpha=0.2) +
  geom_line() +
  facet_wrap(. ~ doors)
