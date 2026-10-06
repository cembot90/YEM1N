import SwiftUI
import SwiftData
import UIKit
import UniformTypeIdentifiers
import CloudKit
import AVFoundation
import UserNotifications
import PencilKit
import CryptoKit
import Security
import WebKit
import CoreImage.CIFilterBuiltins

// MARK: - Eingebauter Sprachkatalog (Englisch und Türkisch)

enum SprachKatalogDaten {
    static let json = #"""
{
 "typ": "sprachkatalog",
 "version": 1,
 "titel": "YEM1N Sprachen",
 "sprachen": {"de": {"name": "Deutsch", "flagge": "🇩🇪", "sprachcode": "de-DE"}, "en": {"name": "Englisch", "flagge": "🇬🇧", "sprachcode": "en-GB"}, "tr": {"name": "Türkisch", "flagge": "🇹🇷", "sprachcode": "tr-TR"}},
 "lernsprachen": ["en", "tr"],
 "themen": [
  {
   "id": "hallo", "titel": "Hallo & Danke", "emoji": "👋", "stufe": 1,
   "woerter": [
    {"emoji": "👋", "de": "Hallo", "en": "hello", "tr": "merhaba", "alt": {"en": ["hi"]}},
    {"emoji": "🚶", "de": "Tschüss", "en": "goodbye", "tr": "hoşça kal", "alt": {"en": ["bye"], "tr": ["güle güle"]}, "hinweis": "Wer geht, sagt „hoşça kal“. Wer bleibt, sagt „güle güle“."},
    {"emoji": "✅", "de": "ja", "en": "yes", "tr": "evet"},
    {"emoji": "❌", "de": "nein", "en": "no", "tr": "hayır"},
    {"emoji": "🙏", "de": "Danke", "en": "thank you", "tr": "teşekkürler", "alt": {"en": ["thanks"], "tr": ["teşekkür ederim", "sağ ol"]}},
    {"emoji": "🙋", "de": "bitte", "en": "please", "tr": "lütfen"},
    {"emoji": "😔", "de": "Entschuldigung", "en": "sorry", "tr": "özür dilerim", "alt": {"tr": ["pardon"]}},
    {"emoji": "🧑‍🤝‍🧑", "de": "der Freund", "en": "friend", "tr": "arkadaş"},
    {"emoji": "🏷️", "de": "der Name", "en": "name", "tr": "ad", "alt": {"tr": ["isim"]}}
   ]
  },
  {
   "id": "zahl0", "titel": "Zahlen 0 bis 10", "emoji": "🔢", "stufe": 1,
   "woerter": [
    {"emoji": "0️⃣", "de": "null", "en": "zero", "tr": "sıfır"},
    {"emoji": "1️⃣", "de": "eins", "en": "one", "tr": "bir"},
    {"emoji": "2️⃣", "de": "zwei", "en": "two", "tr": "iki"},
    {"emoji": "3️⃣", "de": "drei", "en": "three", "tr": "üç"},
    {"emoji": "4️⃣", "de": "vier", "en": "four", "tr": "dört"},
    {"emoji": "5️⃣", "de": "fünf", "en": "five", "tr": "beş"},
    {"emoji": "6️⃣", "de": "sechs", "en": "six", "tr": "altı"},
    {"emoji": "7️⃣", "de": "sieben", "en": "seven", "tr": "yedi"},
    {"emoji": "8️⃣", "de": "acht", "en": "eight", "tr": "sekiz"},
    {"emoji": "9️⃣", "de": "neun", "en": "nine", "tr": "dokuz"},
    {"emoji": "🔟", "de": "zehn", "en": "ten", "tr": "on"}
   ]
  },
  {
   "id": "farben", "titel": "Farben", "emoji": "🎨", "stufe": 1,
   "woerter": [
    {"emoji": "🔴", "de": "rot", "en": "red", "tr": "kırmızı"},
    {"emoji": "🔵", "de": "blau", "en": "blue", "tr": "mavi"},
    {"emoji": "🟡", "de": "gelb", "en": "yellow", "tr": "sarı"},
    {"emoji": "🟢", "de": "grün", "en": "green", "tr": "yeşil"},
    {"emoji": "🟠", "de": "orange", "en": "orange", "tr": "turuncu"},
    {"emoji": "🟣", "de": "lila", "en": "purple", "tr": "mor"},
    {"emoji": "⚫", "de": "schwarz", "en": "black", "tr": "siyah"},
    {"emoji": "⚪", "de": "weiß", "en": "white", "tr": "beyaz"},
    {"emoji": "🟤", "de": "braun", "en": "brown", "tr": "kahverengi"},
    {"emoji": "🎀", "de": "rosa", "en": "pink", "tr": "pembe"},
    {"emoji": "🩶", "de": "grau", "en": "grey", "tr": "gri", "alt": {"en": ["gray"]}}
   ]
  },
  {
   "id": "haustiere", "titel": "Haustiere & Bauernhof", "emoji": "🐶", "stufe": 1,
   "woerter": [
    {"emoji": "🐶", "de": "der Hund", "en": "dog", "tr": "köpek"},
    {"emoji": "🐱", "de": "die Katze", "en": "cat", "tr": "kedi"},
    {"emoji": "🐦", "de": "der Vogel", "en": "bird", "tr": "kuş"},
    {"emoji": "🐟", "de": "der Fisch", "en": "fish", "tr": "balık"},
    {"emoji": "🐴", "de": "das Pferd", "en": "horse", "tr": "at"},
    {"emoji": "🐮", "de": "die Kuh", "en": "cow", "tr": "inek"},
    {"emoji": "🐷", "de": "das Schwein", "en": "pig", "tr": "domuz"},
    {"emoji": "🐑", "de": "das Schaf", "en": "sheep", "tr": "koyun"},
    {"emoji": "🐔", "de": "das Huhn", "en": "chicken", "tr": "tavuk"},
    {"emoji": "🐭", "de": "die Maus", "en": "mouse", "tr": "fare"},
    {"emoji": "🐰", "de": "der Hase", "en": "rabbit", "tr": "tavşan"},
    {"emoji": "🦆", "de": "die Ente", "en": "duck", "tr": "ördek"}
   ]
  },
  {
   "id": "familie", "titel": "Familie", "emoji": "👨‍👩‍👧‍👦", "stufe": 1,
   "woerter": [
    {"emoji": "👩", "de": "die Mama", "en": "mum", "tr": "anne", "alt": {"en": ["mom", "mummy", "mother"]}},
    {"emoji": "👨", "de": "der Papa", "en": "dad", "tr": "baba", "alt": {"en": ["daddy", "father"]}},
    {"emoji": "👦", "de": "der Bruder", "en": "brother", "tr": "erkek kardeş"},
    {"emoji": "👧", "de": "die Schwester", "en": "sister", "tr": "kız kardeş"},
    {"emoji": "🧑", "de": "der große Bruder", "en": "big brother", "tr": "abi", "alt": {"en": ["older brother"], "tr": ["ağabey"]}},
    {"emoji": "👱‍♀️", "de": "die große Schwester", "en": "big sister", "tr": "abla", "alt": {"en": ["older sister"]}},
    {"emoji": "👵", "de": "die Oma", "en": "grandma", "tr": "anneanne", "alt": {"en": ["granny", "grandmother", "nan"], "tr": ["babaanne"]}, "hinweis": "Mamas Mutter heißt „anneanne“, Papas Mutter heißt „babaanne“."},
    {"emoji": "👴", "de": "der Opa", "en": "grandpa", "tr": "dede", "alt": {"en": ["grandad", "grandfather"]}},
    {"emoji": "🙋‍♀️", "de": "die Tante", "en": "aunt", "tr": "teyze", "alt": {"en": ["auntie"], "tr": ["hala"]}, "hinweis": "Mamas Schwester heißt „teyze“, Papas Schwester heißt „hala“."},
    {"emoji": "🙋‍♂️", "de": "der Onkel", "en": "uncle", "tr": "dayı", "alt": {"tr": ["amca"]}, "hinweis": "Mamas Bruder heißt „dayı“, Papas Bruder heißt „amca“."},
    {"emoji": "👶", "de": "das Baby", "en": "baby", "tr": "bebek"},
    {"emoji": "🧒", "de": "das Kind", "en": "child", "tr": "çocuk", "alt": {"en": ["kid"]}},
    {"emoji": "👨‍👩‍👧‍👦", "de": "die Familie", "en": "family", "tr": "aile"}
   ]
  },
  {
   "id": "koerper", "titel": "Körper", "emoji": "🧍", "stufe": 1,
   "woerter": [
    {"emoji": "🙂", "de": "der Kopf", "en": "head", "tr": "baş"},
    {"emoji": "👁️", "de": "das Auge", "en": "eye", "tr": "göz"},
    {"emoji": "👂", "de": "das Ohr", "en": "ear", "tr": "kulak"},
    {"emoji": "👃", "de": "die Nase", "en": "nose", "tr": "burun"},
    {"emoji": "👄", "de": "der Mund", "en": "mouth", "tr": "ağız"},
    {"emoji": "✋", "de": "die Hand", "en": "hand", "tr": "el"},
    {"emoji": "🦶", "de": "der Fuß", "en": "foot", "tr": "ayak"},
    {"emoji": "🦵", "de": "das Bein", "en": "leg", "tr": "bacak"},
    {"emoji": "💪", "de": "der Arm", "en": "arm", "tr": "kol"},
    {"emoji": "🦷", "de": "der Zahn", "en": "tooth", "tr": "diş"},
    {"emoji": "💇", "de": "die Haare", "en": "hair", "tr": "saç"},
    {"emoji": "❤️", "de": "das Herz", "en": "heart", "tr": "kalp"}
   ]
  },
  {
   "id": "obst", "titel": "Obst & Gemüse", "emoji": "🍎", "stufe": 1,
   "woerter": [
    {"emoji": "🍎", "de": "der Apfel", "en": "apple", "tr": "elma"},
    {"emoji": "🍌", "de": "die Banane", "en": "banana", "tr": "muz"},
    {"emoji": "🍐", "de": "die Birne", "en": "pear", "tr": "armut"},
    {"emoji": "🍇", "de": "die Traube", "en": "grape", "tr": "üzüm", "alt": {"en": ["grapes"]}},
    {"emoji": "🍓", "de": "die Erdbeere", "en": "strawberry", "tr": "çilek"},
    {"emoji": "🍉", "de": "die Wassermelone", "en": "watermelon", "tr": "karpuz"},
    {"emoji": "🍋", "de": "die Zitrone", "en": "lemon", "tr": "limon"},
    {"emoji": "🍒", "de": "die Kirsche", "en": "cherry", "tr": "kiraz"},
    {"emoji": "🍅", "de": "die Tomate", "en": "tomato", "tr": "domates"},
    {"emoji": "🥔", "de": "die Kartoffel", "en": "potato", "tr": "patates"},
    {"emoji": "🥕", "de": "die Karotte", "en": "carrot", "tr": "havuç"},
    {"emoji": "🥒", "de": "die Gurke", "en": "cucumber", "tr": "salatalık"}
   ]
  },
  {
   "id": "essen", "titel": "Essen & Trinken", "emoji": "🍞", "stufe": 1,
   "woerter": [
    {"emoji": "🍞", "de": "das Brot", "en": "bread", "tr": "ekmek"},
    {"emoji": "🥛", "de": "die Milch", "en": "milk", "tr": "süt"},
    {"emoji": "💧", "de": "das Wasser", "en": "water", "tr": "su"},
    {"emoji": "🍵", "de": "der Tee", "en": "tea", "tr": "çay"},
    {"emoji": "🧃", "de": "der Saft", "en": "juice", "tr": "meyve suyu"},
    {"emoji": "🧀", "de": "der Käse", "en": "cheese", "tr": "peynir"},
    {"emoji": "🥚", "de": "das Ei", "en": "egg", "tr": "yumurta"},
    {"emoji": "🍰", "de": "der Kuchen", "en": "cake", "tr": "pasta", "hinweis": "„pasta“ heißt auf Türkisch Kuchen. Nudeln heißen „makarna“."},
    {"emoji": "🍦", "de": "das Eis", "en": "ice cream", "tr": "dondurma", "alt": {"en": ["ice-cream"]}},
    {"emoji": "🍲", "de": "die Suppe", "en": "soup", "tr": "çorba"},
    {"emoji": "🥩", "de": "das Fleisch", "en": "meat", "tr": "et"},
    {"emoji": "🍯", "de": "der Honig", "en": "honey", "tr": "bal"},
    {"emoji": "🍫", "de": "die Schokolade", "en": "chocolate", "tr": "çikolata"},
    {"emoji": "🍕", "de": "die Pizza", "en": "pizza", "tr": "pizza"}
   ]
  },
  {
   "id": "wildtiere", "titel": "Wilde Tiere", "emoji": "🦁", "stufe": 2,
   "woerter": [
    {"emoji": "🦁", "de": "der Löwe", "en": "lion", "tr": "aslan"},
    {"emoji": "🐘", "de": "der Elefant", "en": "elephant", "tr": "fil"},
    {"emoji": "🐵", "de": "der Affe", "en": "monkey", "tr": "maymun"},
    {"emoji": "🐻", "de": "der Bär", "en": "bear", "tr": "ayı"},
    {"emoji": "🐺", "de": "der Wolf", "en": "wolf", "tr": "kurt"},
    {"emoji": "🦊", "de": "der Fuchs", "en": "fox", "tr": "tilki"},
    {"emoji": "🦒", "de": "die Giraffe", "en": "giraffe", "tr": "zürafa"},
    {"emoji": "🐯", "de": "der Tiger", "en": "tiger", "tr": "kaplan"},
    {"emoji": "🐍", "de": "die Schlange", "en": "snake", "tr": "yılan"},
    {"emoji": "🐸", "de": "der Frosch", "en": "frog", "tr": "kurbağa"},
    {"emoji": "🦋", "de": "der Schmetterling", "en": "butterfly", "tr": "kelebek"},
    {"emoji": "🐝", "de": "die Biene", "en": "bee", "tr": "arı"}
   ]
  },
  {
   "id": "zuhause", "titel": "Zuhause", "emoji": "🏠", "stufe": 2,
   "woerter": [
    {"emoji": "🏠", "de": "das Haus", "en": "house", "tr": "ev"},
    {"emoji": "🛋️", "de": "das Zimmer", "en": "room", "tr": "oda"},
    {"emoji": "🚪", "de": "die Tür", "en": "door", "tr": "kapı"},
    {"emoji": "🪟", "de": "das Fenster", "en": "window", "tr": "pencere"},
    {"emoji": "🍽️", "de": "der Tisch", "en": "table", "tr": "masa"},
    {"emoji": "🪑", "de": "der Stuhl", "en": "chair", "tr": "sandalye"},
    {"emoji": "🛏️", "de": "das Bett", "en": "bed", "tr": "yatak"},
    {"emoji": "🍳", "de": "die Küche", "en": "kitchen", "tr": "mutfak"},
    {"emoji": "🛁", "de": "das Bad", "en": "bathroom", "tr": "banyo"},
    {"emoji": "🌳", "de": "der Garten", "en": "garden", "tr": "bahçe"},
    {"emoji": "💡", "de": "die Lampe", "en": "lamp", "tr": "lamba"},
    {"emoji": "🔑", "de": "der Schlüssel", "en": "key", "tr": "anahtar"},
    {"emoji": "📺", "de": "der Fernseher", "en": "TV", "tr": "televizyon", "alt": {"en": ["television"]}},
    {"emoji": "🕐", "de": "die Uhr", "en": "clock", "tr": "saat"}
   ]
  },
  {
   "id": "schule", "titel": "Schule", "emoji": "🏫", "stufe": 2,
   "woerter": [
    {"emoji": "🏫", "de": "die Schule", "en": "school", "tr": "okul"},
    {"emoji": "👥", "de": "die Klasse", "en": "class", "tr": "sınıf"},
    {"emoji": "👩‍🏫", "de": "die Lehrerin", "en": "teacher", "tr": "öğretmen"},
    {"emoji": "🧑‍🎓", "de": "der Schüler", "en": "pupil", "tr": "öğrenci", "alt": {"en": ["student"]}},
    {"emoji": "📖", "de": "das Buch", "en": "book", "tr": "kitap"},
    {"emoji": "📓", "de": "das Heft", "en": "exercise book", "tr": "defter", "alt": {"en": ["notebook"]}},
    {"emoji": "✏️", "de": "der Bleistift", "en": "pencil", "tr": "kurşun kalem"},
    {"emoji": "🧽", "de": "der Radiergummi", "en": "rubber", "tr": "silgi", "alt": {"en": ["eraser"]}},
    {"emoji": "📏", "de": "das Lineal", "en": "ruler", "tr": "cetvel"},
    {"emoji": "✂️", "de": "die Schere", "en": "scissors", "tr": "makas"},
    {"emoji": "🎒", "de": "die Schultasche", "en": "school bag", "tr": "okul çantası", "alt": {"en": ["schoolbag", "bag"], "tr": ["çanta"]}},
    {"emoji": "📝", "de": "die Hausaufgaben", "en": "homework", "tr": "ödev"},
    {"emoji": "🔔", "de": "die Pause", "en": "break", "tr": "teneffüs", "alt": {"en": ["playtime"], "tr": ["ara"]}},
    {"emoji": "➗", "de": "die Mathe", "en": "maths", "tr": "matematik", "alt": {"en": ["math"]}}
   ]
  },
  {
   "id": "kleidung", "titel": "Kleidung", "emoji": "👕", "stufe": 2,
   "woerter": [
    {"emoji": "👕", "de": "das T-Shirt", "en": "t-shirt", "tr": "tişört"},
    {"emoji": "👖", "de": "die Hose", "en": "trousers", "tr": "pantolon", "alt": {"en": ["pants"]}},
    {"emoji": "👗", "de": "das Kleid", "en": "dress", "tr": "elbise"},
    {"emoji": "👟", "de": "die Schuhe", "en": "shoes", "tr": "ayakkabı"},
    {"emoji": "🧦", "de": "die Socken", "en": "socks", "tr": "çorap"},
    {"emoji": "🧢", "de": "die Mütze", "en": "hat", "tr": "şapka", "alt": {"en": ["cap"], "tr": ["bere"]}},
    {"emoji": "🧥", "de": "die Jacke", "en": "jacket", "tr": "ceket"},
    {"emoji": "🧶", "de": "der Pullover", "en": "jumper", "tr": "kazak", "alt": {"en": ["sweater", "pullover"]}},
    {"emoji": "🧤", "de": "die Handschuhe", "en": "gloves", "tr": "eldiven"},
    {"emoji": "🧣", "de": "der Schal", "en": "scarf", "tr": "atkı"},
    {"emoji": "👓", "de": "die Brille", "en": "glasses", "tr": "gözlük"}
   ]
  },
  {
   "id": "wetter", "titel": "Wetter & Natur", "emoji": "☀️", "stufe": 2,
   "woerter": [
    {"emoji": "☀️", "de": "die Sonne", "en": "sun", "tr": "güneş"},
    {"emoji": "🌙", "de": "der Mond", "en": "moon", "tr": "ay"},
    {"emoji": "⭐", "de": "der Stern", "en": "star", "tr": "yıldız"},
    {"emoji": "☁️", "de": "die Wolke", "en": "cloud", "tr": "bulut"},
    {"emoji": "🌧️", "de": "der Regen", "en": "rain", "tr": "yağmur"},
    {"emoji": "❄️", "de": "der Schnee", "en": "snow", "tr": "kar"},
    {"emoji": "💨", "de": "der Wind", "en": "wind", "tr": "rüzgâr", "alt": {"tr": ["rüzgar"]}},
    {"emoji": "🌸", "de": "die Blume", "en": "flower", "tr": "çiçek"},
    {"emoji": "🌳", "de": "der Baum", "en": "tree", "tr": "ağaç"},
    {"emoji": "🌊", "de": "das Meer", "en": "sea", "tr": "deniz"},
    {"emoji": "⛰️", "de": "der Berg", "en": "mountain", "tr": "dağ"},
    {"emoji": "🌤️", "de": "der Himmel", "en": "sky", "tr": "gökyüzü", "alt": {"tr": ["gök"]}},
    {"emoji": "🔥", "de": "das Feuer", "en": "fire", "tr": "ateş"}
   ]
  },
  {
   "id": "fahrzeuge", "titel": "Fahrzeuge", "emoji": "🚗", "stufe": 2,
   "woerter": [
    {"emoji": "🚗", "de": "das Auto", "en": "car", "tr": "araba", "alt": {"tr": ["otomobil"]}},
    {"emoji": "🚌", "de": "der Bus", "en": "bus", "tr": "otobüs"},
    {"emoji": "🚆", "de": "der Zug", "en": "train", "tr": "tren"},
    {"emoji": "🚲", "de": "das Fahrrad", "en": "bike", "tr": "bisiklet", "alt": {"en": ["bicycle"]}},
    {"emoji": "✈️", "de": "das Flugzeug", "en": "plane", "tr": "uçak", "alt": {"en": ["aeroplane", "airplane"]}},
    {"emoji": "🚢", "de": "das Schiff", "en": "ship", "tr": "gemi"},
    {"emoji": "⛵", "de": "das Boot", "en": "boat", "tr": "tekne"},
    {"emoji": "🚜", "de": "der Traktor", "en": "tractor", "tr": "traktör"},
    {"emoji": "🚒", "de": "das Feuerwehrauto", "en": "fire engine", "tr": "itfaiye arabası", "alt": {"en": ["fire truck"]}},
    {"emoji": "🚑", "de": "der Krankenwagen", "en": "ambulance", "tr": "ambulans"},
    {"emoji": "🏍️", "de": "das Motorrad", "en": "motorbike", "tr": "motosiklet", "alt": {"en": ["motorcycle"]}},
    {"emoji": "🚁", "de": "der Hubschrauber", "en": "helicopter", "tr": "helikopter"}
   ]
  },
  {
   "id": "stadt", "titel": "Stadt & Orte", "emoji": "🏙️", "stufe": 2,
   "woerter": [
    {"emoji": "🏙️", "de": "die Stadt", "en": "city", "tr": "şehir", "alt": {"tr": ["kent"]}},
    {"emoji": "🏘️", "de": "das Dorf", "en": "village", "tr": "köy"},
    {"emoji": "🛣️", "de": "die Straße", "en": "street", "tr": "sokak", "alt": {"en": ["road"], "tr": ["yol"]}},
    {"emoji": "🏞️", "de": "der Park", "en": "park", "tr": "park"},
    {"emoji": "🛝", "de": "der Spielplatz", "en": "playground", "tr": "oyun parkı"},
    {"emoji": "🛒", "de": "der Supermarkt", "en": "supermarket", "tr": "süpermarket", "alt": {"tr": ["market"]}},
    {"emoji": "🥖", "de": "die Bäckerei", "en": "bakery", "tr": "fırın", "alt": {"tr": ["ekmek fırını"]}},
    {"emoji": "🏥", "de": "das Krankenhaus", "en": "hospital", "tr": "hastane"},
    {"emoji": "🚉", "de": "der Bahnhof", "en": "station", "tr": "istasyon", "alt": {"en": ["train station", "railway station"], "tr": ["gar"]}},
    {"emoji": "🎬", "de": "das Kino", "en": "cinema", "tr": "sinema"},
    {"emoji": "🌉", "de": "die Brücke", "en": "bridge", "tr": "köprü"},
    {"emoji": "🏛️", "de": "das Museum", "en": "museum", "tr": "müze"}
   ]
  },
  {
   "id": "freizeit", "titel": "Spielen & Freizeit", "emoji": "🎮", "stufe": 2,
   "woerter": [
    {"emoji": "🧸", "de": "das Spielzeug", "en": "toy", "tr": "oyuncak"},
    {"emoji": "🏐", "de": "der Ball", "en": "ball", "tr": "top"},
    {"emoji": "⚽", "de": "der Fußball", "en": "football", "tr": "futbol", "alt": {"en": ["soccer"]}},
    {"emoji": "🪆", "de": "die Puppe", "en": "doll", "tr": "oyuncak bebek"},
    {"emoji": "🧩", "de": "das Puzzle", "en": "puzzle", "tr": "yapboz", "alt": {"tr": ["puzzle"]}},
    {"emoji": "🎮", "de": "das Spiel", "en": "game", "tr": "oyun"},
    {"emoji": "♟️", "de": "das Schach", "en": "chess", "tr": "satranç"},
    {"emoji": "🪁", "de": "der Drachen (zum Fliegen)", "en": "kite", "tr": "uçurtma"},
    {"emoji": "🎵", "de": "die Musik", "en": "music", "tr": "müzik"},
    {"emoji": "🎸", "de": "die Gitarre", "en": "guitar", "tr": "gitar"},
    {"emoji": "📱", "de": "das Handy", "en": "mobile phone", "tr": "cep telefonu", "alt": {"en": ["phone", "mobile", "cell phone"], "tr": ["telefon"]}},
    {"emoji": "💻", "de": "der Computer", "en": "computer", "tr": "bilgisayar"},
    {"emoji": "📷", "de": "die Kamera", "en": "camera", "tr": "kamera"},
    {"emoji": "🖼️", "de": "das Bild", "en": "picture", "tr": "resim"}
   ]
  },
  {
   "id": "wochentage", "titel": "Wochentage", "emoji": "📅", "stufe": 2, "bilder": false,
   "woerter": [
    {"de": "Montag", "en": "Monday", "tr": "Pazartesi"},
    {"de": "Dienstag", "en": "Tuesday", "tr": "Salı"},
    {"de": "Mittwoch", "en": "Wednesday", "tr": "Çarşamba"},
    {"de": "Donnerstag", "en": "Thursday", "tr": "Perşembe"},
    {"de": "Freitag", "en": "Friday", "tr": "Cuma"},
    {"de": "Samstag", "en": "Saturday", "tr": "Cumartesi"},
    {"de": "Sonntag", "en": "Sunday", "tr": "Pazar"}
   ]
  },
  {
   "id": "zahl20", "titel": "Zahlen 11 bis 20", "emoji": "🔢", "stufe": 2,
   "woerter": [
    {"emoji": "11", "de": "elf", "en": "eleven", "tr": "on bir"},
    {"emoji": "12", "de": "zwölf", "en": "twelve", "tr": "on iki"},
    {"emoji": "13", "de": "dreizehn", "en": "thirteen", "tr": "on üç"},
    {"emoji": "14", "de": "vierzehn", "en": "fourteen", "tr": "on dört"},
    {"emoji": "15", "de": "fünfzehn", "en": "fifteen", "tr": "on beş"},
    {"emoji": "16", "de": "sechzehn", "en": "sixteen", "tr": "on altı"},
    {"emoji": "17", "de": "siebzehn", "en": "seventeen", "tr": "on yedi"},
    {"emoji": "18", "de": "achtzehn", "en": "eighteen", "tr": "on sekiz"},
    {"emoji": "19", "de": "neunzehn", "en": "nineteen", "tr": "on dokuz"},
    {"emoji": "20", "de": "zwanzig", "en": "twenty", "tr": "yirmi"}
   ]
  },
  {
   "id": "monate", "titel": "Monate", "emoji": "🗓️", "stufe": 3, "bilder": false,
   "woerter": [
    {"de": "Januar", "en": "January", "tr": "Ocak"},
    {"de": "Februar", "en": "February", "tr": "Şubat"},
    {"de": "März", "en": "March", "tr": "Mart"},
    {"de": "April", "en": "April", "tr": "Nisan"},
    {"de": "Mai", "en": "May", "tr": "Mayıs"},
    {"de": "Juni", "en": "June", "tr": "Haziran"},
    {"de": "Juli", "en": "July", "tr": "Temmuz"},
    {"de": "August", "en": "August", "tr": "Ağustos"},
    {"de": "September", "en": "September", "tr": "Eylül"},
    {"de": "Oktober", "en": "October", "tr": "Ekim"},
    {"de": "November", "en": "November", "tr": "Kasım"},
    {"de": "Dezember", "en": "December", "tr": "Aralık"}
   ]
  },
  {
   "id": "zeit", "titel": "Jahreszeiten & Zeit", "emoji": "🌷", "stufe": 3,
   "woerter": [
    {"emoji": "🌷", "de": "der Frühling", "en": "spring", "tr": "ilkbahar", "alt": {"tr": ["bahar"]}},
    {"emoji": "🏖️", "de": "der Sommer", "en": "summer", "tr": "yaz"},
    {"emoji": "🍂", "de": "der Herbst", "en": "autumn", "tr": "sonbahar", "alt": {"en": ["fall"]}},
    {"emoji": "☃️", "de": "der Winter", "en": "winter", "tr": "kış"},
    {"de": "heute", "en": "today", "tr": "bugün"},
    {"de": "gestern", "en": "yesterday", "tr": "dün"},
    {"de": "morgen (der nächste Tag)", "en": "tomorrow", "tr": "yarın"},
    {"emoji": "🌅", "de": "der Morgen (früh)", "en": "morning", "tr": "sabah"},
    {"emoji": "🌇", "de": "der Abend", "en": "evening", "tr": "akşam"},
    {"emoji": "🌙", "de": "die Nacht", "en": "night", "tr": "gece"},
    {"emoji": "📆", "de": "die Woche", "en": "week", "tr": "hafta"},
    {"emoji": "🎆", "de": "das Jahr", "en": "year", "tr": "yıl"},
    {"emoji": "🌞", "de": "der Tag", "en": "day", "tr": "gün"}
   ]
  },
  {
   "id": "taetigkeiten", "titel": "Tätigkeiten", "emoji": "🏃", "stufe": 3,
   "woerter": [
    {"emoji": "🏃", "de": "laufen", "en": "run", "tr": "koşmak"},
    {"emoji": "🏊", "de": "schwimmen", "en": "swim", "tr": "yüzmek"},
    {"emoji": "🦘", "de": "springen", "en": "jump", "tr": "zıplamak"},
    {"emoji": "🍽️", "de": "essen", "en": "eat", "tr": "yemek"},
    {"emoji": "🥤", "de": "trinken", "en": "drink", "tr": "içmek"},
    {"emoji": "😴", "de": "schlafen", "en": "sleep", "tr": "uyumak"},
    {"emoji": "🎮", "de": "spielen", "en": "play", "tr": "oynamak"},
    {"emoji": "📖", "de": "lesen", "en": "read", "tr": "okumak"},
    {"emoji": "✍️", "de": "schreiben", "en": "write", "tr": "yazmak"},
    {"emoji": "🎤", "de": "singen", "en": "sing", "tr": "şarkı söylemek"},
    {"emoji": "💃", "de": "tanzen", "en": "dance", "tr": "dans etmek"},
    {"emoji": "😂", "de": "lachen", "en": "laugh", "tr": "gülmek"},
    {"emoji": "😢", "de": "weinen", "en": "cry", "tr": "ağlamak"},
    {"emoji": "🤝", "de": "helfen", "en": "help", "tr": "yardım etmek"}
   ]
  },
  {
   "id": "gegenteile", "titel": "Gegenteile", "emoji": "↔️", "stufe": 3,
   "woerter": [
    {"emoji": "🐘", "de": "groß", "en": "big", "tr": "büyük"},
    {"emoji": "🐜", "de": "klein", "en": "small", "tr": "küçük"},
    {"emoji": "🥵", "de": "heiß", "en": "hot", "tr": "sıcak"},
    {"emoji": "🥶", "de": "kalt", "en": "cold", "tr": "soğuk"},
    {"emoji": "🐇", "de": "schnell", "en": "fast", "tr": "hızlı"},
    {"emoji": "🐢", "de": "langsam", "en": "slow", "tr": "yavaş"},
    {"emoji": "🆕", "de": "neu", "en": "new", "tr": "yeni"},
    {"emoji": "🕰️", "de": "alt", "en": "old", "tr": "eski", "hinweis": "„eski“ sagt man bei Dingen. Bei Menschen heißt alt „yaşlı“."},
    {"emoji": "👍", "de": "gut", "en": "good", "tr": "iyi"},
    {"emoji": "👎", "de": "schlecht", "en": "bad", "tr": "kötü"},
    {"emoji": "😊", "de": "glücklich", "en": "happy", "tr": "mutlu"},
    {"emoji": "😔", "de": "traurig", "en": "sad", "tr": "üzgün"},
    {"emoji": "🤫", "de": "leise", "en": "quiet", "tr": "sessiz"},
    {"emoji": "🌺", "de": "schön", "en": "beautiful", "tr": "güzel", "alt": {"en": ["pretty", "nice"]}}
   ]
  },
  {
   "id": "zehner", "titel": "Zehnerzahlen bis 100", "emoji": "💯", "stufe": 3,
   "woerter": [
    {"emoji": "30", "de": "dreißig", "en": "thirty", "tr": "otuz"},
    {"emoji": "40", "de": "vierzig", "en": "forty", "tr": "kırk"},
    {"emoji": "50", "de": "fünfzig", "en": "fifty", "tr": "elli"},
    {"emoji": "60", "de": "sechzig", "en": "sixty", "tr": "altmış"},
    {"emoji": "70", "de": "siebzig", "en": "seventy", "tr": "yetmiş"},
    {"emoji": "80", "de": "achtzig", "en": "eighty", "tr": "seksen"},
    {"emoji": "90", "de": "neunzig", "en": "ninety", "tr": "doksan"},
    {"emoji": "100", "de": "hundert", "en": "hundred", "tr": "yüz"}
   ]
  },
  {
   "id": "saetze", "titel": "Kleine Sätze", "emoji": "💬", "stufe": 3, "bilder": false, "typ": "saetze",
   "woerter": [
    {"emoji": "🌅", "de": "Guten Morgen!", "en": "Good morning!", "tr": "Günaydın!"},
    {"emoji": "🌇", "de": "Guten Abend!", "en": "Good evening!", "tr": "İyi akşamlar!"},
    {"emoji": "🌙", "de": "Gute Nacht!", "en": "Good night!", "tr": "İyi geceler!"},
    {"emoji": "🙂", "de": "Wie geht es dir?", "en": "How are you?", "tr": "Nasılsın?"},
    {"emoji": "😊", "de": "Mir geht es gut.", "en": "I am fine.", "tr": "İyiyim.", "alt": {"en": ["I'm fine.", "I am good.", "I'm good."]}},
    {"emoji": "❓", "de": "Wie heißt du?", "en": "What is your name?", "tr": "Adın ne?", "alt": {"en": ["What's your name?"], "tr": ["Senin adın ne?", "Adın nedir?"]}},
    {"emoji": "🙋", "de": "Ich heiße Ali.", "en": "My name is Ali.", "tr": "Benim adım Ali.", "alt": {"tr": ["Adım Ali."]}},
    {"emoji": "🎂", "de": "Wie alt bist du?", "en": "How old are you?", "tr": "Kaç yaşındasın?"},
    {"emoji": "🔢", "de": "Ich bin acht Jahre alt.", "en": "I am eight years old.", "tr": "Ben sekiz yaşındayım.", "alt": {"en": ["I'm eight years old.", "I'm eight.", "I am eight."], "tr": ["Sekiz yaşındayım."]}},
    {"emoji": "🍽️", "de": "Ich habe Hunger.", "en": "I am hungry.", "tr": "Acıktım.", "alt": {"en": ["I'm hungry."], "tr": ["Karnım aç."]}},
    {"emoji": "🥤", "de": "Ich habe Durst.", "en": "I am thirsty.", "tr": "Susadım.", "alt": {"en": ["I'm thirsty."]}},
    {"emoji": "❤️", "de": "Ich liebe dich.", "en": "I love you.", "tr": "Seni seviyorum."},
    {"emoji": "🤷", "de": "Ich verstehe das nicht.", "en": "I do not understand.", "tr": "Anlamıyorum.", "alt": {"en": ["I don't understand.", "I do not understand that.", "I don't understand that."], "tr": ["Bunu anlamıyorum."]}},
    {"emoji": "🆘", "de": "Kannst du mir helfen?", "en": "Can you help me?", "tr": "Bana yardım edebilir misin?"},
    {"emoji": "🚻", "de": "Wo ist die Toilette?", "en": "Where is the toilet?", "tr": "Tuvalet nerede?"},
    {"emoji": "🧑‍🤝‍🧑", "de": "Das ist mein Freund.", "en": "This is my friend.", "tr": "Bu benim arkadaşım."},
    {"emoji": "🍕", "de": "Ich mag Pizza.", "en": "I like pizza.", "tr": "Pizzayı severim.", "alt": {"tr": ["Pizza severim."]}},
    {"emoji": "⚽", "de": "Ich spiele Fußball.", "en": "I play football.", "tr": "Futbol oynuyorum.", "alt": {"en": ["I play soccer."]}},
    {"emoji": "🔍", "de": "Was ist das?", "en": "What is this?", "tr": "Bu nedir?", "alt": {"en": ["What is that?", "What's this?"], "tr": ["Bu ne?"]}},
    {"emoji": "🥵", "de": "Heute ist es heiß.", "en": "It is hot today.", "tr": "Bugün hava sıcak.", "alt": {"en": ["It's hot today."]}},
    {"emoji": "👋", "de": "Bis morgen!", "en": "See you tomorrow!", "tr": "Yarın görüşürüz!"},
    {"emoji": "😊", "de": "Gern geschehen!", "en": "You are welcome!", "tr": "Rica ederim!", "alt": {"en": ["You're welcome!", "No problem!"]}},
    {"emoji": "🍀", "de": "Viel Glück!", "en": "Good luck!", "tr": "Bol şans!", "alt": {"tr": ["İyi şanslar!"]}},
    {"emoji": "🎉", "de": "Herzlichen Glückwunsch!", "en": "Congratulations!", "tr": "Tebrikler!"},
    {"emoji": "🎈", "de": "Alles Gute zum Geburtstag!", "en": "Happy birthday!", "tr": "Doğum günün kutlu olsun!", "alt": {"tr": ["İyi ki doğdun!"]}}
   ]
  }
 ]
}
"""#
}
