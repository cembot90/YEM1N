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

// MARK: - Eingebauter Sprachkatalog (Englisch, Türkisch und Italienisch)

enum SprachKatalogDaten {
    static let json = #"""
{
 "typ": "sprachkatalog",
 "version": 1,
 "titel": "YEM1N Sprachen",
 "sprachen": {"de": {"name": "Deutsch", "flagge": "🇩🇪", "sprachcode": "de-DE"}, "en": {"name": "Englisch", "flagge": "🇬🇧", "sprachcode": "en-GB"}, "tr": {"name": "Türkisch", "flagge": "🇹🇷", "sprachcode": "tr-TR"}, "it": {"name": "Italienisch", "flagge": "🇮🇹", "sprachcode": "it-IT"}},
 "lernsprachen": ["en", "tr", "it"],
 "themen": [
  {
   "id": "hallo", "titel": "Hallo & Danke", "emoji": "👋", "stufe": 1,
   "woerter": [
    {"emoji": "👋", "de": "Hallo", "en": "hello", "tr": "merhaba", "it": "ciao", "alt": {"en": ["hi"], "it": ["salve"]}},
    {"emoji": "🚶", "de": "Tschüss", "en": "goodbye", "tr": "hoşça kal", "it": "arrivederci", "alt": {"en": ["bye"], "tr": ["güle güle"], "it": ["ciao", "addio"]}, "hinweise": {"tr": "Wer geht, sagt „hoşça kal“. Wer bleibt, sagt „güle güle“.", "it": "„ciao“ sagt man zum Begrüßen und zum Verabschieden. „arrivederci“ ist etwas höflicher."}},
    {"emoji": "✅", "de": "ja", "en": "yes", "tr": "evet", "it": "sì", "alt": {"it": ["si"]}},
    {"emoji": "❌", "de": "nein", "en": "no", "tr": "hayır", "it": "no"},
    {"emoji": "🙏", "de": "Danke", "en": "thank you", "tr": "teşekkürler", "it": "grazie", "alt": {"en": ["thanks"], "tr": ["teşekkür ederim", "sağ ol"]}},
    {"emoji": "🙋", "de": "bitte", "en": "please", "tr": "lütfen", "it": "per favore", "alt": {"it": ["per piacere"]}},
    {"emoji": "😔", "de": "Entschuldigung", "en": "sorry", "tr": "özür dilerim", "it": "scusa", "alt": {"tr": ["pardon"], "it": ["scusi", "scusami", "mi dispiace"]}},
    {"emoji": "🧑‍🤝‍🧑", "de": "der Freund", "en": "friend", "tr": "arkadaş", "it": "l'amico", "hinweise": {"it": "Vor einem Vokal werden „il“ und „la“ zu „l'“."}},
    {"emoji": "🏷️", "de": "der Name", "en": "name", "tr": "ad", "it": "il nome", "alt": {"tr": ["isim"]}}
   ]
  },
  {
   "id": "zahl0", "titel": "Zahlen 0 bis 10", "emoji": "🔢", "stufe": 1,
   "woerter": [
    {"emoji": "0️⃣", "de": "null", "en": "zero", "tr": "sıfır", "it": "zero"},
    {"emoji": "1️⃣", "de": "eins", "en": "one", "tr": "bir", "it": "uno"},
    {"emoji": "2️⃣", "de": "zwei", "en": "two", "tr": "iki", "it": "due"},
    {"emoji": "3️⃣", "de": "drei", "en": "three", "tr": "üç", "it": "tre"},
    {"emoji": "4️⃣", "de": "vier", "en": "four", "tr": "dört", "it": "quattro"},
    {"emoji": "5️⃣", "de": "fünf", "en": "five", "tr": "beş", "it": "cinque"},
    {"emoji": "6️⃣", "de": "sechs", "en": "six", "tr": "altı", "it": "sei"},
    {"emoji": "7️⃣", "de": "sieben", "en": "seven", "tr": "yedi", "it": "sette"},
    {"emoji": "8️⃣", "de": "acht", "en": "eight", "tr": "sekiz", "it": "otto"},
    {"emoji": "9️⃣", "de": "neun", "en": "nine", "tr": "dokuz", "it": "nove"},
    {"emoji": "🔟", "de": "zehn", "en": "ten", "tr": "on", "it": "dieci"}
   ]
  },
  {
   "id": "farben", "titel": "Farben", "emoji": "🎨", "stufe": 1,
   "woerter": [
    {"emoji": "🔴", "de": "rot", "en": "red", "tr": "kırmızı", "it": "rosso"},
    {"emoji": "🔵", "de": "blau", "en": "blue", "tr": "mavi", "it": "blu", "alt": {"it": ["azzurro"]}},
    {"emoji": "🟡", "de": "gelb", "en": "yellow", "tr": "sarı", "it": "giallo"},
    {"emoji": "🟢", "de": "grün", "en": "green", "tr": "yeşil", "it": "verde"},
    {"emoji": "🟠", "de": "orange", "en": "orange", "tr": "turuncu", "it": "arancione", "alt": {"it": ["arancio"]}},
    {"emoji": "🟣", "de": "lila", "en": "purple", "tr": "mor", "it": "viola"},
    {"emoji": "⚫", "de": "schwarz", "en": "black", "tr": "siyah", "it": "nero"},
    {"emoji": "⚪", "de": "weiß", "en": "white", "tr": "beyaz", "it": "bianco"},
    {"emoji": "🟤", "de": "braun", "en": "brown", "tr": "kahverengi", "it": "marrone"},
    {"emoji": "🎀", "de": "rosa", "en": "pink", "tr": "pembe", "it": "rosa"},
    {"emoji": "🩶", "de": "grau", "en": "grey", "tr": "gri", "it": "grigio", "alt": {"en": ["gray"]}}
   ]
  },
  {
   "id": "haustiere", "titel": "Haustiere & Bauernhof", "emoji": "🐶", "stufe": 1,
   "woerter": [
    {"emoji": "🐶", "de": "der Hund", "en": "dog", "tr": "köpek", "it": "il cane"},
    {"emoji": "🐱", "de": "die Katze", "en": "cat", "tr": "kedi", "it": "il gatto", "alt": {"it": ["la gatta"]}},
    {"emoji": "🐦", "de": "der Vogel", "en": "bird", "tr": "kuş", "it": "l'uccello"},
    {"emoji": "🐟", "de": "der Fisch", "en": "fish", "tr": "balık", "it": "il pesce"},
    {"emoji": "🐴", "de": "das Pferd", "en": "horse", "tr": "at", "it": "il cavallo"},
    {"emoji": "🐮", "de": "die Kuh", "en": "cow", "tr": "inek", "it": "la mucca"},
    {"emoji": "🐷", "de": "das Schwein", "en": "pig", "tr": "domuz", "it": "il maiale", "alt": {"it": ["il porco"]}},
    {"emoji": "🐑", "de": "das Schaf", "en": "sheep", "tr": "koyun", "it": "la pecora"},
    {"emoji": "🐔", "de": "das Huhn", "en": "chicken", "tr": "tavuk", "it": "la gallina", "alt": {"it": ["il pollo"]}},
    {"emoji": "🐭", "de": "die Maus", "en": "mouse", "tr": "fare", "it": "il topo"},
    {"emoji": "🐰", "de": "der Hase", "en": "rabbit", "tr": "tavşan", "it": "il coniglio"},
    {"emoji": "🦆", "de": "die Ente", "en": "duck", "tr": "ördek", "it": "l'anatra"}
   ]
  },
  {
   "id": "familie", "titel": "Familie", "emoji": "👨‍👩‍👧‍👦", "stufe": 1,
   "woerter": [
    {"emoji": "👩", "de": "die Mama", "en": "mum", "tr": "anne", "it": "la mamma", "alt": {"en": ["mom", "mummy", "mother"], "it": ["la madre"]}},
    {"emoji": "👨", "de": "der Papa", "en": "dad", "tr": "baba", "it": "il papà", "alt": {"en": ["daddy", "father"], "it": ["il papa", "il babbo", "il padre"]}},
    {"emoji": "👦", "de": "der Bruder", "en": "brother", "tr": "erkek kardeş", "it": "il fratello"},
    {"emoji": "👧", "de": "die Schwester", "en": "sister", "tr": "kız kardeş", "it": "la sorella"},
    {"emoji": "🧑", "de": "der große Bruder", "en": "big brother", "tr": "abi", "it": "il fratello maggiore", "alt": {"en": ["older brother"], "tr": ["ağabey"]}},
    {"emoji": "👱‍♀️", "de": "die große Schwester", "en": "big sister", "tr": "abla", "it": "la sorella maggiore", "alt": {"en": ["older sister"]}},
    {"emoji": "👵", "de": "die Oma", "en": "grandma", "tr": "anneanne", "it": "la nonna", "alt": {"en": ["granny", "grandmother", "nan"], "tr": ["babaanne"]}, "hinweise": {"tr": "Mamas Mutter heißt „anneanne“, Papas Mutter heißt „babaanne“."}},
    {"emoji": "👴", "de": "der Opa", "en": "grandpa", "tr": "dede", "it": "il nonno", "alt": {"en": ["grandad", "grandfather"]}},
    {"emoji": "🙋‍♀️", "de": "die Tante", "en": "aunt", "tr": "teyze", "it": "la zia", "alt": {"en": ["auntie"], "tr": ["hala"]}, "hinweise": {"tr": "Mamas Schwester heißt „teyze“, Papas Schwester heißt „hala“."}},
    {"emoji": "🙋‍♂️", "de": "der Onkel", "en": "uncle", "tr": "dayı", "it": "lo zio", "alt": {"tr": ["amca"]}, "hinweise": {"tr": "Mamas Bruder heißt „dayı“, Papas Bruder heißt „amca“.", "it": "Vor „z“ steht „lo“ statt „il“."}},
    {"emoji": "👶", "de": "das Baby", "en": "baby", "tr": "bebek", "it": "il neonato", "alt": {"it": ["il bebè", "il bambino piccolo", "il baby"]}},
    {"emoji": "🧒", "de": "das Kind", "en": "child", "tr": "çocuk", "it": "il bambino", "alt": {"en": ["kid"], "it": ["la bambina"]}},
    {"emoji": "👨‍👩‍👧‍👦", "de": "die Familie", "en": "family", "tr": "aile", "it": "la famiglia"}
   ]
  },
  {
   "id": "koerper", "titel": "Körper", "emoji": "🧍", "stufe": 1,
   "woerter": [
    {"emoji": "🙂", "de": "der Kopf", "en": "head", "tr": "baş", "it": "la testa"},
    {"emoji": "👁️", "de": "das Auge", "en": "eye", "tr": "göz", "it": "l'occhio"},
    {"emoji": "👂", "de": "das Ohr", "en": "ear", "tr": "kulak", "it": "l'orecchio"},
    {"emoji": "👃", "de": "die Nase", "en": "nose", "tr": "burun", "it": "il naso"},
    {"emoji": "👄", "de": "der Mund", "en": "mouth", "tr": "ağız", "it": "la bocca"},
    {"emoji": "✋", "de": "die Hand", "en": "hand", "tr": "el", "it": "la mano", "hinweise": {"it": "„la mano“ ist weiblich, obwohl es auf „o“ endet."}},
    {"emoji": "🦶", "de": "der Fuß", "en": "foot", "tr": "ayak", "it": "il piede"},
    {"emoji": "🦵", "de": "das Bein", "en": "leg", "tr": "bacak", "it": "la gamba"},
    {"emoji": "💪", "de": "der Arm", "en": "arm", "tr": "kol", "it": "il braccio"},
    {"emoji": "🦷", "de": "der Zahn", "en": "tooth", "tr": "diş", "it": "il dente"},
    {"emoji": "💇", "de": "die Haare", "en": "hair", "tr": "saç", "it": "i capelli"},
    {"emoji": "❤️", "de": "das Herz", "en": "heart", "tr": "kalp", "it": "il cuore"}
   ]
  },
  {
   "id": "obst", "titel": "Obst & Gemüse", "emoji": "🍎", "stufe": 1,
   "woerter": [
    {"emoji": "🍎", "de": "der Apfel", "en": "apple", "tr": "elma", "it": "la mela"},
    {"emoji": "🍌", "de": "die Banane", "en": "banana", "tr": "muz", "it": "la banana"},
    {"emoji": "🍐", "de": "die Birne", "en": "pear", "tr": "armut", "it": "la pera"},
    {"emoji": "🍇", "de": "die Traube", "en": "grape", "tr": "üzüm", "it": "l'uva", "alt": {"en": ["grapes"], "it": ["gli acini"]}},
    {"emoji": "🍓", "de": "die Erdbeere", "en": "strawberry", "tr": "çilek", "it": "la fragola"},
    {"emoji": "🍉", "de": "die Wassermelone", "en": "watermelon", "tr": "karpuz", "it": "l'anguria", "alt": {"it": ["il cocomero"]}},
    {"emoji": "🍋", "de": "die Zitrone", "en": "lemon", "tr": "limon", "it": "il limone"},
    {"emoji": "🍒", "de": "die Kirsche", "en": "cherry", "tr": "kiraz", "it": "la ciliegia"},
    {"emoji": "🍅", "de": "die Tomate", "en": "tomato", "tr": "domates", "it": "il pomodoro"},
    {"emoji": "🥔", "de": "die Kartoffel", "en": "potato", "tr": "patates", "it": "la patata"},
    {"emoji": "🥕", "de": "die Karotte", "en": "carrot", "tr": "havuç", "it": "la carota"},
    {"emoji": "🥒", "de": "die Gurke", "en": "cucumber", "tr": "salatalık", "it": "il cetriolo"}
   ]
  },
  {
   "id": "essen", "titel": "Essen & Trinken", "emoji": "🍞", "stufe": 1,
   "woerter": [
    {"emoji": "🍞", "de": "das Brot", "en": "bread", "tr": "ekmek", "it": "il pane"},
    {"emoji": "🥛", "de": "die Milch", "en": "milk", "tr": "süt", "it": "il latte"},
    {"emoji": "💧", "de": "das Wasser", "en": "water", "tr": "su", "it": "l'acqua"},
    {"emoji": "🍵", "de": "der Tee", "en": "tea", "tr": "çay", "it": "il tè", "alt": {"it": ["il te", "il the"]}},
    {"emoji": "🧃", "de": "der Saft", "en": "juice", "tr": "meyve suyu", "it": "il succo", "alt": {"it": ["il succo di frutta"]}},
    {"emoji": "🧀", "de": "der Käse", "en": "cheese", "tr": "peynir", "it": "il formaggio"},
    {"emoji": "🥚", "de": "das Ei", "en": "egg", "tr": "yumurta", "it": "l'uovo"},
    {"emoji": "🍰", "de": "der Kuchen", "en": "cake", "tr": "pasta", "it": "la torta", "alt": {"it": ["il dolce"]}, "hinweise": {"tr": "„pasta“ heißt auf Türkisch Kuchen. Nudeln heißen „makarna“."}},
    {"emoji": "🍦", "de": "das Eis", "en": "ice cream", "tr": "dondurma", "it": "il gelato", "alt": {"en": ["ice-cream"]}},
    {"emoji": "🍲", "de": "die Suppe", "en": "soup", "tr": "çorba", "it": "la zuppa", "alt": {"it": ["la minestra"]}},
    {"emoji": "🥩", "de": "das Fleisch", "en": "meat", "tr": "et", "it": "la carne"},
    {"emoji": "🍯", "de": "der Honig", "en": "honey", "tr": "bal", "it": "il miele"},
    {"emoji": "🍫", "de": "die Schokolade", "en": "chocolate", "tr": "çikolata", "it": "il cioccolato", "alt": {"it": ["la cioccolata"]}},
    {"emoji": "🍕", "de": "die Pizza", "en": "pizza", "tr": "pizza", "it": "la pizza"}
   ]
  },
  {
   "id": "wildtiere", "titel": "Wilde Tiere", "emoji": "🦁", "stufe": 2,
   "woerter": [
    {"emoji": "🦁", "de": "der Löwe", "en": "lion", "tr": "aslan", "it": "il leone"},
    {"emoji": "🐘", "de": "der Elefant", "en": "elephant", "tr": "fil", "it": "l'elefante"},
    {"emoji": "🐵", "de": "der Affe", "en": "monkey", "tr": "maymun", "it": "la scimmia"},
    {"emoji": "🐻", "de": "der Bär", "en": "bear", "tr": "ayı", "it": "l'orso"},
    {"emoji": "🐺", "de": "der Wolf", "en": "wolf", "tr": "kurt", "it": "il lupo"},
    {"emoji": "🦊", "de": "der Fuchs", "en": "fox", "tr": "tilki", "it": "la volpe"},
    {"emoji": "🦒", "de": "die Giraffe", "en": "giraffe", "tr": "zürafa", "it": "la giraffa"},
    {"emoji": "🐯", "de": "der Tiger", "en": "tiger", "tr": "kaplan", "it": "la tigre"},
    {"emoji": "🐍", "de": "die Schlange", "en": "snake", "tr": "yılan", "it": "il serpente", "alt": {"it": ["la serpe"]}},
    {"emoji": "🐸", "de": "der Frosch", "en": "frog", "tr": "kurbağa", "it": "la rana"},
    {"emoji": "🦋", "de": "der Schmetterling", "en": "butterfly", "tr": "kelebek", "it": "la farfalla"},
    {"emoji": "🐝", "de": "die Biene", "en": "bee", "tr": "arı", "it": "l'ape"}
   ]
  },
  {
   "id": "zuhause", "titel": "Zuhause", "emoji": "🏠", "stufe": 2,
   "woerter": [
    {"emoji": "🏠", "de": "das Haus", "en": "house", "tr": "ev", "it": "la casa"},
    {"emoji": "🛋️", "de": "das Zimmer", "en": "room", "tr": "oda", "it": "la stanza", "alt": {"it": ["la camera"]}},
    {"emoji": "🚪", "de": "die Tür", "en": "door", "tr": "kapı", "it": "la porta"},
    {"emoji": "🪟", "de": "das Fenster", "en": "window", "tr": "pencere", "it": "la finestra"},
    {"emoji": "🍽️", "de": "der Tisch", "en": "table", "tr": "masa", "it": "il tavolo"},
    {"emoji": "🪑", "de": "der Stuhl", "en": "chair", "tr": "sandalye", "it": "la sedia"},
    {"emoji": "🛏️", "de": "das Bett", "en": "bed", "tr": "yatak", "it": "il letto"},
    {"emoji": "🍳", "de": "die Küche", "en": "kitchen", "tr": "mutfak", "it": "la cucina"},
    {"emoji": "🛁", "de": "das Bad", "en": "bathroom", "tr": "banyo", "it": "il bagno"},
    {"emoji": "🌳", "de": "der Garten", "en": "garden", "tr": "bahçe", "it": "il giardino"},
    {"emoji": "💡", "de": "die Lampe", "en": "lamp", "tr": "lamba", "it": "la lampada"},
    {"emoji": "🔑", "de": "der Schlüssel", "en": "key", "tr": "anahtar", "it": "la chiave"},
    {"emoji": "📺", "de": "der Fernseher", "en": "TV", "tr": "televizyon", "it": "la televisione", "alt": {"en": ["television"], "it": ["la tv", "il televisore"]}},
    {"emoji": "🕐", "de": "die Uhr", "en": "clock", "tr": "saat", "it": "l'orologio"}
   ]
  },
  {
   "id": "schule", "titel": "Schule", "emoji": "🏫", "stufe": 2,
   "woerter": [
    {"emoji": "🏫", "de": "die Schule", "en": "school", "tr": "okul", "it": "la scuola"},
    {"emoji": "👥", "de": "die Klasse", "en": "class", "tr": "sınıf", "it": "la classe"},
    {"emoji": "👩‍🏫", "de": "die Lehrerin", "en": "teacher", "tr": "öğretmen", "it": "la maestra", "alt": {"it": ["l'insegnante", "la professoressa"]}},
    {"emoji": "🧑‍🎓", "de": "der Schüler", "en": "pupil", "tr": "öğrenci", "it": "l'alunno", "alt": {"en": ["student"], "it": ["lo scolaro", "lo studente", "l'allievo"]}},
    {"emoji": "📖", "de": "das Buch", "en": "book", "tr": "kitap", "it": "il libro"},
    {"emoji": "📓", "de": "das Heft", "en": "exercise book", "tr": "defter", "it": "il quaderno", "alt": {"en": ["notebook"]}},
    {"emoji": "✏️", "de": "der Bleistift", "en": "pencil", "tr": "kurşun kalem", "it": "la matita"},
    {"emoji": "🧽", "de": "der Radiergummi", "en": "rubber", "tr": "silgi", "it": "la gomma", "alt": {"en": ["eraser"]}},
    {"emoji": "📏", "de": "das Lineal", "en": "ruler", "tr": "cetvel", "it": "il righello"},
    {"emoji": "✂️", "de": "die Schere", "en": "scissors", "tr": "makas", "it": "le forbici"},
    {"emoji": "🎒", "de": "die Schultasche", "en": "school bag", "tr": "okul çantası", "it": "lo zaino", "alt": {"en": ["schoolbag", "bag"], "tr": ["çanta"], "it": ["la cartella"]}},
    {"emoji": "📝", "de": "die Hausaufgaben", "en": "homework", "tr": "ödev", "it": "i compiti"},
    {"emoji": "🔔", "de": "die Pause", "en": "break", "tr": "teneffüs", "it": "l'intervallo", "alt": {"en": ["playtime"], "tr": ["ara"], "it": ["la pausa", "la ricreazione"]}},
    {"emoji": "➗", "de": "die Mathe", "en": "maths", "tr": "matematik", "it": "la matematica", "alt": {"en": ["math"]}}
   ]
  },
  {
   "id": "kleidung", "titel": "Kleidung", "emoji": "👕", "stufe": 2,
   "woerter": [
    {"emoji": "👕", "de": "das T-Shirt", "en": "t-shirt", "tr": "tişört", "it": "la maglietta", "alt": {"it": ["la t-shirt", "la maglia"]}},
    {"emoji": "👖", "de": "die Hose", "en": "trousers", "tr": "pantolon", "it": "i pantaloni", "alt": {"en": ["pants"]}},
    {"emoji": "👗", "de": "das Kleid", "en": "dress", "tr": "elbise", "it": "il vestito"},
    {"emoji": "👟", "de": "die Schuhe", "en": "shoes", "tr": "ayakkabı", "it": "le scarpe"},
    {"emoji": "🧦", "de": "die Socken", "en": "socks", "tr": "çorap", "it": "i calzini", "alt": {"it": ["le calze"]}},
    {"emoji": "🧢", "de": "die Mütze", "en": "hat", "tr": "şapka", "it": "il cappello", "alt": {"en": ["cap"], "tr": ["bere"], "it": ["il berretto", "il cappellino"]}},
    {"emoji": "🧥", "de": "die Jacke", "en": "jacket", "tr": "ceket", "it": "la giacca"},
    {"emoji": "🧶", "de": "der Pullover", "en": "jumper", "tr": "kazak", "it": "il maglione", "alt": {"en": ["sweater", "pullover"]}},
    {"emoji": "🧤", "de": "die Handschuhe", "en": "gloves", "tr": "eldiven", "it": "i guanti"},
    {"emoji": "🧣", "de": "der Schal", "en": "scarf", "tr": "atkı", "it": "la sciarpa"},
    {"emoji": "👓", "de": "die Brille", "en": "glasses", "tr": "gözlük", "it": "gli occhiali", "hinweise": {"it": "Mehrzahl: „gli“ steht vor Vokalen und „z“, sonst „i“."}}
   ]
  },
  {
   "id": "wetter", "titel": "Wetter & Natur", "emoji": "☀️", "stufe": 2,
   "woerter": [
    {"emoji": "☀️", "de": "die Sonne", "en": "sun", "tr": "güneş", "it": "il sole"},
    {"emoji": "🌙", "de": "der Mond", "en": "moon", "tr": "ay", "it": "la luna"},
    {"emoji": "⭐", "de": "der Stern", "en": "star", "tr": "yıldız", "it": "la stella"},
    {"emoji": "☁️", "de": "die Wolke", "en": "cloud", "tr": "bulut", "it": "la nuvola"},
    {"emoji": "🌧️", "de": "der Regen", "en": "rain", "tr": "yağmur", "it": "la pioggia"},
    {"emoji": "❄️", "de": "der Schnee", "en": "snow", "tr": "kar", "it": "la neve"},
    {"emoji": "💨", "de": "der Wind", "en": "wind", "tr": "rüzgâr", "it": "il vento", "alt": {"tr": ["rüzgar"]}},
    {"emoji": "🌸", "de": "die Blume", "en": "flower", "tr": "çiçek", "it": "il fiore"},
    {"emoji": "🌳", "de": "der Baum", "en": "tree", "tr": "ağaç", "it": "l'albero"},
    {"emoji": "🌊", "de": "das Meer", "en": "sea", "tr": "deniz", "it": "il mare"},
    {"emoji": "⛰️", "de": "der Berg", "en": "mountain", "tr": "dağ", "it": "la montagna", "alt": {"it": ["il monte"]}},
    {"emoji": "🌤️", "de": "der Himmel", "en": "sky", "tr": "gökyüzü", "it": "il cielo", "alt": {"tr": ["gök"]}},
    {"emoji": "🔥", "de": "das Feuer", "en": "fire", "tr": "ateş", "it": "il fuoco"}
   ]
  },
  {
   "id": "fahrzeuge", "titel": "Fahrzeuge", "emoji": "🚗", "stufe": 2,
   "woerter": [
    {"emoji": "🚗", "de": "das Auto", "en": "car", "tr": "araba", "it": "la macchina", "alt": {"tr": ["otomobil"], "it": ["l'auto", "l'automobile"]}},
    {"emoji": "🚌", "de": "der Bus", "en": "bus", "tr": "otobüs", "it": "l'autobus", "alt": {"it": ["il bus", "il pullman"]}},
    {"emoji": "🚆", "de": "der Zug", "en": "train", "tr": "tren", "it": "il treno"},
    {"emoji": "🚲", "de": "das Fahrrad", "en": "bike", "tr": "bisiklet", "it": "la bicicletta", "alt": {"en": ["bicycle"], "it": ["la bici"]}},
    {"emoji": "✈️", "de": "das Flugzeug", "en": "plane", "tr": "uçak", "it": "l'aereo", "alt": {"en": ["aeroplane", "airplane"], "it": ["l'aeroplano"]}},
    {"emoji": "🚢", "de": "das Schiff", "en": "ship", "tr": "gemi", "it": "la nave"},
    {"emoji": "⛵", "de": "das Boot", "en": "boat", "tr": "tekne", "it": "la barca"},
    {"emoji": "🚜", "de": "der Traktor", "en": "tractor", "tr": "traktör", "it": "il trattore"},
    {"emoji": "🚒", "de": "das Feuerwehrauto", "en": "fire engine", "tr": "itfaiye arabası", "it": "il camion dei pompieri", "alt": {"en": ["fire truck"], "it": ["l'autopompa"]}},
    {"emoji": "🚑", "de": "der Krankenwagen", "en": "ambulance", "tr": "ambulans", "it": "l'ambulanza"},
    {"emoji": "🏍️", "de": "das Motorrad", "en": "motorbike", "tr": "motosiklet", "it": "la moto", "alt": {"en": ["motorcycle"], "it": ["la motocicletta"]}},
    {"emoji": "🚁", "de": "der Hubschrauber", "en": "helicopter", "tr": "helikopter", "it": "l'elicottero"}
   ]
  },
  {
   "id": "stadt", "titel": "Stadt & Orte", "emoji": "🏙️", "stufe": 2,
   "woerter": [
    {"emoji": "🏙️", "de": "die Stadt", "en": "city", "tr": "şehir", "it": "la città", "alt": {"tr": ["kent"]}},
    {"emoji": "🏘️", "de": "das Dorf", "en": "village", "tr": "köy", "it": "il paese", "alt": {"it": ["il villaggio"]}},
    {"emoji": "🛣️", "de": "die Straße", "en": "street", "tr": "sokak", "it": "la strada", "alt": {"en": ["road"], "tr": ["yol"], "it": ["la via"]}},
    {"emoji": "🏞️", "de": "der Park", "en": "park", "tr": "park", "it": "il parco"},
    {"emoji": "🛝", "de": "der Spielplatz", "en": "playground", "tr": "oyun parkı", "it": "il parco giochi", "alt": {"it": ["il campo giochi", "l'area giochi"]}},
    {"emoji": "🛒", "de": "der Supermarkt", "en": "supermarket", "tr": "süpermarket", "it": "il supermercato", "alt": {"tr": ["market"]}},
    {"emoji": "🥖", "de": "die Bäckerei", "en": "bakery", "tr": "fırın", "it": "la panetteria", "alt": {"tr": ["ekmek fırını"], "it": ["il panificio", "il forno"]}},
    {"emoji": "🏥", "de": "das Krankenhaus", "en": "hospital", "tr": "hastane", "it": "l'ospedale"},
    {"emoji": "🚉", "de": "der Bahnhof", "en": "station", "tr": "istasyon", "it": "la stazione", "alt": {"en": ["train station", "railway station"], "tr": ["gar"]}},
    {"emoji": "🎬", "de": "das Kino", "en": "cinema", "tr": "sinema", "it": "il cinema"},
    {"emoji": "🌉", "de": "die Brücke", "en": "bridge", "tr": "köprü", "it": "il ponte"},
    {"emoji": "🏛️", "de": "das Museum", "en": "museum", "tr": "müze", "it": "il museo"}
   ]
  },
  {
   "id": "freizeit", "titel": "Spielen & Freizeit", "emoji": "🎮", "stufe": 2,
   "woerter": [
    {"emoji": "🧸", "de": "das Spielzeug", "en": "toy", "tr": "oyuncak", "it": "il giocattolo"},
    {"emoji": "🏐", "de": "der Ball", "en": "ball", "tr": "top", "it": "la palla", "alt": {"it": ["il pallone"]}},
    {"emoji": "⚽", "de": "der Fußball", "en": "football", "tr": "futbol", "it": "il calcio", "alt": {"en": ["soccer"], "it": ["il pallone", "il football"]}},
    {"emoji": "🪆", "de": "die Puppe", "en": "doll", "tr": "oyuncak bebek", "it": "la bambola"},
    {"emoji": "🧩", "de": "das Puzzle", "en": "puzzle", "tr": "yapboz", "it": "il puzzle", "alt": {"tr": ["puzzle"], "it": ["il rompicapo"]}},
    {"emoji": "🎮", "de": "das Spiel", "en": "game", "tr": "oyun", "it": "il gioco"},
    {"emoji": "♟️", "de": "das Schach", "en": "chess", "tr": "satranç", "it": "gli scacchi"},
    {"emoji": "🪁", "de": "der Drachen (zum Fliegen)", "en": "kite", "tr": "uçurtma", "it": "l'aquilone"},
    {"emoji": "🎵", "de": "die Musik", "en": "music", "tr": "müzik", "it": "la musica"},
    {"emoji": "🎸", "de": "die Gitarre", "en": "guitar", "tr": "gitar", "it": "la chitarra"},
    {"emoji": "📱", "de": "das Handy", "en": "mobile phone", "tr": "cep telefonu", "it": "il cellulare", "alt": {"en": ["phone", "mobile", "cell phone"], "tr": ["telefon"], "it": ["il telefonino", "il telefono", "lo smartphone"]}},
    {"emoji": "💻", "de": "der Computer", "en": "computer", "tr": "bilgisayar", "it": "il computer", "alt": {"it": ["il pc"]}},
    {"emoji": "📷", "de": "die Kamera", "en": "camera", "tr": "kamera", "it": "la fotocamera", "alt": {"it": ["la macchina fotografica", "la telecamera"]}},
    {"emoji": "🖼️", "de": "das Bild", "en": "picture", "tr": "resim", "it": "l'immagine", "alt": {"it": ["il quadro", "la foto", "il disegno"]}}
   ]
  },
  {
   "id": "wochentage", "titel": "Wochentage", "emoji": "📅", "stufe": 2, "bilder": false,
   "woerter": [
    {"de": "Montag", "en": "Monday", "tr": "Pazartesi", "it": "lunedì", "alt": {"it": ["lunedi"]}, "hinweise": {"it": "Die Wochentage schreibt man im Italienischen klein."}},
    {"de": "Dienstag", "en": "Tuesday", "tr": "Salı", "it": "martedì", "alt": {"it": ["martedi"]}},
    {"de": "Mittwoch", "en": "Wednesday", "tr": "Çarşamba", "it": "mercoledì", "alt": {"it": ["mercoledi"]}},
    {"de": "Donnerstag", "en": "Thursday", "tr": "Perşembe", "it": "giovedì", "alt": {"it": ["giovedi"]}},
    {"de": "Freitag", "en": "Friday", "tr": "Cuma", "it": "venerdì", "alt": {"it": ["venerdi"]}},
    {"de": "Samstag", "en": "Saturday", "tr": "Cumartesi", "it": "sabato"},
    {"de": "Sonntag", "en": "Sunday", "tr": "Pazar", "it": "domenica"}
   ]
  },
  {
   "id": "zahl20", "titel": "Zahlen 11 bis 20", "emoji": "🔢", "stufe": 2,
   "woerter": [
    {"emoji": "11", "de": "elf", "en": "eleven", "tr": "on bir", "it": "undici"},
    {"emoji": "12", "de": "zwölf", "en": "twelve", "tr": "on iki", "it": "dodici"},
    {"emoji": "13", "de": "dreizehn", "en": "thirteen", "tr": "on üç", "it": "tredici"},
    {"emoji": "14", "de": "vierzehn", "en": "fourteen", "tr": "on dört", "it": "quattordici"},
    {"emoji": "15", "de": "fünfzehn", "en": "fifteen", "tr": "on beş", "it": "quindici"},
    {"emoji": "16", "de": "sechzehn", "en": "sixteen", "tr": "on altı", "it": "sedici"},
    {"emoji": "17", "de": "siebzehn", "en": "seventeen", "tr": "on yedi", "it": "diciassette"},
    {"emoji": "18", "de": "achtzehn", "en": "eighteen", "tr": "on sekiz", "it": "diciotto"},
    {"emoji": "19", "de": "neunzehn", "en": "nineteen", "tr": "on dokuz", "it": "diciannove"},
    {"emoji": "20", "de": "zwanzig", "en": "twenty", "tr": "yirmi", "it": "venti"}
   ]
  },
  {
   "id": "monate", "titel": "Monate", "emoji": "🗓️", "stufe": 3, "bilder": false,
   "woerter": [
    {"de": "Januar", "en": "January", "tr": "Ocak", "it": "gennaio"},
    {"de": "Februar", "en": "February", "tr": "Şubat", "it": "febbraio"},
    {"de": "März", "en": "March", "tr": "Mart", "it": "marzo"},
    {"de": "April", "en": "April", "tr": "Nisan", "it": "aprile"},
    {"de": "Mai", "en": "May", "tr": "Mayıs", "it": "maggio"},
    {"de": "Juni", "en": "June", "tr": "Haziran", "it": "giugno"},
    {"de": "Juli", "en": "July", "tr": "Temmuz", "it": "luglio"},
    {"de": "August", "en": "August", "tr": "Ağustos", "it": "agosto"},
    {"de": "September", "en": "September", "tr": "Eylül", "it": "settembre"},
    {"de": "Oktober", "en": "October", "tr": "Ekim", "it": "ottobre"},
    {"de": "November", "en": "November", "tr": "Kasım", "it": "novembre"},
    {"de": "Dezember", "en": "December", "tr": "Aralık", "it": "dicembre"}
   ]
  },
  {
   "id": "zeit", "titel": "Jahreszeiten & Zeit", "emoji": "🌷", "stufe": 3,
   "woerter": [
    {"emoji": "🌷", "de": "der Frühling", "en": "spring", "tr": "ilkbahar", "it": "la primavera", "alt": {"tr": ["bahar"]}},
    {"emoji": "🏖️", "de": "der Sommer", "en": "summer", "tr": "yaz", "it": "l'estate", "hinweise": {"it": "„l'estate“ ist weiblich: die Sommerzeit."}},
    {"emoji": "🍂", "de": "der Herbst", "en": "autumn", "tr": "sonbahar", "it": "l'autunno", "alt": {"en": ["fall"]}},
    {"emoji": "☃️", "de": "der Winter", "en": "winter", "tr": "kış", "it": "l'inverno"},
    {"de": "heute", "en": "today", "tr": "bugün", "it": "oggi"},
    {"de": "gestern", "en": "yesterday", "tr": "dün", "it": "ieri"},
    {"de": "morgen (der nächste Tag)", "en": "tomorrow", "tr": "yarın", "it": "domani"},
    {"emoji": "🌅", "de": "der Morgen (früh)", "en": "morning", "tr": "sabah", "it": "la mattina", "alt": {"it": ["il mattino"]}},
    {"emoji": "🌇", "de": "der Abend", "en": "evening", "tr": "akşam", "it": "la sera", "alt": {"it": ["la serata"]}},
    {"emoji": "🌙", "de": "die Nacht", "en": "night", "tr": "gece", "it": "la notte"},
    {"emoji": "📆", "de": "die Woche", "en": "week", "tr": "hafta", "it": "la settimana"},
    {"emoji": "🎆", "de": "das Jahr", "en": "year", "tr": "yıl", "it": "l'anno"},
    {"emoji": "🌞", "de": "der Tag", "en": "day", "tr": "gün", "it": "il giorno"}
   ]
  },
  {
   "id": "taetigkeiten", "titel": "Tätigkeiten", "emoji": "🏃", "stufe": 3,
   "woerter": [
    {"emoji": "🏃", "de": "laufen", "en": "run", "tr": "koşmak", "it": "correre"},
    {"emoji": "🏊", "de": "schwimmen", "en": "swim", "tr": "yüzmek", "it": "nuotare"},
    {"emoji": "🦘", "de": "springen", "en": "jump", "tr": "zıplamak", "it": "saltare"},
    {"emoji": "🍽️", "de": "essen", "en": "eat", "tr": "yemek", "it": "mangiare"},
    {"emoji": "🥤", "de": "trinken", "en": "drink", "tr": "içmek", "it": "bere"},
    {"emoji": "😴", "de": "schlafen", "en": "sleep", "tr": "uyumak", "it": "dormire"},
    {"emoji": "🎮", "de": "spielen", "en": "play", "tr": "oynamak", "it": "giocare"},
    {"emoji": "📖", "de": "lesen", "en": "read", "tr": "okumak", "it": "leggere"},
    {"emoji": "✍️", "de": "schreiben", "en": "write", "tr": "yazmak", "it": "scrivere"},
    {"emoji": "🎤", "de": "singen", "en": "sing", "tr": "şarkı söylemek", "it": "cantare"},
    {"emoji": "💃", "de": "tanzen", "en": "dance", "tr": "dans etmek", "it": "ballare"},
    {"emoji": "😂", "de": "lachen", "en": "laugh", "tr": "gülmek", "it": "ridere"},
    {"emoji": "😢", "de": "weinen", "en": "cry", "tr": "ağlamak", "it": "piangere"},
    {"emoji": "🤝", "de": "helfen", "en": "help", "tr": "yardım etmek", "it": "aiutare"}
   ]
  },
  {
   "id": "gegenteile", "titel": "Gegenteile", "emoji": "↔️", "stufe": 3,
   "woerter": [
    {"emoji": "🐘", "de": "groß", "en": "big", "tr": "büyük", "it": "grande"},
    {"emoji": "🐜", "de": "klein", "en": "small", "tr": "küçük", "it": "piccolo"},
    {"emoji": "🥵", "de": "heiß", "en": "hot", "tr": "sıcak", "it": "caldo"},
    {"emoji": "🥶", "de": "kalt", "en": "cold", "tr": "soğuk", "it": "freddo"},
    {"emoji": "🐇", "de": "schnell", "en": "fast", "tr": "hızlı", "it": "veloce", "alt": {"it": ["rapido"]}},
    {"emoji": "🐢", "de": "langsam", "en": "slow", "tr": "yavaş", "it": "lento"},
    {"emoji": "🆕", "de": "neu", "en": "new", "tr": "yeni", "it": "nuovo"},
    {"emoji": "🕰️", "de": "alt", "en": "old", "tr": "eski", "it": "vecchio", "hinweise": {"tr": "„eski“ sagt man bei Dingen. Bei Menschen heißt alt „yaşlı“."}},
    {"emoji": "👍", "de": "gut", "en": "good", "tr": "iyi", "it": "buono", "alt": {"it": ["bravo"]}},
    {"emoji": "👎", "de": "schlecht", "en": "bad", "tr": "kötü", "it": "cattivo", "alt": {"it": ["brutto"]}},
    {"emoji": "😊", "de": "glücklich", "en": "happy", "tr": "mutlu", "it": "felice", "alt": {"it": ["contento", "allegro"]}},
    {"emoji": "😔", "de": "traurig", "en": "sad", "tr": "üzgün", "it": "triste"},
    {"emoji": "🤫", "de": "leise", "en": "quiet", "tr": "sessiz", "it": "silenzioso", "alt": {"it": ["tranquillo"]}},
    {"emoji": "🌺", "de": "schön", "en": "beautiful", "tr": "güzel", "it": "bello", "alt": {"en": ["pretty", "nice"], "it": ["bella", "carino"]}}
   ]
  },
  {
   "id": "zehner", "titel": "Zehnerzahlen bis 100", "emoji": "💯", "stufe": 3,
   "woerter": [
    {"emoji": "30", "de": "dreißig", "en": "thirty", "tr": "otuz", "it": "trenta"},
    {"emoji": "40", "de": "vierzig", "en": "forty", "tr": "kırk", "it": "quaranta"},
    {"emoji": "50", "de": "fünfzig", "en": "fifty", "tr": "elli", "it": "cinquanta"},
    {"emoji": "60", "de": "sechzig", "en": "sixty", "tr": "altmış", "it": "sessanta"},
    {"emoji": "70", "de": "siebzig", "en": "seventy", "tr": "yetmiş", "it": "settanta"},
    {"emoji": "80", "de": "achtzig", "en": "eighty", "tr": "seksen", "it": "ottanta"},
    {"emoji": "90", "de": "neunzig", "en": "ninety", "tr": "doksan", "it": "novanta"},
    {"emoji": "100", "de": "hundert", "en": "hundred", "tr": "yüz", "it": "cento"}
   ]
  },
  {
   "id": "saetze", "titel": "Kleine Sätze", "emoji": "💬", "stufe": 3, "bilder": false, "typ": "saetze",
   "woerter": [
    {"emoji": "🌅", "de": "Guten Morgen!", "en": "Good morning!", "tr": "Günaydın!", "it": "Buongiorno!", "alt": {"it": ["Buon giorno!"]}},
    {"emoji": "🌇", "de": "Guten Abend!", "en": "Good evening!", "tr": "İyi akşamlar!", "it": "Buonasera!", "alt": {"it": ["Buona sera!"]}},
    {"emoji": "🌙", "de": "Gute Nacht!", "en": "Good night!", "tr": "İyi geceler!", "it": "Buonanotte!", "alt": {"it": ["Buona notte!"]}},
    {"emoji": "🙂", "de": "Wie geht es dir?", "en": "How are you?", "tr": "Nasılsın?", "it": "Come stai?", "alt": {"it": ["Come va?"]}},
    {"emoji": "😊", "de": "Mir geht es gut.", "en": "I am fine.", "tr": "İyiyim.", "it": "Sto bene.", "alt": {"en": ["I'm fine.", "I am good.", "I'm good."], "it": ["Io sto bene."]}},
    {"emoji": "❓", "de": "Wie heißt du?", "en": "What is your name?", "tr": "Adın ne?", "it": "Come ti chiami?", "alt": {"en": ["What's your name?"], "tr": ["Senin adın ne?", "Adın nedir?"]}},
    {"emoji": "🙋", "de": "Ich heiße Ali.", "en": "My name is Ali.", "tr": "Benim adım Ali.", "it": "Mi chiamo Ali.", "alt": {"tr": ["Adım Ali."], "it": ["Il mio nome è Ali."]}},
    {"emoji": "🎂", "de": "Wie alt bist du?", "en": "How old are you?", "tr": "Kaç yaşındasın?", "it": "Quanti anni hai?"},
    {"emoji": "🔢", "de": "Ich bin acht Jahre alt.", "en": "I am eight years old.", "tr": "Ben sekiz yaşındayım.", "it": "Ho otto anni.", "alt": {"en": ["I'm eight years old.", "I'm eight.", "I am eight."], "tr": ["Sekiz yaşındayım."], "it": ["Io ho otto anni."]}, "hinweise": {"it": "Im Italienischen sagt man „ich habe acht Jahre“."}},
    {"emoji": "🍽️", "de": "Ich habe Hunger.", "en": "I am hungry.", "tr": "Acıktım.", "it": "Ho fame.", "alt": {"en": ["I'm hungry."], "tr": ["Karnım aç."], "it": ["Io ho fame."]}},
    {"emoji": "🥤", "de": "Ich habe Durst.", "en": "I am thirsty.", "tr": "Susadım.", "it": "Ho sete.", "alt": {"en": ["I'm thirsty."], "it": ["Io ho sete."]}},
    {"emoji": "❤️", "de": "Ich liebe dich.", "en": "I love you.", "tr": "Seni seviyorum.", "it": "Ti amo.", "alt": {"it": ["Ti voglio bene."]}},
    {"emoji": "🤷", "de": "Ich verstehe das nicht.", "en": "I do not understand.", "tr": "Anlamıyorum.", "it": "Non capisco.", "alt": {"en": ["I don't understand.", "I do not understand that.", "I don't understand that."], "tr": ["Bunu anlamıyorum."], "it": ["Non lo capisco.", "Non ho capito."]}},
    {"emoji": "🆘", "de": "Kannst du mir helfen?", "en": "Can you help me?", "tr": "Bana yardım edebilir misin?", "it": "Puoi aiutarmi?", "alt": {"it": ["Mi puoi aiutare?", "Puoi darmi una mano?"]}},
    {"emoji": "🚻", "de": "Wo ist die Toilette?", "en": "Where is the toilet?", "tr": "Tuvalet nerede?", "it": "Dov'è il bagno?", "alt": {"it": ["Dove è il bagno?", "Dov'è la toilette?", "Dove è la toilette?"]}},
    {"emoji": "🧑‍🤝‍🧑", "de": "Das ist mein Freund.", "en": "This is my friend.", "tr": "Bu benim arkadaşım.", "it": "Questo è il mio amico.", "alt": {"it": ["Lui è il mio amico."]}},
    {"emoji": "🍕", "de": "Ich mag Pizza.", "en": "I like pizza.", "tr": "Pizzayı severim.", "it": "Mi piace la pizza.", "alt": {"tr": ["Pizza severim."], "it": ["Mi piace pizza."]}, "hinweise": {"it": "„Mi piace“ heißt wörtlich: „sie gefällt mir“."}},
    {"emoji": "⚽", "de": "Ich spiele Fußball.", "en": "I play football.", "tr": "Futbol oynuyorum.", "it": "Gioco a calcio.", "alt": {"en": ["I play soccer."], "it": ["Io gioco a calcio.", "Gioco a pallone."]}},
    {"emoji": "🔍", "de": "Was ist das?", "en": "What is this?", "tr": "Bu nedir?", "it": "Che cos'è?", "alt": {"en": ["What is that?", "What's this?"], "tr": ["Bu ne?"], "it": ["Che cos'è questo?", "Cos'è?", "Cos'è questo?", "Che cosa è?"]}},
    {"emoji": "🥵", "de": "Heute ist es heiß.", "en": "It is hot today.", "tr": "Bugün hava sıcak.", "it": "Oggi fa caldo.", "alt": {"en": ["It's hot today."], "it": ["Oggi è caldo."]}},
    {"emoji": "👋", "de": "Bis morgen!", "en": "See you tomorrow!", "tr": "Yarın görüşürüz!", "it": "A domani!", "alt": {"it": ["Ci vediamo domani!"]}},
    {"emoji": "😊", "de": "Gern geschehen!", "en": "You are welcome!", "tr": "Rica ederim!", "it": "Prego!", "alt": {"en": ["You're welcome!", "No problem!"], "it": ["Di niente!", "Figurati!"]}, "hinweise": {"it": "„prego“ heißt „bitte sehr“ und „gern geschehen“."}},
    {"emoji": "🍀", "de": "Viel Glück!", "en": "Good luck!", "tr": "Bol şans!", "it": "Buona fortuna!", "alt": {"tr": ["İyi şanslar!"], "it": ["In bocca al lupo!"]}},
    {"emoji": "🎉", "de": "Herzlichen Glückwunsch!", "en": "Congratulations!", "tr": "Tebrikler!", "it": "Congratulazioni!", "alt": {"it": ["Complimenti!", "Auguri!"]}},
    {"emoji": "🎈", "de": "Alles Gute zum Geburtstag!", "en": "Happy birthday!", "tr": "Doğum günün kutlu olsun!", "it": "Buon compleanno!", "alt": {"tr": ["İyi ki doğdun!"], "it": ["Tanti auguri!", "Auguri di buon compleanno!"]}}
   ]
  }
 ]
}
"""#
}
