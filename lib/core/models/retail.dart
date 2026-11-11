class RetailCity {
  const RetailCity({required this.id, required this.name});

  final String id;
  final String name;
}

class StoreChain {
  const StoreChain({required this.id, required this.name});

  final String id;
  final String name;
}

const retailCities = <RetailCity>[
  RetailCity(id: 'rostov_on_don', name: 'Ростов-на-Дону'),
  RetailCity(id: 'moscow', name: 'Москва'),
  RetailCity(id: 'saint_petersburg', name: 'Санкт-Петербург'),
  RetailCity(id: 'novosibirsk', name: 'Новосибирск'),
  RetailCity(id: 'yekaterinburg', name: 'Екатеринбург'),
  RetailCity(id: 'kazan', name: 'Казань'),
  RetailCity(id: 'nizhny_novgorod', name: 'Нижний Новгород'),
  RetailCity(id: 'chelyabinsk', name: 'Челябинск'),
  RetailCity(id: 'krasnoyarsk', name: 'Красноярск'),
  RetailCity(id: 'samara', name: 'Самара'),
  RetailCity(id: 'ufa', name: 'Уфа'),
  RetailCity(id: 'omsk', name: 'Омск'),
  RetailCity(id: 'krasnodar', name: 'Краснодар'),
  RetailCity(id: 'voronezh', name: 'Воронеж'),
  RetailCity(id: 'volgograd', name: 'Волгоград'),
  RetailCity(id: 'perm', name: 'Пермь'),
  RetailCity(id: 'saratov', name: 'Саратов'),
  RetailCity(id: 'tyumen', name: 'Тюмень'),
  RetailCity(id: 'tolyatti', name: 'Тольятти'),
  RetailCity(id: 'barnaul', name: 'Барнаул'),
];

const storeChains = <StoreChain>[
  StoreChain(id: 'magnit', name: 'Магнит'),
  StoreChain(id: 'pyaterochka', name: 'Пятёрочка'),
  StoreChain(id: 'perekrestok', name: 'Перекрёсток'),
  StoreChain(id: 'chizhik', name: 'Чижик'),
  StoreChain(id: 'auchan', name: 'Ашан'),
  StoreChain(id: 'lenta', name: 'Лента'),
];

const defaultCityId = 'rostov_on_don';
const defaultStoreId = 'magnit';

RetailCity retailCityById(String id) {
  return retailCities.firstWhere(
    (city) => city.id == id,
    orElse: () => retailCities.first,
  );
}

StoreChain storeChainById(String id) {
  return storeChains.firstWhere(
    (store) => store.id == id,
    orElse: () => storeChains.first,
  );
}
