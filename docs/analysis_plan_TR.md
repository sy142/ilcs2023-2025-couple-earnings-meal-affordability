# Eşler arasında kazancın dağılımı ve hanenin gıdayı karşılayabilmesi: Analiz Talimatı

> Arşiv sürümü (v1.0.0): dergi adı, önceki çalışmaların ve klasörlerin adları ile kullanıcı yolları köşeli parantez içinde çıkarıldı ya da `~/` ile kısaltıldı ve çalışma ortamına ilişkin iki cümle sadeleştirildi; analiz içeriğinde değişiklik yapılmadı.

Sürüm 1, 28 Ekim 2026. Bu belge analizi yürütecek analiste yazılmıştır. Makaleyi biz yazacağız; senden istenen, aşağıdaki analizlerin tamamını bitirmiş, dosyalanmış, yeniden üretilebilir ve raporlanmış olarak teslim etmendir.

Okuma sırası:

1. Bu belgenin tamamı.
2. Proje kökündeki `GYKA_2023_2025_tarif.docx` ve `GYKA_2023_2025_inceleme_raporu.docx`. Kökte yoksa `../[önceki çalışma 1]/` klasöründen kopyala.
3. Birinci çalışmanın talimatı ve raporu: `../[önceki çalışma 1]/docs/analysis_plan_TR.md`, `../[önceki çalışma 1]/Rapor.md` ve `../[önceki çalışma 1]/Codes/README_kodlar.md`. Klasör düzeni, rapor biçimi, tablo kurucu ve figür stili için örnek olarak oku. Bu çalışmanın sonuçlarını oradan taşıma.

Sorularını ve kararlarını `Rapor.md` içinde tut. Bizden cevap beklemeden ilerleyebileceğin her yerde varsayılan kararı uygula ve kaydet.

---

## 0. Çalışmanın özü

**Soru.** Çiftin toplam çalışma kazancı, hanenin diğer gelirleri ve hane bileşimi benzerken, kazancın eşler arasında nasıl bölündüğü hanenin gıdayı karşılayabilmesiyle ilişkili mi?

Çalışma birbirine karışan iki boyutu ayırır:

- **Pay:** iki kazançlı çiftlerde kadının çift kazancındaki payı (0 ile 1 arasında sürekli).
- **Kazanan yapısı:** çift içinde yalnız erkeğin, iki eşin ya da yalnız kadının pozitif net çalışma kazancı olması.

Yalnız erkeğin kazandığı çiftlerde pay her zaman 0, yalnız kadının kazandığı çiftlerde her zaman 1'dir. Bu yüzden pay eğrisi yalnız iki kazançlı çiftlerde tanımlanır. Tek kazanan durumları eğrinin uzantısı değil, ayrı köşelerdir.

**Araştırma soruları.** Yönlü hipotez yoktur; aşağıdakiler araştırılacak olasılıklardır, beklenen sonuçlar değil.

- RQ1. İki kazançlı çiftlerde kazancın bir eşte yoğunlaşması gıda yoksunluğuyla ilişkili mi?
- RQ2. Aynı yoğunlaşma düzeyinde, kazancın büyük kısmını hangi eşin elde ettiği fark yaratıyor mu?
- RQ3. Çiftin tek kazananı olmak, kazancın büyük kısmını elde etmekle aynı anlama mı geliyor?
- İkincil. Yalnız kadının kazandığı çiftlerde örüntü, kocanın gelir yılındaki durumuna göre farklılaşıyor mu?

Literatürde iki çizgi var: kaynağın kimin elinde olduğunun harcamayı etkilediğini gösteren iç-hane kaynak paylaşımı çalışmaları ve tek kadın kazananlı çiftlerin ekonomik durumunu inceleyen çalışmalar. Bunlar birbirini dışlayan iki hipotez değildir; sonuçları ikisinden birini doğrulama diye yorumlama.

**Veri.** TÜİK Gelir ve Yaşam Koşulları Araştırması (GYKA) 2023, 2024 ve 2025 kesit mikro verileri; birleşik dosya `GYKA_2023_2025_birlesik.xlsx` (239.985 fert satırı, 266 sütun).

**Sonuç değişkeni.** HE090 = 2: hane, iki günde bir et, tavuk, balık ya da vejetaryen eşdeğerini içeren yemeği karşılayamıyor. Tek maddelik bir öğün karşılanabilirliği yoksunluğudur ("food deprivation"); FIES gibi bir gıda güvencesizliği ölçeği değildir ve raporda da böyle adlandırılır. Hane anketini kimin yanıtladığı veride yoktur.

**Önceki çalışmalarla ilişki.** Aynı veriyle iki çalışma yapıldı: [önceki çalışma 1] (gelir yoksulluğu eşiğinin gıda yoksunluğunu kaçırması) ve [önceki çalışma 2] (gıda karşılanabilirliği ve sağlık harcaması yükü). Bu çalışmanın sorusu, analiz birimi ve maruziyeti farklıdır. Önceki sonuçları kullanma; yalnız kod parçalarını yeniden kullanabilirsin (Bölüm 1).

**Hedef dergi.** [Hedef dergi bilgisi arşiv sürümünde çıkarılmıştır.] Araştırma makalesi. Ana metinde 2 tablo ve 3 figür; geri kalan her şey Supplementary Material'a gider.

**Senin ürünün.**

- Kodlar.
- Veri setleri.
- Sonuç tabloları (docx, csv, xlsx).
- Figürler (PNG, PDF, TIFF).
- `sayilar.json`.
- `Rapor.md` ve `README_kodlar.md`.
- İngilizce altyazı ve tablo notu taslakları.
- `Rapor.md` içinde İngilizce Methods notları.

Makale metnini yazma.

---

## 1. Klasör yapısı ve dosya kuralları

Proje kökü: `[proje kökü]/`. Bütün komutlar kökten çalıştırılır; göreli yollar köke göredir.

```
[proje kökü]/
  Article.docx                      (dergi şablonu; dokunma)
  analysis_plan_TR.md               (bu belge)
  GYKA_2023_2025_tarif.docx         ([önceki çalışma 1]'den kopya)
  GYKA_2023_2025_inceleme_raporu.docx
  Rapor.md                          (sen yazacaksın)
  Codes/
    README_kodlar.md
    analiz.R                        (tek giriş noktası)
    figurler.py, figur_stili.py, etiketler.json
    xlsx_simge.py                   ([önceki çalışma 1]'den kopyalanabilir)
  Figures/                          (Figure1–3: png/pdf/tiff; figur_altyazilari.md)
  Figures/Supplementary/
  R_Data ve Python Data/            (parquet, rds, csv; yalnız burada kişi ve hane düzeyi veri)
  R_Data ve Python Data/onbellek/   (Stan modelleri, posterior çekilişleri, bootstrap)
  R_Data ve Python Data/figur_verileri/
  Results/                          (Table1–2 docx/csv, tablolar_tumu.xlsx, sayilar.json, ...)
  Results/Supplementary/
  Results/denetim/                  (Aşama 0 ve tanı çıktıları; yayın öğesi değil)
  Results/log/
  docs/                             (bu belgenin arşiv kopyası, CHANGELOG.md)
```

**Ham veri.**

- Kaynak: `../[önceki çalışma 1]/GYKA_2023_2025_birlesik.xlsx`. Tarif belgesi Bölüm 1.4'teki Okuma 1 ile (`col_types = sozluk$okuma_turu`) bir kez okunur.
- `R_Data ve Python Data/gyka_2023_2025.parquet` ve `.rds` yazılır; `sozluk`, `kodlar` ve `dogrulama` sayfaları CSV olarak aynı klasöre gider.
- `../[önceki çalışma 1]/R_Data ve Python Data/gyka_2023_2025.parquet` varsa, ikisinin aynı olduğunu satır, sütun ve değer düzeyinde denetle ve sonucu raporla.
- Okuma yaklaşık 19 GB tepe bellek ister; makinede 64 GB var.

**Yeniden kullanım.** Şunları `../[önceki çalışma 1]/Codes/` altından alabilirsin:

- `figur_stili.py` ve `xlsx_simge.py`.
- `analiz.R` içindeki `tablo_cikar` (flextable + xlsx tablo kurucu).
- `analiz.R` içindeki imza eşleştirme parçaları.

Kopyaladığın her parçayı `Rapor.md`'de belirt ve bu çalışmaya göre denetle.

**Tek komutla üretim.**

- `Rscript Codes/analiz.R` sırasıyla şunları üretir:
  - veri hazırlığı;
  - bağlantı zincirleri;
  - fizibilite denetimi;
  - ortak destek;
  - modeller;
  - standartlaştırma;
  - duyarlılık analizleri;
  - tablolar, figür verileri ve `sayilar.json`.
- Ardından `~/veri-ortami/bin/python3 Codes/figurler.py` bütün figürleri `figur_verileri/*.csv` dosyalarından çizer. Figür kodu veri hesaplamaz.
- Uzun hesaplar önbelleklenir; dosya varsa yeniden hesaplanmaz.

**Veri güvenliği.**

- Mikro veri ve hane düzeyindeki ara dosyalar yalnız `R_Data ve Python Data/` altında durur. `Results/` ve `Figures/` yalnız toplulaştırılmış çıktı içerir.
- Ağırlıksız n < 20 olan hücrelerde tahmin verilmez; 20–50 arası hücreler işaretlenir (tarif Bölüm 2.4). Bu kural figürler için de geçerlidir.
- Mikro veri 5429 sayılı Kanun gereği hiçbir çevrim içi hizmete yüklenmez.

---

## 2. Çalışma kuralları (kalıcı tercihlerimiz)

### Kod

- Veri düzenleme, Bayesçi modeller, standartlaştırma ve tablolar R'de; figürler Python'da (matplotlib).
  - Python yorumlayıcısı: `~/veri-ortami/bin/python3`.
  - Bir figür R'de daha iyi olacaksa R kullanabilirsin; gerekçesini raporla.
- Önce veri düzenleme, ardından analiz gelir; hepsi `analiz.R` içinde ilerler. Her parça kaldığı yerden devam eder; önceki parçalardaki nesneler ve paketler tekrar kurulmaz.
- Kod bir yıl sonra açıldığında baştan sona hatasız ve aynı sonuçlarla çalışmalı. Tohumlar sabittir ve `README_kodlar.md`'de yazılıdır.
- R kodunda:
  - `#` ile açıklama ya da bölüm başlığı satırı yazma. `# ====`, `# ----` gibi ASCII süslemeler yok.
  - Gereken her karakter (Türkiye, ≥, –, ±, ı, ş, ğ) doğrudan karakter olarak yazılır, `±` gibi kaçış kodlarıyla değil; dosyalar UTF-8.
  - Bu kural birinci çalışmadaki "R'de Türkçe karakter kullanma, kaçış kodu yaz" kuralının yerine geçer.
  - Değişken adları ASCII ve küçük harfli kalabilir.
- Python'da ASCII kuralı geçerli değildir; kod yine açıklama satırlarından arındırılmış ve sade olsun.
- Paket atıfları uydurulmaz. `citation("paket")` çıktıları `Results/paket_atiflari.txt`'e yazılır. Önemli olanlar analizde doğrudan rol oynayan paketlerdir: model kuran, test yapan, tahmin üreten paketler (brms, cmdstanr ve Stan, survey, splines, statmod, nnet, posterior). Yardımcı paketleri de listele, rollerini ayrı yaz. Python kütüphaneleri için README'lerinin önerdiği atıflar aynı dosyaya girer.

### Donanım

- Mac: 64 GB bellek, 18 çekirdek CPU, 40 çekirdek GPU.
- CPU'da en çok 16 iş parçacığı: Stan'de 4 zincir × 4 iş parçacığı (`threads = threading(4)`, `reduce_sum`); R'de `future::plan(multisession, workers = 16)`, işçilerde `VECLIB_MAXIMUM_THREADS = 1`.
- GPU: uzun koşularda mümkünse GPU kullanılmasını isteriz. Stan'de GPU desteği yalnız OpenCL üzerinden ve sınırlıdır. Pilotta brms `opencl()` seçeneğini dene:
  - Çalışıyor ve hızlıysa kullan.
  - Çalışmıyorsa CPU'da devam et.
  - Denemenin sonucunu ve her adımın nerede, kaç dakikada koştuğunu `Rapor.md` Bölüm 13'e yaz.

### Ağırlık ve tasarım

- Analiz birimi hanedir: her hane-yılı bir satır, ağırlık HB040.
  - 2023 dosyasında HB040, belgede yazanın aksine FB030'a eşittir. TÜİK'in ortalama hane gelirini HB040 verdiği için hane düzeyinde yine HB040 kullanılır (tarif Bölüm 1.4).
- **Model ağırlığı ve hedef ağırlığı aynıdır.** HB040, bütün havuzlanmış analiz örnekleminde örneklem büyüklüğüne normalize edilir: w̃ = n · HB040 / ΣHB040.
  - Böylece yılların hedef dağılımdaki payı q_t = W_t / ΣW_t olur; yıllar temsil ettikleri hane nüfuslarıyla katkı verir.
  - Ağırlıklar zincir uzunluğuna bölünmez. Üç yılda görülen bir hane, üç hane-yılı katkısı verir.
- Tabaka ve birincil örnekleme birimi değişkenleri veride yoktur. Belirsizlik bu nedenle eksik tahmin edilmiş olabilir; bu durum sınırlılık olarak raporlanır.
- Gelirler yıl içi göreli ölçeğe çevrilir (Bölüm 3.4). Nominal TL yıllar arasında karşılaştırılmaz.
- Tablolarda n ağırlıksız, yüzdeler ağırlıklıdır; bu durum tablo notunda yazar.

### Dil ve çıktı biçimi

- Rapor ve karar defteri Türkçe.
- Figür içindeki bütün yazılar, tablo başlıkları, sütun adları, notlar ve altyazılar Amerikan İngilizcesi (standardized, equivalized, analyzed, color).
  - Ortak metinler `Codes/etiketler.json`'da tek yerden tanımlanır; R tabloları da aynı dosyayı okur.
- Nedensel dil yok: "association", "difference", "probability", "conditional on". "Effect", "impact", "because of" yok.
- Terimler:
  - Sonuç değişkeni: "food deprivation" ya da "inability to afford a meal with meat, chicken or fish every second day".
  - Kazanan yapısı: "only the husband has positive net labor earnings" gibi tam tanımlı etiketler. Kısaltmalar: "husband-only earner", "dual-earner", "wife-only earner".
  - "Breadwinner" yalnız literatür bağlamında kullanılır.
- **Tablolar.**
  - flextable ile docx, aynı içerikte csv ve `Results/tablolar_tumu.xlsx` (sayfa başına bir tablo; alt ve üst simgeler `xlsx_simge.py` ile gerçek biçimde).
  - Times New Roman, hücreler 9 pt, notlar 8 pt. Yalnız üst ve alt çizgiler ile başlık altı çizgisi.
  - Birbirini kapsayan başlıklar birleşik hücre olur; grup başlıkları bir kez yazılır, alt kategoriler girintili.
  - "Decision", "Reject", "Supported" gibi sütun ya da ifade yok. Hücre içinde uzun yazı yok.
  - Açıklama gerekmedikçe not yok; notlar kısa.
  - Q~1~–Q~3~ gibi gösterimlerde gerçek alt simge kullanılır.
- **Figürler.**
  - Üstte "Figure 1." gibi bir başlık olmaz.
  - Paneller aynı figürün içinde kurulur ve dergi biçiminde **(a)**, **(b)** diye etiketlenir. "Figure 2a" ve "Figure 2b" diye ayrı figür olmaz.
  - 600 dpi PNG, yazı tipi gömülü PDF ve LZW TIFF.
  - Varsayılan matplotlib görünümü ve klasik kodlama fontları kabul edilmez. Tipografi ve tasarımda yaratıcı ol:
    - Birinci çalışmanın ailesi korunabilir (Avenir Next, yoksa Helvetica Neue; temel 8 pt, panel harfi 11 pt kalın).
    - Bu çalışmanın kendine ait, renk körlüğüne uygun bir paleti olsun.
    - Kadın ve erkeği pembe ve mavi gibi kalıp renklerle kodlama.
  - Çift eksen yok. Alt simgeler mathtext ile.
  - Detay bilgi taşımıyorsa eklenmez.
  - Her figürün İngilizce altyazı taslağı `Figures/figur_altyazilari.md`'ye yazılır. Altyazılar kısa tutulur.
- **Denetim çıktısı ile yayın çıktısını ayır.** Tanı grafikleri `Results/denetim/` ve `Results/log/` altında kalır ve raporda özetlenir; her biri Supplementary öğesine dönüşmez.
  - Grafikle değerlendirilmesi gereken bir durumu, grafiği incelemeden değerlendirilmiş sayma.

### Rapor.md

Birinci çalışmadaki yapıyı kullan:

0. Durum: son güncelleme zamanı, hangi aşamada olunduğu, bitenler, sırada ne olduğu, tahmini süre. Uzun koşularda ilerleme satırı.
1. Aşama günlüğü. Her aşama için: amaç, ne yapıldı, neden, nasıl, ne bulundu, hangi dosyalar üretildi.
2. Karar defteri: K1, K2, … Her kayıtta karar, gerekçe, alternatif ve etkisi. Sonuçlar görüldükten sonra alınan kararlar ayrıca işaretlenir.
3. Doğrulama kontrolleri.
4. Bağlantı zincirleri ve kalitesi.
5. Fizibilite ve ortak destek.
6. Model kurma protokolü: kontrol, ölçüt, sonuç, karar.
7. Nihai değişken tanımları.
8. Ana sayılar (Results için).
9. Methods için notlar (İngilizce taslak cümleler dahil).
10. Araştırma sorularının değerlendirmesi: her biri için kanıt ve iddianın düzeyi.
11. Bize sorular: her soru için uyguladığın varsayılan karar.
12. Eksikler ve yapılamayanlar.
13. Dosya envanteri ve süreler.
14. İç denetim turları.

Her aşama bittiğinde ve 30 dakikayı aşan her hesabın ortasında güncelle.

### İnisiyatif

Bu belge bir başlangıç tasarımıdır, mekanik bir liste değildir. Gerekçeli yargı kullanmanı istiyoruz.

**Sen karar verirsin; gerekçeyi karar defterine yazarsın:**

- Kodlama ve seyrek kategorilerin birleştirilmesi.
- Spline düğümleri ve serbestlik dereceleri (Bölüm 6'daki önceden belirlenmiş değerlerle başlayarak).
- Prior ölçeklerinin prior predictive check'e göre düzeltilmesi (sonuçlar görülmeden).
- Örnekleyici ayarları ve iterasyon sayıları.
- Hesaplama yolu (CPU ya da GPU).
- Figür düzeni (stil içinde).
- Tablo ayrıntıları.
- Bir tanının gerektirdiği orantılı düzeltme.

**Ek analiz ekleyebilirsin.** Yeni bir analiz, ayrı bir soruyu yanıtlıyorsa ya da ana sonucun bağlı olduğu önemli bir belirsizliği değerlendiriyorsa eklenir. Hangi soruyu yanıtladığını yaz. Analiz sayısı için önceden bir hedef yok; gerekçesiz genişletme yapma.

**Bu planda bir hata ya da veriyle uyuşmayan bir varsayım görürsen** kanıtıyla "Bize sorular"a yaz, en makul düzeltmeyi uygula ve devam et.

**Bize sorarsın; soruyu yazar ve varsayılanla devam edersin:**

- Tahmin edilecek büyüklüklerin (E1–E4) ya da hedef nüfusun tanımında değişiklik.
- Bir ana analizin çıkarılması.
- Bir nüfus grubunun dışlanması.
- Ana analizin 2025'e döndürülmesi.
- Sonuç ya da maruziyet tanımının değiştirilmesi.

**Sonuçlara bakarak tanım değiştirme.** Sonuçlar görüldükten sonra yapılan her değişiklik karar defterinde öyle işaretlenir.

---

## 3. Aşama 0a: Veri hazırlığı

### 3.1. Okuma ve doğrulama

Okuma 1 ile oku, parquet yaz. Tarif belgesindeki doğrulama değerlerini yeniden üret ve `Results/dogrulama_kontrolleri.csv`'ye yaz. En azından şunlar tutmalı:

- 239.985 satır, 266 sütun.
- Yıllara göre hane sayısı 24.932 / 25.925 / 25.836.
- 2025'te HE090 = 1 / 2 hane sayısı 15.772 / 10.064.
- FK240 dolu fert sayısı 38.531 / 39.747 / 39.494.
- HB040 yıllık toplamı 26,7–27,2 milyon hane.
- 2023'te TR63 hanesi yok.

### 3.2. Çiftin belirlenmesi

- Her hane için eş bağlarını FK240 ile kur (aynı yıl içinde FERT_ID'ye gönderme yapar; tarif Bölüm 6.3). Bağları şu sınıflara ayır:
  - karşılıklı ve tekil;
  - karşılıklı olmayan;
  - bir kişiye birden fazla eş bağı;
  - aynı hanede birden fazla karşılıklı çift (ör. anne-baba ile evli çocuk ve eşi).
  
  Çok çiftli hane ile çok eşlilik ayrı durumlardır; ikisini karıştırma.
- **Analiz çifti:** hane reisi (FK095 = 1) ile FK240 üzerinden karşılıklı ve tekil olarak bağlı eşi (FK095 = 2). Eşlerin farklı cinsiyette olduğunu FK090 ile denetle.
- **Kazanan eş anlamında "kadın" ve "erkek":** FK090 = 2 kadın, FK090 = 1 erkek. Hane reisinin cinsiyeti ayrıca kaydedilir.
- Çok çiftli hanelerde analiz çifti yine referans çifttir. Referans dışı çiftin kazancı "diğer gelir"in parçasıdır. Duyarlılık için tek çiftli haneler analiz edilir. Referans çiftin kazancı olmayıp referans dışı çiftin kazandığı hane sayısını raporla.

### 3.3. Uygunluk ve kazanç

**Her eşin net çalışma kazancı:**

E_k = FG010 + FG020 + FG030 + FG040

- Bileşenler ücret (nakdi ve ayni) ile müteşebbis geliridir (nakdi ve ayni).
- `f_kayit = 1` olan eşlerde boş gelir hücresi 0 sayılır.
- Bireysel kaydı olmayan eşin boş kazancı sıfır değildir; bilinmiyordur.
- **Negatif değerler sıfırlanmaz.** Önce her eşin net toplamı hesaplanır.

**Uygunluk:**

- İki eş de FK070 ≥ 18. FK070, gelir yılının 31 Aralık tarihindeki yaştır.
- En az biri 18–64 yaşında. Örneklem bu yüzden "iki eşi de çalışma çağında" diye tanımlanmaz.
- İki eşin de bireysel kaydı var (`f_kayit = 1`).
- E_kadın ≥ 0, E_erkek ≥ 0 ve E_kadın + E_erkek > 0.

**Dışlananlar, ayrı ayrı sayılır ve raporlanır:**

- Kazancı olmayan çiftler.
- Negatif net kazançlı eşi olan çiftler.
- Bireysel kaydı eksik eşi olan çiftler.
- Belirsiz eş bağları.
- Referans çifti olmayan haneler.

**Pay ve kazanan yapısı:**

- s = E_kadın / (E_kadın + E_erkek).
- G = M (yalnız kocanın pozitif net kazancı var; s = 0), D (iki eşinki de pozitif) ya da F (yalnız kadınınki; s = 1).
- "Yalnız kadın kazanıyor" etiketi, çift içinde yalnız kadının pozitif net çalışma kazancı olduğu anlamına gelir. Koca emekli aylığı alıyor olabilir; hanedeki başka biri çalışıyor olabilir. Bu etiket "hanenin tek gelir sağlayıcısı" diye yorumlanmaz.

**Bayraklar:**

- FI120 = 5 (esas işte ücretsiz aile işçisi; görüşme anındaki çalışanlar için tanımlı), iki eş için ayrı ayrı.
- Ücret örneği: iki eşte de FG030 = 0 ve FG040 = 0. Sıfır kazançlı eşler korunur; böylece tek kazanan grupları bu örnekte kalır.
- Eşin gelir yılında çalıştığı ay sayısı (FI260 + FI270). Bu bir "kazanan" ölçütü değildir.
- Gelir yılındaki kazanan yapısı ile görüşme anındaki çalışma durumunun (FI010 ∈ 1–4) uyumu.

### 3.4. Gelir terimleri ve kovaryatlar

**Ölçek.** m_t, t yılındaki bütün hanelerde (her hane bir kez, `hane_reisi == 1`) HB040 ağırlıklı HG110 medyanıdır.

- Çiftin kazancı: E = E_kadın + E_erkek.
- Diğer gelir: O = HG110 − E. O; emekli aylıklarını, transferleri, diğer üyelerin kazancını, izafi kirayı ve düşülen kalemleri içerir. Negatif olabilir.
- Modele asinh(E / m_t) ve asinh(O / m_t) girer.
- Duyarlılık: O_izk = HG110 − HG010 − E (izafi kira hariç).

**Hane bileşimi:**

- n_0_5: FK070 ≤ 5. FK070 = −1 olan, anket yılında doğan bebekler bu sayıya dahildir.
- n_6_13 ve n_14_17.
- n_diger_18_64 ve n_diger_65: iki eş hariç diğer yetişkinler.

**Eşler:**

- Kadının ve kocanın yaşı.
- Her iki eşin eğitimi (FE030; 5 grup: 0–1, 2–3, 4, 5–6, 7–10).

**Diğer değişkenler:**

- Yıl.
- HB031 (İBBS-2) ve HB030 (İBBS-1).

**Genişletilmiş set (M3):**

- Her eşte süregelen sağlık sorunu nedeniyle günlük faaliyetlerde sınırlanma (FS030 ∈ {1, 2}).
- Her eşte kronik hastalık (FS020 = 1).
- Mülkiyet (HH020; ev sahibi, kiracı, lojman ya da kira ödemeden oturma).

Bu değişkenler görüşme anına aittir ve zamansal konumları belirsizdir. Bu yüzden M3 "genişletilmiş koşullama" diye adlandırılır, "tam düzeltilmiş" diye değil.

**Kocanın durumu (yalnız F çiftlerinde, gelir yılına göre):**

- Koca gelir yılında en çok ayı hangi durumda geçirdiyse o kategoriye girer: emekli (FI290), işsiz (FI280) ya da diğer faal olmayan (FI310).
- Eşitlikte sıra: emekli, işsiz, diğer.
- Ayrı bayraklar:
  - FG080 > 0 (gelir yılında emekli ya da yaşlılık aylığı).
  - FG110 > 0 (malulen emeklilik).
  - FI260 + FI270 > 0 iken E_erkek = 0: kazançsız çalışma, örneğin ücretsiz aile işçiliği. Bu tutarsızlığı say ve raporla.
- Güncel durum (FI010) ayrıca tablolanır, ama sınıflamada kullanılmaz.

### 3.5. Yıllar arası bağlantı zincirleri

Rotasyonlu panel tasarımı nedeniyle aynı haneler birden çok yılda yer alır; kimlik numaraları ise her yıl yeniden verilmiştir (inceleme raporu Bölüm 4). Zincirler yalnız tekrar bağımlılığını modellemek için kullanılır. Hane içi değişim tahmini yapılmaz. İnceleme raporunun "analizde bağlantı anahtarı olarak kullanılması önerilmez" uyarısı, aşağıdaki duyarlılık analizleriyle karşılanır.

**Algoritma.** Bağlantı, analiz filtrelerinden önce bütün çok kişili hanelerde kurulur; filtreler sonradan uygulanır.

1. **Üye imzası:** hanedeki bütün üyelerin (FK080 doğum yılı, FK075 doğum ayı, FK090 cinsiyet) üçlülerinin sıralı birleşimi. Aynı üçlüye sahip üyeler silinmez (`unique()` kullanma). İki yılda da yalnız bir kez geçen imzalar eşleşir.
2. **Çift anahtarı:** referans çiftin iki eşinin üçlüleri ile HB031. İki yılda da yalnız bir kez geçen anahtarlar eşleşir. Bebek doğduğunda ya da bir çocuk ayrıldığında imza bozulur; bu anahtar o eşleşmeleri yakalar.
3. **Hane reisi anahtarı** (yalnız duyarlılıkta): reisin üçlüsü, HB031, HH010 ve HH020; birinci çalışmadaki tanım.
4. Bağlantılar 2023–2024, 2024–2025 ve doğrudan 2023–2025 için kurulur ve bir grafa dönüştürülür. Bağlı bileşenler zincirdir.
   - Kısıt: bir zincirde bir yıldan en çok bir hane bulunur.
   - Bu kısıtı bozan bileşenlerdeki çelişkili bağları kaldır, sayısını raporla.
5. **Ana kural:** imza ya da çift anahtarı. **Duyarlılık kuralları:** yalnız imza; ana kurala hane reisi anahtarının eklenmesi.

**Kalite raporu** (`Results/denetim/` ve Supplementary):

- Yıl çiftlerine göre eşleşme sayıları. İnceleme raporundaki sayılarla karşılaştır: 12.924, 13.396 ve 7.432.
- Bağlantı türüne göre (yalnız imza, yalnız çift anahtarı, ikisi birden) eşleşmelerin HB031, HH010 ve HH020 uyumu. Anahtarın içinde olan değişkenlerin uyumu bağımsız kanıt sayılmaz; bunu tabloda belirt.
- Eşleşme oranı kazanan yapısına göre.
- 1, 2 ve 3 kayıtlı zincir sayıları.
- İki kayıtlı zincirlerde HE090 örüntüleri (00, 01/10, 11) ve bu örüntülerin bağlantı kuralına göre dağılımı.

---

## 4. Aşama 0b: Fizibilite denetimi

Model kurulmadan önce yapılır. Çıktılar `Results/denetim/fizibilite_*.csv` dosyalarına ve `Rapor.md` Bölüm 5'e gider. Bu aşamada HE090 ile maruziyet arasındaki ilişkiye bakılmaz; yalnız sayılar ve dağılımlar raporlanır.

1. Yıl ve kazanan yapısına göre hane sayısı, HE090 = 2 olay ve olay olmayan sayıları, ağırlıklı paylar ve Kish etkin örneklem büyüklüğü: (Σw)² / Σw².
2. D çiftlerinde payın ağırlıklı dağılımı. Üç çapa noktası çevresindeki destek: [0,05, 0,15], [0,45, 0,55] ve [0,85, 0,95] aralıklarında hane sayısı ve olay sayısı.
3. Her dışlama nedeni için yıllara göre sayılar: örneklem akışı.
4. F çiftlerinde kocanın durumunun dağılımı: gelir yılına göre sınıflama ve güncel durum. Ücretsiz aile işçisi bayraklarının G'ye göre dağılımı.
5. Bağlantı zincirlerinin özeti (Bölüm 3.5).
6. Eksik veri: Bölüm 9.

**Önceden belirlenmiş kurallar.** Bunlar sonuçlar görülmeden uygulanır.

- **F köşesi yeterliliği:** F grubunda havuzlanmış ortak destekte en az 200 hane, en az 50 olay ve en az 50 olay olmayan.
  - Sağlanırsa E3a ve E4 ana sonuçtur.
  - Sağlanmazsa E3a ve E4 yine tahmin edilir, ama "kesinliği düşük, keşifsel" diye işaretlenir.
  - Aynı kural M köşesi için de uygulanır.
- **Çapa noktaları:** her çapa aralığında en az 200 hane. Sağlanmazsa o çapaya dayanan büyüklük işaretlenir. Daha uç ya da başka bir noktaya geçilmez.
- **Kocanın durumu:** en az 50 hanesi olan kategoriler için düzeltilmiş E3a hesaplanır. Daha küçük kategoriler "diğer" ile birleştirilir ya da yalnız betimleyici olarak verilir.
- Bu sayılar raporlandıktan sonra durmadan devam et; özet ve varsayılanlar "Bize sorular"a yazılır.

---

## 5. Aşama 0c: Ortak destek

Standartlaştırma, her hanenin kovaryatlarını sabit tutup kazanan yapısını ve payı değiştirir. Bunun ekstrapolasyona dönüşmemesi için ortak destek kovaryatların birleşiminde tanımlanır, yalnız gelire göre değil.

1. **Karşılaştırma kategorileri (C5):** M, D_düşük (s ∈ [0,05, 0,15]), D_orta ([0,45, 0,55]), D_yüksek ([0,85, 0,95]) ve F.
2. Bu beş kategorideki hanelerde ağırlıklı çok terimli bir lojistik model (`nnet::multinom`) kurulur:
   - Yordayıcılar: M2'nin bütün kovaryatları; spline'lı gelir, yaş ve bileşim terimleri dahil.
   - Bölge İBBS-1 sabit etki olarak girer, yıl da modeldedir.
   - Model bütün uygun hanelerde e_k(X) olasılıklarını üretir; D'nin çapa dışındaki haneleri dahil.
3. **Dikdörtgen ortak destek** (Lopez ve Gutman, 2017, Statistical Science; atfı denetle):
   - Her k kategorisi için, gözlenen beş grubun her birinde e_k'nin ağırlıklı 1. ve 99. yüzdeliklerini bul.
   - Alt sınır, grupların 1. yüzdeliklerinin en büyüğüdür; üst sınır, 99. yüzdeliklerin en küçüğüdür.
   - Bütün k'lar için bu aralıkta kalan haneler hedef küme Q'yu oluşturur.
   - Uç değerlere duyarlılığı azaltmak için minimum ve maksimum yerine yüzdelikler kullanılır.
4. **Tek bir Q kullanılır.** M1, M2, M3 ve bütün standartlaştırmalar aynı Q üzerindedir. Her model için ayrı ortak destek kurulmaz.
5. **Rapor:** dışlanan hanelerin G'ye ve yıla göre sayısı ve ağırlıklı payı; desteğin içinde ve dışında kalan hanelerin karşılaştırması. Örtüşme figürü: G'ye göre e_k yoğunlukları.
6. **Uyarı eşiği:** Q, ağırlıklı uygun örneklemin %10'undan fazlasını ya da F'nin %25'inden fazlasını dışarıda bırakırsa "Bize sorular"a yaz ve devam et.
7. **Duyarlılık:** Q yerine bütün uygun haneler.

---

## 6. Aşama 1: Ana model

### 6.1. Tanım

logit P(Y_i = 1) = α + δ_M I(G_i = M) + δ_F I(G_i = F) + I(G_i = D) f(s_i) + g(E_i) + h(O_i) + X_i γ + τ_yıl + u_İBBS-2 + v_zincir

- f(0,5) = 0 olacak şekilde merkezlenir. α, dengeli iki kazançlı çiftin düzeyidir; δ_M ve δ_F köşelerin bu referansa göre farkıdır.
- **f:** doğal kübik spline. İç düğümler D çiftlerinde payın ağırlıklı 25., 50. ve 75. yüzdeliklerinde; sınır düğümleri 0 ve 1.
- **g ve h:** asinh ölçeğinde doğal spline'lar, df 4 ve 3.
- **Eşlerin yaşları:** ayrı spline'lar, df 3.
- **Uygulama tuzağı:** tek kazanan satırlarında payı NA bırakma; brms bu satırları sessizce modelden atar. Spline bazı önce kurulur, sonra her sütunu iki kazançlı göstergesiyle çarpılır. f{I(D)s} aynı model değildir.

```r
s_bos <- ifelse(d$G == "D", d$s, 0.5)
B <- splines::ns(s_bos, knots = dugum_s, Boundary.knots = c(0, 1))
B05 <- predict(B, 0.5)
Bs <- sweep(as.matrix(B), 2, as.vector(B05)) * (d$G == "D")
colnames(Bs) <- paste0("fs", seq_len(ncol(Bs)))
```

Asıl pay ve G değişkenleri korunur. Tahmin sırasında aynı `dugum_s` ile yeni bazlar kurulur.

### 6.2. Model düzeyleri

Üçü de aynı Q ve aynı ağırlıklarla kurulur.

| Model | İçerik |
|---|---|
| M1 | G, f(s), eşlerin yaşları ve eğitimi, hane bileşimi, yıl, İBBS-2 ve zincir etkileri |
| **M2 (ana)** | M1 + g(E) + h(O) |
| M3 | M2 + eşlerde sağlık kısıtlılığı ve kronik hastalık + mülkiyet |

- M1 "ham fark" değil, "gelir terimleri eklenmeden önceki ilişki"dir.
- M1, M2 ve M3 arasındaki farklar aracılık ya da pazarlık mekanizması olarak raporlanmaz.

### 6.3. Prior'lar ve örnekleme

**Prior'lar** (bunlar başlangıç değerleridir):

- Sabit terim: student_t(3, 0, 2,5).
- Bütün katsayılar: N(0, 1).
- σ_İBBS-2: HalfNormal(0, 1).
- σ_zincir: HalfNormal(0, 1). Duyarlılık: HalfNormal(0, 2).

σ_zincir'in ima ettiği bağımlılığı latent ölçekte ρ = σ² / (σ² + π²/3) ile yorumla: σ = 0,5, 1 ve 2 için ρ ≈ 0,07, 0,23 ve 0,55. Prior predictive check yap. Ölçekler gerekirse sonuçlar görülmeden düzeltilir ve kaydedilir.

**Ağırlıklar:** `y | weights(w_norm) ~ ...` (Bölüm 2). Bu bir pseudo-posterior'dur. Ağırlıklandırma temsili düzeltir; tasarımın belirsizliğini otomatik olarak yansıtmaz. Bunu Methods notlarında yaz.

**Örnekleme:**

- cmdstanr arka ucu; 4 zincir, en az 1000 ısınma ve 1500 örnekleme iterasyonu.
- `adapt_delta` gerekirse 0,95–0,99.
- Tohumlar sabit.
- Önce kısa bir pilot koşu yap; süreyi ölç ve toplam süre bütçesini raporla.

**Tanılar** (`Results/denetim/model_tanilari.csv`):

- R-hat ≤ 1,01; bulk ve tail ESS ≥ 400.
- Sıfır divergence; E-BFMI > 0,3.
- E1–E4 ve ROPE olasılıkları için Monte Carlo hatası (posterior paketi) raporlanır: farklarda 0,1 puanın, olasılıklarda 0,01'in altında olmalı. Değilse iterasyon artırılır.
- MCMC ESS ile anket ağırlıklarının etkin örneklem büyüklüğü ayrı kavramlardır.

**Posterior predictive check:**

- G ve yıla göre HE090 yaygınlığı.
- Pay aralıklarına göre yaygınlık.
- İBBS-2'ye göre yaygınlık.
- İki kayıtlı zincirlerde aynı ya da farklı sonuç oranı. Bu kontrol önemlidir: yaygınlığı iyi üreten bir model tekrar bağımlılığını yanlış modellemiş olabilir.
- σ_zincir için prior ve posterior dağılımı birlikte gösterilir.

### 6.4. Geri dönüş kuralı

Üç durumu ayır:

1. **Hesaplama ya da parametrizasyon sorunu** (divergence, R-hat): önce ölçekleme, parametrizasyon ve `adapt_delta` ile çözülür.
   - Çözülmezse ana analiz 2025'e döner: zincir etkisi olmadan, İBBS-2 etkisiyle.
   - Bu, farklı bir dönem ve hedef nüfusa geçiştir; raporda böyle yazılır.
   - Havuzlanmış sonuçlar gizlenmez, Supplementary'de verilir.
2. **σ_zincir zayıf öğreniliyor** (posterior prior'a yakın): model korunur. HalfNormal(0, 2) ile tekrarlanır. E1–E4 maddi olarak değişirse bu ana metinde raporlanır, yalnız Supplementary'de değil.
3. **Bağlantı kuralı belirsiz:** E1–E4 bağlantı kurallarına göre maddi olarak değişirse bu da ana metinde raporlanır. Daha uzun MCMC bu sorunu çözmez.

**Maddi değişiklik:** bir büyüklükte 1 yüzde puandan büyük fark ya da üç ROPE olasılığından en büyüğünün değişmesi.

---

## 7. Tahmin edilecek büyüklükler ve standartlaştırma

**Hedef nüfus.** Q kümesindeki, gözlenen coğrafi kapsamdaki uygun çift hane-yılları; ağırlık w_norm.

- 2023'te TR63 olmadığından bu nüfus her yıl aynı coğrafyayı temsil etmez; raporda yazılır.
- Ortak coğrafi kapsam için üç yılda da TR63'ün çıkarıldığı duyarlılık analizi yapılır.

**Senaryo a.** Her hanenin kovaryatları, yılı ve bölge etkisi korunur. Yalnız G ve s değiştirilir:

- "Herkes M" senaryosu.
- "Herkes F" senaryosu.
- "Herkes D, pay s" senaryosu; s, 0,05 ile 0,95 arasında 0,01 adımlarla.

Eğri, D çiftlerinde payın ağırlıklı 2,5. ve 97,5. yüzdelikleri arasında çizilir; çapalar bu aralıkta olmalıdır.

**Zincir etkisinin marjinalleştirilmesi.** Zincir etkisi sıfırlanmaz ve gözlenen zincirlerin posterior etkileri de kullanılmaz; dağılımı üzerinden integral alınır. `re_formula` içinden zinciri çıkarmak etkiyi sıfırlamak demektir; marjinalleştirme yapmaz.

Her posterior çekilişi için:

p̄_Q(a) = Σ_i ω_i ∫ logit⁻¹{η_i(a) + v} φ(v; 0, σ_v²) dv / Σ_i ω_i

Burada η_i(a), zincir etkisi dışındaki doğrusal tahmindir ve hanenin İBBS-2 etkisini içerir. İntegral 20 noktalı Gauss–Hermite kuralıyla alınır (statmod):

```r
gh <- statmod::gauss.quad(20, kind = "hermite")
p_marj <- function(eta, sigma) {
  rowSums(vapply(seq_along(gh$nodes),
    function(j) gh$weights[j] / sqrt(pi) * plogis(eta + sqrt(2) * sigma * gh$nodes[j]),
    numeric(length(eta))))
}
```

**Büyüklükler.** Yüzde puan cinsinden, her çekilişte hesaplanır.

| Kod | Tanım | Yorum sınırı |
|---|---|---|
| E1, yoğunlaşma | [p_D(0,1) + p_D(0,9)] / 2 − p_D(0,5) | E1 ≈ 0 eğrinin düz olduğu anlamına gelmez |
| E2, kimin kazandığı | p_D(0,9) − p_D(0,1) | Aynı yoğunlaşmada yön |
| E3a | p_F − p_D(0,9) | Tek kazanan olmak ile %90 kazancı sağlamak arasındaki standartlaştırılmış fark; 0,99'dan 1'e bir sıçrama değil |
| E3b | p_M − p_D(0,1) | Aynı yorum, erkek tarafı |
| E4 | p_F − p_M | E4 = E3a + E2 − E3b; türetilmiş bir özettir, ayrı bir soru değil |

Bütün büyüklükler aynı Q'dan, aynı çekilişlerden ve aynı marjinalleştirmeyle hesaplanır; E4'ün cebirsel ilişkisi denetlenir.

**Özetler:**

- Posterior medyanı ve %95 eşit kuyruklu aralık.
- Üç ROPE olasılığı: P(Δ < −2), P(|Δ| ≤ 2), P(Δ > 2). Ayrıca P(Δ > 0).
- Monte Carlo hataları.

ROPE ±2 yüzde puandır. Bu, araştırmacının önceden belirlediği bir pratik eşdeğerlik marjıdır; yerleşik bir eşik değildir. Duyarlılık ±1 ve ±3 puandır. Sonuçlar "benzer" ya da "farklı" diye etiketlenmez; tahmin ve aralık önde kalır.

**Eğri çıktısı.** `figur_verileri/`'ne D eğrisinin noktasal medyanı ve %95 aralığı, köşe olasılıkları ve D çiftlerinde payın ağırlıklı dağılımı yazılır.

---

## 8. Aşama 2: İkincil analizler

### 8.1. Yalnız kadının kazandığı çiftlerde kocanın durumu (öncelikli)

- Model: M2'de F kategorisi, kocanın gelir yılındaki durumuna göre ayrılır (F × durum).
- Her durum k için hedef küme Q_k: Q içindeki F çiftlerinden durumu k olanlar, kendi kovaryatlarıyla.
- E3a_k = p_F,k − p_D(0,9). İkisi de Q_k üzerinde hesaplanır.
- Figür ve tablo için her kategoride ayrıca raporlanır:
  - ağırlıksız n;
  - ağırlıklı ham HE090 oranı;
  - düzeltilmiş E3a_k.
- Bu analiz ana ilişkinin "mekanizmasını" açıklamaz; F grubunun içindeki örüntüyü ayrıntılandırır.

### 8.2. Yıllara göre farklılaşma (Supplementary)

- δ_k,t = δ_k + d_k,t, k ∈ {M, F}.
- d_k,t ~ N(0, 0,5). Bu prior ölçeği önceden sabitlenmiştir; üç düzeyle hiperstandart sapma öğrenilmez. Bir merkezleme kısıtı kullanılır.
- f(s) yıllar arasında ortaktır. Soru şudur: köşelerin iki kazançlı referansa göre farkı yıllara göre değişiyor mu?
- Yıllar, araştırma yılıyla etiketlenir. Farklar enflasyonun etkisi diye yorumlanmaz.
- Yüzde puan farklarındaki yıllar arası değişim, temel olasılıklar değiştiği için de ortaya çıkabilir; eğrinin yapısal değişimi diye yorumlanmaz.

---

## 9. Eksik veri

- **Değişken × yıl × G tablosu:** eksik sayılar ve nasıl ele alındıkları.
  - Gelirde boş hücre 0 demektir, eksik değildir. Diğer değişkenlerde boş hücre filtre dışı ya da yanıtsızdır.
  - 98 ("diğer") ve 99 ("bilmiyor") kodları için verdiğin kararı yaz.
- **Kayıtsız eşi olan çiftler:** gerçek kazanan yapıları bilinmediği için G'ye ayrılamazlar.
  - Eksiklik; gözlenen eşin özellikleri ile hane bilgileri (HE090, HG110 / m_t, bileşim, bölge, yıl ve gözlenen eşin kazancı) üzerinden incelenir.
  - Dahil edilen çiftlerle karşılaştırma ağırlıklı standardize farklarla yapılır.
  - Küçük farklar seçilim yanlılığı olmadığının kanıtı diye sunulmaz.
- **Kovaryat eksikliği:**
  - Hem toplamda hem her G'de %5'in altındaysa tam vaka analizi yapılır.
  - Daha yüksekse çoklu atamayı değerlendir; kararı gerekçesiyle yaz.
- **HG105 senaryosu yapılmaz:** atanmış gelirin kime ait olduğu belirsizdir.

---

## 10. Duyarlılık analizleri

Her analiz, ana M2'nin E1–E4 değerlerini aynı biçimde raporlar. Her birinin hangi soruyu yanıtladığı tabloda yazılır.

**A. Örneklem ve dönem** (hedef nüfus da değişir):

1. Yalnız 2025: zincir etkisi yok, İBBS-2 etkisi var. *Figure 3b'ye girer.*
2. 2023 ve 2024 ayrı ayrı.
3. Ücret örneği: iki eşte de müteşebbis geliri yok. Aile işletmesinde kazancın tek eşe yazılması sorununu hedefler. *Figure 3b'ye girer.*
4. Eşlerden biri ücretsiz aile işçisi olan çiftlerin çıkarılması.
5. Tek çiftli haneler.
6. Tüm yaşlar (iki eş de 18 ve üstü).
7. Üç yılda da TR63'ün çıkarılması (ortak coğrafi kapsam).
8. Gelir yılındaki kazanan yapısı ile görüşme anındaki çalışma durumu uyuşan çiftler. Bu bir istikrarlı çalışma düzeni duyarlılığıdır, "daha doğru ölçüm" değildir.
9. Ortak destek yerine bütün uygun haneler.

**B. Tahmin yaklaşımı:**

10. Ağırlıksız Bayesçi model; standartlaştırmada yine HB040 temelli hedef dağılım. *Figure 3b'ye girer.*
11. **Survey modeli:**
    - `svydesign(ids = ~zincir, weights = ~HB040)`; `svyglm` (quasibinomial) ile M2 terimleri, İBBS-2 sabit etki ve yıl.
    - Bağlantı yalnız varyansta kullanıldığından nokta tahminleri bağlantıdan bağımsızdır.
    - Standartlaştırılmış büyüklüklerin güven aralıkları zincir düzeyinde bootstrap replikat ağırlıklarıyla hesaplanır (`as.svrepdesign`, 1000 replikat).
    - Adı: "mevcut tasarım bilgileriyle kurulmuş ağırlıklı duyarlılık modeli". Tam tasarım temelli doğrulama değildir.
    - Güven aralığı ile posterior aralığı ayrı adlandırılır; bu modelden ROPE olasılığı türetilmez.
    - *Figure 3b'ye girer.*
12. Zincir etkisi olmadan; kayıtlar bağımsız.
13. Bağlantı kuralı: yalnız imza; ana kurala hane reisi anahtarının eklenmesi.
14. σ_zincir prior'ı: HalfNormal(0, 2).

**C. Tanım:**

15. Kazanan eşiği: payın %5'in altı M, %95'in üstü F sayılır.
16. O yerine izafi kira hariç O.
17. g(E) ve h(O) yerine, eşdeğer hane gelirinin yıl medyanına oranı (asinh, spline).
18. f(s) için df 3 ve 5.
19. ROPE ±1 ve ±3 puan.
20. M3.

**Süre bütçesi.** Her Bayesçi yeniden kurulum saatler alabilir. Pilotlardan sonra toplam süre tahminini raporla.

- Bütçe yaklaşık 24 saati aşacaksa, C grubundaki tanım duyarlılıklarını zincir etkisi olmadan kurabilirsin. Bunu kaydet; A ve B gruplarındaki analizler tam modelle yapılır.
- Önbellek ve paralel koşu kullan.

---

## 11. Tablolar ve figürler

Ana metin beş öğedir. Okuma sırası Figure 1 → Table 1 → Figure 2 → Table 2 → Figure 3. Makalenin ağırlık merkezi Figure 2 ve Table 2'dir.

**Figure 1. Tasarım ve örneklem.**

- **(a) Sade örneklem akışı:**
  - üç yıldaki hane-yılları;
  - referans çifti olan haneler;
  - temel dışlamalar (gruplanmış);
  - uygun örneklem;
  - ortak destek (Q);
  - Q içindeki M, D ve F sayıları.
  
  Birim her yerde hane-yılıdır; zincir sayısı ayrıca verilebilir. Toplam satırı "farklı hane sayısı" gibi sunma. Ayrıntılı dışlama sayıları Supplementary'ye gider. Kutu ya da bant boyutları sayılarla orantılı olsun; birinci çalışmanın Figure 1'i biçim örneğidir.
- **(b) Kavram şeması:**
  - Ortada iki kazançlı çiftlerin pay ekseni; iki yanda, eksenden görsel olarak kopuk M ve F köşeleri.
  - %10, %50 ve %90 noktaları hafifçe işaretlenir.
  - E1–E4 formülleri ve karşılaştırma okları bu panelde yer almaz; panelin görevi ayrımı öğretmektir.

**Table 1. Ortak destek örneklemindeki (Q) hanelerin özellikleri.**

- Sütunlar:
  - Yalnız koca.
  - İki kazançlı, birleşik başlık altında üç alt sütun: kadın payı < 0,40; 0,40–0,60; > 0,60.
  - Yalnız kadın.
  - Payın üç grubu yalnız betimleme içindir; modelde pay süreklidir. Bunu dipnotta yaz.
- Satırlar, bu sırayla:
  1. Ağırlıksız hane-yılı sayısı ve ağırlıklı grup payı.
  2. Gıda yoksunluğu yaygınlığı.
  3. Çiftin kazancı ve diğer gelir. Yıl medyanına oran olarak verilir, nominal TL ya da asinh değil; medyan (Q~1~–Q~3~).
  4. Eşlerin yaşı ve eğitimi.
  5. Çocuklar ve diğer üyeler.
  6. Bölge (İBBS-1, kısa) ve yıl.
- p değeri yok; tablo grupları sınamak için değil, karşılaştırılan haneleri göstermek için var.
- Q öncesi uygun örneklem ve Q dışında kalanlar Supplementary'de verilir.

**Figure 2. Ana ilişki (M2).**

- **(a)**
  - Yatay eksen: iki kazançlı çiftlerde kadının payı.
  - Dikey eksen: standartlaştırılmış gıda yoksunluğu olasılığı (%).
  - Medyan eğri ve noktasal %95 posterior aralığı bandı.
  - Eğrinin altında ince bir alan: D çiftlerinde payın ağırlıklı dağılımı.
  - M ve F köşeleri eğriye çizgiyle bağlanmayan ayrı noktalar ve aralıklar olarak gösterilir.
  - %10, %50 ve %90 hafif işaretli.
  - Eğri yalnız destek aralığında çizilir.
- **(b)** Dört satırlık nokta-aralık grafiği: E1, E2, E3a, E3b.
  - Yalnız M2.
  - Yatay eksen yüzde puan farkı; sıfır çizgisi ve ±2 puanlık ROPE bandı gösterilir.
  - E4, M1, M3 ve duyarlılıklar bu panelde yer almaz.

**Table 2. Önceden belirlenmiş karşılaştırmalar, M1 ve M2.**

- Satırlar E1, E2, E3a, E3b. E4 en altta, "türetilmiş özet" olarak ve daha düşük görsel ağırlıkla.
- Sütunlar, birleşik başlıklarla M1 | M2; her birinin altında:
  - tahmin (%95 posterior aralığı);
  - P(Δ < −2);
  - P(|Δ| ≤ 2);
  - P(Δ > 2).
- M1 sütunu "gelir terimleri eklenmeden önce" olarak etiketlenir, "crude" değil.
- İki model aynı Q ve aynı hedef ağırlıklarla hesaplanır.

**Figure 3. İkincil bulgu ve duyarlılık.**

- **(a) Yalnız kadının kazandığı çiftlerde kocanın durumu:** her kategoride n, ağırlıklı ham yaygınlık ve düzeltilmiş E3a_k (Bölüm 8.1). Mutlak olasılık ve yüzde puan farkı aynı eksende karışmaz; panel içinde ayrı alt eksenler kullan.
- **(b) Örneklem ve model duyarlılıkları:**
  - E1, E2, E3a ve E3b için dört küçük grafik.
  - Satırlar: ana M2; yalnız 2025; ücret örneği; ağırlıksız model; survey modeli.
  - Satırlar iki blokta gruplanır: örneklem ve dönem değişiklikleri (2025, ücret örneği) ile tahmin yaklaşımı değişiklikleri (ağırlıksız, survey).
  - Survey modelinin güven aralığı farklı bir işaretle gösterilir ve altyazıda tanımlanır.

**Supplementary.** Numaralar ana metindeki ilk atıf sırasına göre en sonda verilir. Taslak liste:

1. **Değişkenler ve örneklem:** türetilen değişkenlerin tanımları; yıllara göre dışlama akışı; yıl ve G'ye göre hane, olay ve olay olmayan sayıları ile Kish etkin örneklem büyüklüğü; bağlantı zincirleri ve kalitesi.
2. **Eksik veri:** değişken × yıl × G eksikliği; kayıtsız eşi olan çiftler ile dahil edilen çiftlerin karşılaştırması.
3. **Model:** denklemler ve prior'lar; yakınsama tanıları; prior ve posterior predictive check figürü (zincir içi sonuç birlikteliği dahil).
4. **Ortak destek:** örtüşme figürü; destek içi ve dışı karşılaştırması.
5. **Ek sonuçlar:** M3; yıllara göre farklılaşma; bütün katsayılar ve varyans bileşenleri; ROPE ±1 ve ±3.
6. **Tasarım ve tahmin duyarlılığı:** Bölüm 10 B.
7. **Örneklem ve tanım duyarlılığı:** Bölüm 10 A ve C. Bir tablo ve bir orman figürü.
8. **Yazılım:** paketler, sürümler ve her paketin rolü.
9. **Kaynaklar.**

Biçim örneği `../[önceki çalışma 1]/[makale klasörü]/Supplementary Material.docx`'tir. Docx'i biz kuracağız; sen tabloları ve figürleri bu düzene uygun üret.

**sayilar.json.** Makalede geçecek her sayı (tahmin, aralık, olasılık, n, olay, model) makine okunur biçimde yazılır.

**strobe_akis.md.** STROBE (kesitsel çalışmalar) maddelerine göre notlar.

---

## 12. Tuzaklar (kontrol listesine al)

- Hane değişkenleri her ferde yazılıdır. Hane düzeyi için `hane_reisi == 1` satırı kullanılır; eşin bilgisi FK240 ile bulunur.
- FK070 gelir yılı sonundaki yaştır; anket yılında doğanlar −1 değerini alır.
- 2023'te HB040 = FB030'dur; yine de hane düzeyinde HB040 kullanılır.
- 2023'te TR63 hanesi yoktur.
- Gelir önceki yıla, HE090 görüşme anına aittir. Eşlerin gelir yılının tamamında birlikte yaşadığı doğrulanamaz; bunu sınırlılık olarak kaydet.
- İki eşin aynı yılda pozitif kazancı olması, aynı aylarda birlikte çalıştıkları anlamına gelmez.
- FG040'ta açık 0 değerleri ve boşlar aynı anlamdadır.
- FG030 ve FG140 negatif olabilir; net toplamlar bu nedenle önce hesaplanır.
- HG110'un %0,1'i TÜİK'in negatif gelir kuralıyla değiştirilmiştir; O bu hanelerde tuhaf değerler alabilir, raporla.
- Kodlar alışılmadıktır: HB050 için 1, 21, 22, 23, 3, 4; FI010 için 1–10. Etiketleri `kodlar.csv`'den al.
- brms'te herhangi bir yordayıcıda NA olan satır sessizce düşer. Uyum öncesi ve sonrası satır sayılarını her modelde denetle.
- Standartlaştırma ve E1–E4 aynı çekilişlerden hesaplanır; parça parça farklı özetlerden birleştirilmez.

---

## 13. İç denetim

Birinci çalışmada yapıldığı gibi, analizler bittikten sonra en az bir bağımsız iç denetim turu yap ve `Rapor.md` Bölüm 14'e işle:

1. Kod, sayılar ve yöntem: bir hakem gözüyle.
2. Sunum ve yorum.

Bu turları çalışmaya katılmamış bir denetçiye yaptır; ona çalışmayı değil, kodu ve çıktıları ver. Bulguları ve verdiğin kararları kaydet.

---

## 14. Teslim listesi

- **`Codes/`:** çalışır ve sıralı scriptler ile `README_kodlar.md` (çalıştırma sırası, süreler, ortam, tohumlar, önbellekler).
- **`R_Data ve Python Data/`:** parquet dosyaları, önbellekler, `figur_verileri/`.
- **`Results/`:**
  - Table 1–2 (docx ve csv), `tablolar_tumu.xlsx` ve `Supplementary/` tabloları.
  - `sayilar.json`, `model_ozetleri.txt`, `model_protokolu.csv`, `dogrulama_kontrolleri.csv` ve `degisken_tanimlari.csv`.
  - `strobe_akis.md`, `paket_atiflari.txt`, `sessionInfo.txt` ve `python_ortam.txt`.
  - `denetim/` ve `log/` klasörleri.
- **`Figures/`:** Figure 1–3 (PNG 600 dpi, PDF, TIFF), `Supplementary/` ve `figur_altyazilari.md`.
- **`Rapor.md`** tamamlanmış olarak.
- **`docs/`:** bu belgenin arşiv kopyası ve `CHANGELOG.md`.
- **Temiz çalıştırma:** türetilmiş dosyalar bir arşiv klasörüne taşınır ve her şey ham xlsx'ten baştan çalıştırılır. Ardından `sayilar.json` önceki koşuyla karşılaştırılır ve sonuç `Rapor.md`'ye yazılır.

---

## Ek A. Yazım tercihlerimizden bu işi ilgilendirenler

Makaleyi biz yazacağız, ama senin çıktıların doğrudan metne girecek. Bu yüzden şu kurallar senin için de geçerlidir.

- **Veriye sadakat.**
  - Sayıları, yönleri, aralıkları, n'leri ve analiz birimini aynen raporla.
  - Koşullu ilişkiyi nedensel etki gibi yazma.
  - "Gelir benzerken" bulgusunu "kadının kazancını artırmanın etkisi" diye yorumlama.
  - Kesitsel veriden zaman sırası çıkarma.
  - Anlamlı bulunmayan ya da ROPE içinde kalan sonucu "ilişki yok" diye kesinleştirme.
  - Duyarlılıklar ana yorumu zayıflatıyorsa bunu ana bulgularda yaz.
- **Ölçümün niteliği.**
  - HE090 tek maddedir; "food insecurity" demek yerine "food deprivation" de.
  - Kazanç payı karar gücü ya da para yönetimi değildir; kimin kazandığını ölçer, parayı kimin yönettiğini ölçmez.
- **Methods notları.**
  - İngilizce, kısa ve kesintisiz paragraflar halinde.
  - Analizde rol oynayan paketlere atıf için `citation()` çıktısını kullan.
  - Denklemler LaTeX olarak yazılır; biz Word denklemine çevireceğiz.
- **Tablo ve figür metinleri.**
  - Amerikan İngilizcesi.
  - Uzun altyazı ve not yazma.
  - Supplementary'deki her öğenin ana metinde nereden atıflanacağını `Rapor.md`'de not et.
- **Rapor dili.**
  - Bulgu, yorum ve olası mekanizmayı birbirinden ayır.
  - "Bu çok önemli" demek yerine neyi değiştirdiğini yaz.
