class Animal {
  final String id;
  final String ar;
  final String en;
  final String wiki; // Wikipedia article title (used to fetch the real photo)
  final String cat;
  final String? snd; // search words for the real recording (null = no audible sound)
  final String soundName;

  const Animal({
    required this.id,
    required this.ar,
    required this.en,
    required this.wiki,
    required this.cat,
    this.snd,
    this.soundName = '',
  });

  bool get hasSound => snd != null;
}

const Map<String, String> kCategories = {
  'pets': 'أليفة',
  'farm': 'مزرعة',
  'wild': 'برية',
  'birds': 'طيور',
  'sea': 'بحرية',
  'bugs': 'حشرات وزواحف',
};

String normalizeText(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[\u064B-\u065F\u0640]'), '')
    .replaceAll(RegExp('[أإآ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي')
    .trim();

// id|arabic|english|wikipedia title|category|sound search words|sound name
const String _raw = '''
cat|قطة|Cat|Cat|pets|cat meow|المواء
dog|كلب|Dog|Dog|pets|dog bark|النباح
rabbit|أرنب|Rabbit|Rabbit|pets||
hamster|هامستر|Hamster|Hamster|pets||
mouse|فأر|House mouse|House mouse|pets|mouse squeak|الصرير
guineapig|خنزير غينيا|Guinea pig|Guinea pig|pets|guinea pig|الصرير
parrot|ببغاء|Parrot|Parrot|pets|parrot|الصياح
canary|كناري|Domestic canary|Domestic canary|pets|canary song|التغريد
horse|حصان|Horse|Horse|farm|horse neigh|الصهيل
donkey|حمار|Donkey|Donkey|farm|donkey bray|النهيق
cow|بقرة|Cow|Cattle|farm|cow moo|الخوار
bull|ثور|Bull|Bull|farm|bull bellow|الخوار
sheep|خروف|Sheep|Sheep|farm|sheep bleat|الثغاء
goat|ماعز|Goat|Goat|farm|goat bleat|الثغاء
pig|خنزير|Domestic pig|Domestic pig|farm|pig oink|القباع
camel|جمل|Dromedary|Dromedary|farm|camel groan|الرغاء
buffalo|جاموس|Water buffalo|Water buffalo|farm|buffalo grunt|الخوار
hen|دجاجة|Chicken|Chicken|farm|hen cluck|القوقأة
rooster|ديك|Rooster|Rooster|farm|rooster crow|الصياح
duck|بطة|Duck|Domestic duck|farm|duck quack|البطبطة
goose|إوزة|Goose|Domestic goose|farm|goose honk|الصياح
turkey|ديك رومي|Turkey|Domesticated turkey|farm|turkey gobble|القلقلة
pigeon|حمامة|Pigeon|Rock dove|farm|pigeon coo|الهديل
llama|لاما|Llama|Llama|farm|llama hum|الهمهمة
lion|أسد|Lion|Lion|wild|lion roar|الزئير
tiger|نمر|Tiger|Tiger|wild|tiger roar|الزئير
leopard|فهد|Leopard|Leopard|wild|leopard growl|الزمجرة
cheetah|شيتا|Cheetah|Cheetah|wild|cheetah chirp|الزقزقة
jaguar|جاغوار|Jaguar|Jaguar|wild|jaguar roar|الزئير
elephant|فيل|African elephant|African elephant|wild|elephant trumpet|النفير
giraffe|زرافة|Giraffe|Giraffe|wild||
zebra|حمار وحشي|Plains zebra|Plains zebra|wild|zebra bark|النباح
rhino|وحيد القرن|White rhinoceros|White rhinoceros|wild|rhinoceros snort|الشخير
hippo|فرس النهر|Hippopotamus|Hippopotamus|wild|hippopotamus grunt|النخير
monkey|قرد|Monkey|Monkey|wild|monkey call|الصياح
gorilla|غوريلا|Gorilla|Gorilla|wild|gorilla grunt|النخير
chimp|شمبانزي|Chimpanzee|Chimpanzee|wild|chimpanzee pant hoot|الصياح
orangutan|إنسان الغاب|Orangutan|Orangutan|wild|orangutan long call|النداء
bear|دب|Brown bear|Brown bear|wild|bear growl|الزمجرة
polarbear|دب قطبي|Polar bear|Polar bear|wild|polar bear growl|الزمجرة
panda|باندا|Giant panda|Giant panda|wild|panda bleat|الثغاء
wolf|ذئب|Gray wolf|Wolf|wild|wolf howl|العواء
fox|ثعلب|Red fox|Red fox|wild|fox scream|الصراخ
hyena|ضبع|Spotted hyena|Spotted hyena|wild|hyena laugh|الضحك
jackal|ابن آوى|Golden jackal|Golden jackal|wild|jackal howl|العواء
deer|أيل|Red deer|Red deer|wild|red deer roar|النعير
kangaroo|كنغر|Kangaroo|Kangaroo|wild|kangaroo cough|السعال
koala|كوالا|Koala|Koala|wild|koala bellow|النخير
bat|خفاش|Bat|Bat|wild|bat echolocation|الصرير
squirrel|سنجاب|Squirrel|Squirrel|wild|squirrel chatter|الثرثرة
hedgehog|قنفذ|Hedgehog|Hedgehog|wild|hedgehog snuffle|الشخير
meerkat|ميركات|Meerkat|Meerkat|wild|meerkat call|النداء
sparrow|عصفور|House sparrow|House sparrow|birds|house sparrow chirp|الزقزقة
owl|بومة|Owl|Owl|birds|owl hoot|النعيب
eagle|نسر|Bald eagle|Bald eagle|birds|eagle call|الصرخة
falcon|صقر|Peregrine falcon|Peregrine falcon|birds|falcon call|الصرخة
penguin|بطريق|Emperor penguin|Emperor penguin|birds|penguin call|النهيق
peacock|طاووس|Indian peafowl|Indian peafowl|birds|peacock call|الصراخ
swan|بجعة|Mute swan|Mute swan|birds|swan call|الصياح
flamingo|فلامنجو|Flamingo|Flamingo|birds|flamingo call|الصياح
crow|غراب|Crow|Crow|birds|crow caw|النعيق
hoopoe|هدهد|Eurasian hoopoe|Eurasian hoopoe|birds|hoopoe call|الهدهدة
nightingale|بلبل|Common nightingale|Common nightingale|birds|nightingale song|التغريد
ostrich|نعامة|Common ostrich|Common ostrich|birds|ostrich boom|الهدير
seagull|نورس|Seagull|Gull|birds|seagull call|الصياح
stork|لقلق|White stork|White stork|birds|stork clatter|القرقعة
cuckoo|وقواق|Common cuckoo|Common cuckoo|birds|cuckoo call|الوقوقة
woodpecker|نقار الخشب|Woodpecker|Woodpecker|birds|woodpecker drumming|النقر
dolphin|دولفين|Bottlenose dolphin|Bottlenose dolphin|sea|dolphin whistle|الصفير
whale|حوت|Humpback whale|Humpback whale|sea|humpback whale song|غناء الحوت
orca|أوركا|Orca|Orca|sea|orca call|الصفير
seal|فقمة|Harbor seal|Harbor seal|sea|seal call|النباح
sealion|أسد البحر|Sea lion|Sea lion|sea|sea lion bark|النباح
walrus|فظ|Walrus|Walrus|sea|walrus grunt|النخير
shark|قرش|Great white shark|Great white shark|sea||
octopus|أخطبوط|Octopus|Octopus|sea||
crab|سلطعون|Crab|Crab|sea||
jellyfish|قنديل البحر|Jellyfish|Jellyfish|sea||
seahorse|حصان البحر|Seahorse|Seahorse|sea|seahorse click|النقر
snake|ثعبان|Snake|Snake|bugs|snake hiss|الفحيح
cobra|كوبرا|Egyptian cobra|Egyptian cobra|bugs|cobra hiss|الفحيح
crocodile|تمساح|Nile crocodile|Nile crocodile|bugs|crocodile roar|الزمجرة
turtle|سلحفاة|Tortoise|Tortoise|bugs||
lizard|سحلية|Lizard|Lizard|bugs||
gecko|أبو بريص|Gecko|Gecko|bugs|gecko call|النقر
chameleon|حرباء|Chameleon|Chameleon|bugs||
frog|ضفدع|Frog|Frog|bugs|frog croak|النقيق
toad|علجوم|Toad|Toad|bugs|toad call|النقيق
bee|نحلة|Western honey bee|Western honey bee|bugs|bee buzz|الطنين
fly|ذبابة|Housefly|Housefly|bugs|housefly buzz|الطنين
mosquito|بعوضة|Mosquito|Mosquito|bugs|mosquito buzz|الأزيز
cricket|صرصور الليل|Cricket (insect)|Cricket (insect)|bugs|cricket chirp|الصرير
cicada|زيز|Cicada|Cicada|bugs|cicada|الصرير
butterfly|فراشة|Butterfly|Butterfly|bugs||
ant|نملة|Ant|Ant|bugs||
scorpion|عقرب|Scorpion|Scorpion|bugs||
spider|عنكبوت|Spider|Spider|bugs||
''';

final List<Animal> kAnimals = _raw
    .split('\n')
    .map((l) => l.trim())
    .where((l) => l.isNotEmpty)
    .map((l) {
  final p = l.split('|');
  return Animal(
    id: p[0],
    ar: p[1],
    en: p[2],
    wiki: p[3],
    cat: p[4],
    snd: p[5].isEmpty ? null : p[5],
    soundName: p[6],
  );
}).toList();
