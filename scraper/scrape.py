from bs4 import BeautifulSoup
import requests
import dataset

db = dataset.connect('sqlite:///cars.db')

def main():
    for model in get_models():
        for group in get_groups(model['key']):
            for year in get_years(model['key'], group['key']):
                for type_ in get_types(model['key'], group['key'], year['key']):
                    s = db['specs'].count(type=type_['key'])
                    if s < 50:
                        get_specs(type_['key'], '/tech')
                        get_specs(type_['key'], '/sizes')
                    print(type_['key'])



def get_models():
    models = db['models'].count()
    if models > 0:
        return db['models'].all()
    # download models from cars-data
    r = requests.get('https://www.cars-data.com/')
    soup = BeautifulSoup(r.text, 'html.parser')
    select = soup.find('select', class_='input_select_mark')
    models = []
    for opt in select.find_all('option'):
        if opt['value'] != '':
            models.append(dict(key=opt['value'], name=opt.string))
    db['models'].insert_many(models)
    return models


def get_groups(model):
    groups = db['groups'].count(model=model)
    if groups > 0:
        return db['groups'].find(model=model)
    r = requests.get('https://www.cars-data.com/ajax_files/get_groups.php?url='+model)
    soup = BeautifulSoup(r.text, 'html.parser')
    groups = []
    for opt in soup.find_all('option'):
        if opt['value'] != '':
            groups.append(dict(model=model, key=opt['value'], name=opt.string))
    db['groups'].insert_many(groups)
    return groups


def get_years(model, group):
    years = db['years'].count(model=model, group=group)
    if years > 0:
        return db['years'].find(model=model, group=group)
    r = requests.get('https://www.cars-data.com/ajax_files/get_years.php?url='+group)
    soup = BeautifulSoup(r.text, 'html.parser')
    years = []
    for opt in soup.find_all('option'):
        if opt['value'] != '':
            [year, key] = opt['value'].split('|')
            years.append(dict(model=model, group=group, key=key, year=int(year)))
    db['years'].insert_many(years)
    return years


def get_types(model, group, year):
    cars = db['types'].count(model=model, group=group, year=year)
    if cars > 0:
        return db['types'].find(model=model, group=group, year=year)
    r = requests.get('https://www.cars-data.com/en/'+year)
    soup = BeautifulSoup(r.text, 'html.parser')
    types = []
    section = soup.find('section', class_='types')
    for row in section.find_all('div', class_='row'):
        h2 = row.find('h2')
        if h2:
            a = h2.find('a')
            if a:
                name = a.string
                url = a['href'][29:]
                if url != '':
                    types.append(dict(model=model, group=group, year=year, key=url, name=name))
    db['types'].insert_many(types)
    return types


def get_specs(url, append=''):
    r = requests.get('https://www.cars-data.com/en/'+url+append)
    soup = BeautifulSoup(r.text, 'html.parser')
    specs = []
    for group in soup.find_all('dl', class_='box'):
        h2 = group.find('h2')
        spec_group = h2.string.lower()
        for dt in group.find_all('dt'):
            spec_name = dt.string[:-1]  # chop off trailing colon
            spec_value = dt.next_sibling.string
            if spec_value != '' and spec_value != 'N.A.':
                specs.append(dict(type=url, spec_group=spec_group, metric=spec_name, value=spec_value))
    db['specs'].insert_many(specs)
    return specs

if __name__ == '__main__':
    main()