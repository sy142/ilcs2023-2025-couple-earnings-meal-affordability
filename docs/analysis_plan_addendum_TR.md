# Talimat Ek 1: Hane içi zaman kanalı testleri ve figürlerin yeniden tasarımı

> Arşiv sürümü (v1.0.0): ana planın dosya adı arşivdeki adıyla (`docs/analysis_plan_TR.md`) yazıldı ve iki ifade sadeleştirildi; analiz içeriğinde değişiklik yapılmadı.

Sürüm 1, 1 Kasım 2026. `analysis_plan_TR.md`'nin eki; oradaki bütün çalışma kuralları geçerlidir. Önce `Rapor.md` Bölüm 0 ve 13'ü, `Codes/README_kodlar.md`'yi ve bu dosyayı oku. Başka bir projenin klasörüne yazma. Mikro veri hiçbir yere yüklenmez.

Bu ekteki analizler **ana sonuçlar görüldükten sonra** tasarlandı. Karar defterine K-numarasıyla "sonuç sonrası" diye işlenir; tablolarda ^p işareti taşır. Ana modeller (M1–M3), ortak destek, E1–E4 ve mevcut duyarlılıklar **değişmez**; hiçbir mevcut sayı yeniden üretilmez.

---

## 0. Ne test ediyoruz ve neden

**Soru.** Yalnız erkeğin kazandığı çiftler, aynı toplam kazanç ve diğer gelirde, kadının payının küçük olduğu iki kazançlı çiftlerden daha az gıda yoksunluğu bildiriyor (E3b = −2,7 puan). Tartışmada iki açıklama var:

- **Zaman kanalı (hane üretimi):** Çalışmayan eş yemek alışverişine ve hazırlığına zaman ayırabiliyor; parasal gelir aynıyken öğünün parasal maliyeti düşüyor. Eş çalışınca bu zaman azalıyor, dışarıdan ya da hazır gıdaya yöneliş artıyor (Bircan Bodur ve Mukiyen Avcı 2015; TÜİK Aile Yapısı 2021: yemek yapma %85,4 kadında).
- **Sıkışma kanalı (added worker):** Kadın, hane zaten zorda olduğu için düşük ücretli işe giriyor; küçük pay bir sıkıntı işaretidir, nedeni değil.

**Mevcut karşı kanıt.** Görüşme anındaki istihdamı gelir yılındaki yapıyla uyuşan çiftlerde E3b = 0,1 (−3,1; 3,1). Zaman kanalı ana açıklama olsaydı fark bu örneklemde en belirgin olmalıydı. Bu ekteki testler bu bulguyla birlikte yorumlanır.

**Çerçeve.** Değişken "kadının evde kalması" değil, **hane içinde yemek üretimine ayrılabilen zaman**dır; kimin sağladığından bağımsız tanımlanır. Metinde, raporda ve tablolarda eşlerin ne yapması gerektiğine ilişkin hiçbir ifade yer almaz. Sonuç hipotezi desteklemezse öyle yazılır.

**Önceden ilan edilen yönler (model kurulmadan yazıldı):**

| Test | Zaman kanalı öngörüsü | Sıkışma kanalı öngörüsü |
|---|---|---|
| T1. Payı düşük kadınların çalışma yoğunluğu | Betimsel; yön yok | Betimsel; yön yok |
| T2. İki kazançlılarda kadının yoğunluğu ↑ → yoksunluk | Artar (aynı kazanç ve payda) | Artabilir (düşük ücret işareti); ayırt edici değil |
| T2'. Kocanın yoğunluğu ↑ → yoksunluk | Kadınınkinden küçük | Belirsiz |
| T3. Hanede çalışmayan başka yetişkin varken E3b | Mutlak değeri küçülür | Öngörü yok |

T3 iki açıklamayı ayırabilecek tek testtir; T2 ve T2' destekleyici, T1 öncül niteliğindedir.

---

## 1. T1: Çalışma yoğunluğu betimsel tablosu (Table S19)

Örneklem: Q. Gruplar: Table 1'in sütunları (M; D payı <0,40, 0,40–0,60, >0,60; F) ve ek olarak D payı 0,05–0,15 (çapa bandı).

Her grupta, kadın ve koca için ayrı ayrı:

- Gelir yılında tam zamanlı çalışılan ay (FI260): ağırlıklı medyan (Ç1–Ç3).
- Yarı zamanlı ay (FI270): medyan (Ç1–Ç3).
- Tam zaman eşdeğeri ay: TZE = FI260 + 0,5 × FI270 (tarif belgesi Denklem 8'deki 0,5 katsayısı; çalışmanın varsayımıdır, notta yazılır).
- TZE ≥ 10 ay olanların yüzdesi; TZE = 0 olanların yüzdesi.
- Görüşme anında çalışanlarda (FI010 = 1–4) esas iş haftalık saat (FI150): medyan (Ç1–Ç3) ve ≥ 40 saat yüzdesi. Not: görüşme anı ölçümüdür, gelir yılı değil.

Ek satır: D payı <0,20 olan çiftlerde kadının TZE'sine göre (≤ 6 ay; > 6 ay) ham ağırlıklı HE090 yüzdesi ve ağırlıksız n. n < 20 gizleme ve 20–50 işaretleme kuralı geçerli.

Beklenen tutarsızlıklar raporlanır: M çiftlerinde kadının TZE > 0 olması (ücretsiz aile işçiliği; Rapor K16'da sayılmıştı), D çiftlerinde TZE = 0 olan eş (kazanç var, ay yok).

Çıktı: `Results/Supplementary/TableS19.csv/.docx`, `sayilar.json` → `zaman_kanali.T1`.

---

## 2. T2 ve T2': Çalışma yoğunluğu modeli (X1)

M2'ye iki terim eklenir: kadının TZE'si ve kocanın TZE'si, her biri 3 df doğal spline (düğümler Q'daki ağırlıklı tertiller; TZE = 0 yığılması varsa düğümleri pozitif değerlerin tertillerine koy ve raporla). Pay spline'ı, gelir terimleri ve bütün kovaryatlar aynen kalır. Prior'lar M2 ile aynı; 4 zincir, 1.000 ısınma + 4.500 örnekleme; tanılar Table S8 ölçütleriyle.

Standartlaştırma (Gauss–Hermite ile zincir etkisi üzerinden, M2'deki gibi), **yalnız Q'daki D çiftleri** üzerinde, payı ve gelirleri gözlenen değerinde tutarak:

- T2: kadının TZE'si 12 aya karşı 6 aya ayarlandığında standartlaştırılmış olasılık farkı (puan), medyan ve %95 CrI; ROPE ±2 olasılıkları. Kocanın TZE'si gözlenen değerinde.
- T2': kocanın TZE'si için aynı fark; kadınınki gözlenen değerinde.
- Her iki eğri 0–12 ay aralığında 13 noktada (`figur_verileri/`).
- Ayrıca X1'de E1–E4: senaryolarda M çiftlerinde kadın TZE = 0, D çiftlerinde kadın TZE gözlenen değerinde (yani E3b, kadının zamanı modele girdikten sonraki "artık" fark). M2'nin E3b'siyle yan yana raporlanır; fark 1 puandan büyükse metinde yorumlanır.

Yorum sınırı (raporda yaz): T2 pozitif çıksa bile iki kanal da bunu öngörür; yalnız T2 > T2' örüntüsü zaman kanalını bir adım daha destekler.

Çıktı: `Results/Supplementary/TableS20.csv/.docx` (tahminler, CrI, ROPE, tanılar), `sayilar.json` → `zaman_kanali.X1`.

---

## 3. T3: Başka yetişkin etkileşimi (X2)

**Değişken A (hane üretimini üstlenebilecek başka yetişkin):** Eşler dışında, 18 yaş ve üstü, görüşme anında çalışmayan (FI010 ∉ {1,2,3,4}; bireysel kaydı olmayan 18+ üyeler "çalışmıyor" sayılmaz, dışarıda bırakılır ve sayıları raporlanır) en az bir hane üyesi varsa A = 1. Duyarlılık: A' = herhangi bir başka 18+ üye (çalışma durumuna bakılmaksızın). Q'da A = 1 ve A = 0 hücrelerinde M, D, F sayıları ve olay sayıları önce raporlanır; bir köşede 50 olay ya da 50 olay-olmayanın altı varsa model yine kurulur ama "kesinliği düşük" işaretlenir.

**Model:** M2 + A ana etkisi + A × [δ_M, δ_F, f(s)] etkileşimleri (iki pay eğrisi). Diğer yetişkin sayıları (18–64 ve 65+) kovaryat olarak zaten modeldedir, kalır. Prior'lar: etkileşim katsayıları N(0, 1); gerisi M2 ile aynı.

**Raporlanacaklar:**

- E3b ve E4, A = 1 hanelerde (kendi haneleri üzerinde standartlaştırılarak) ve A = 0 hanelerde ayrı ayrı; medyan, %95 CrI, ROPE ±2.
- İki alt grup arasındaki fark: E3b(A=1) − E3b(A=0), aynı çekilişlerden hesaplanır (bu, kocanın durumu analizinden farklı olarak tek modelden gelen bir karşıtlıktır ve raporlanabilir); medyan, CrI ve P(fark > 0).
- Logit ölçeğinde A × δ_M etkileşim katsayısı ve CrI.
- Aynı şey A' ile (duyarlılık).

**Önceden ilan edilen ölçüt:** Zaman kanalı lehine yorum için |E3b(A=1)| < |E3b(A=0)| ve farkın %95 CrI'sinin sıfırı dışlaması gerekir. CrI sıfırı içeriyorsa sonuç "ayırt edemedi" diye yazılır; hiçbir yönde güçlü ifade kullanılmaz.

Çıktı: `Results/Supplementary/TableS21.csv/.docx`, `sayilar.json` → `zaman_kanali.X2`, tanılar Table S8'e eklenir.

---

## 4. Figure S6

Üç panel: (a) T1'den kadın TZE dağılımı (pay gruplarına göre, yatay kutu ya da nokta-aralık); (b) X1 eğrileri: kadın ve koca TZE'sine göre standartlaştırılmış olasılık (D çiftleri), 50/80/95 iç içe bantlar; (c) X2: E3b ve E4, A = 0 ve A = 1 için, ROPE bandıyla. Veriler `figur_verileri/`'ne yazılır, `figurler.py` çizer. Altyazı taslağı `figur_altyazilari.md`'ye eklenir; ^p işareti ve "post hoc, directions prespecified in the addendum of 1 November 2026" ifadesi altyazıda yer alır.

---

## 5. Figürlerin yeniden tasarımı (Figure 1–3, S1–S6)

Mevcut figürlerin içeriği ve panel düzeni korunur; **tipografi, renk ve işaretleme sıfırdan** kurulur. Bütün değişiklik `Codes/figur_stili.py` ve `figurler.py`'de yapılır; veri hesaplanmaz.

### 5.1. Yazı tipi

- Birincil: **Source Sans 3** (Adobe, SIL OFL). `~/Library/Fonts/` altına yüklenir (GitHub `adobe-fonts/source-sans` sürüm paketindeki OTF dosyaları); matplotlib font önbelleği yenilenir. Yüklenemezse ikinci seçenek **IBM Plex Sans** (OFL). İkisi de olmazsa Mac'teki **Gill Sans**. Seçilen yazı tipi raporda yazılır.
- Ağırlıklar: panel harfleri (a), (b) 600 (semibold); eksen başlıkları ve doğrudan etiketler 400; tik etiketleri 400; kaynak/dipnot satırı 400 gri.
- Boyutlar (son baskı genişliğinde, 170 mm iki sütun): panel harfi 11 pt, eksen başlığı 9 pt, tik 8 pt, doğrudan etiket 8,5 pt, lejant 8 pt. Hiçbir yazı 6,5 pt'nin altına inmez. Tek sütun figürlerde (85 mm) aynı pt değerleri.
- Sayılar: eksi işareti U+2212, binlik ayırıcı virgül, ondalık nokta (Amerikan İngilizcesi).

### 5.2. Palet (üç ana ton renk körlüğü denetiminden geçti: OKLab ΔE ≥ 13 deutan/protan, normal görüşte ≥ 21, beyaz zeminde kontrast ≥ 3:1; ton merdivenleri OKLab'da aynı tonda açıklık basamaklarıdır)

| Rol | Hex | Tonlar (açık → koyu) |
|---|---|---|
| Yalnız erkek kazanan (M) | `#B5651D` | `#F6D7C1` `#E5B18D` `#CC8650` `#B5651D` `#8C4300` |
| İki kazançlı (D) | `#0D968F` | `#C4E6E3` `#8FCBC6` `#4EAAA3` `#0D968F` `#00716B` |
| Yalnız kadın kazanan (F) | `#8C2D6C` | `#F8D1E7` `#E7A7CC` `#CD77AB` `#8C2D6C` `#640649` |
| Mürekkep (metin, eksen) | `#2B2B2B` | — |
| Sessiz metin, dipnot | `#6B6B6B` | — |
| Izgara | `#E6E6E6` | — |
| ROPE bandı | `#F1ECE2` | — |
| Referans çizgileri (sıfır, M2 medyanı) | `#9A9A9A` kesikli | — |

Kurallar: bir kategori her figürde aynı rengi ve aynı işaretçiyi taşır (M kare, D daire, F elmas; içi dolu). Pay bantlarında (Figure S3b gibi sıralı gruplar) D'nin ton merdiveni açıktan koyuya kullanılır. † işaretli karşılaştırmalar (E1, E2, E3a) **içi boş** işaretçiyle çizilir; E3b ve E4 dolu. Hiçbir bilgi yalnız renkle verilmez: doğrudan etiket ya da işaretçi biçimi eşlik eder. Dört renkli kategori gerekmez; gerekirse sor.

Yeni paleti kaydettikten sonra Python'da `colorspacious` (`pip install colorspacious`, yalnız sanal ortama) ile deuteranopi, protanopi ve gri ton simülasyonu yapılır; her figürün simüle edilmiş kopyası `Figures/kontrol/` altına yazılır ve raporda "okunabilir" diye onaylanır.

### 5.3. Aralıkların tonlanması

- Eğri bantları (Figure 2a, S6b): iç içe %50, %80 ve %95 bantları; seri renginin alfa 0,45 / 0,28 / 0,14 tonları; medyan çizgisi 1,8 pt. Lejantta "50/80/95% credible bands" tek öğe olarak.
- Nokta-aralık grafikleri (Figure 2b, 3, S4, S5, S6c): %95 aralığı 1 pt ince çizgi, %80 aralığı 2,6 pt kalın parça, medyan işaretçi ≥ 8 px; survey modeli için içi boş elmas ve kesikli çizgi korunur.
- Kutu/dağılım (Figure 2a'daki pay dağılımı, S6a): dolgu seri renginin açık tonu, kenar koyu tonu 0,8 pt.
- Posterior öngörü (S3): gözlenen değer mürekkep rengi daire, tahmin aralığı ilgili kategori tonu.

### 5.4. Düzen

- Üst ve sağ eksen çizgileri yok; sol ve alt eksen 0,8 pt `#2B2B2B`; yatay ızgara 0,5 pt `#E6E6E6`; tik dışa, 3 pt.
- Panel harfleri eksen alanının sol üstünde, panel başlığı harfin sağında aynı satırda.
- Lejant yerine ≤ 3 seri varsa doğrudan etiket; lejant gerekiyorsa figürün altında tek satır, çerçevesiz.
- Panel araları 10 mm; figür kenar boşluğu 2 mm; `constrained_layout`.
- Figure 1a (Sankey): akış renkleri gri tonları, son sütunda M/D/F renkleri; iç grafik (zincirler) D tonları. Figure 1b: kavram şeması aynı üç renk ve işaretçi.
- Üstte başlık yok; altyazı Word'de.

### 5.5. Çıktı

PNG 600 dpi, PDF (yazı tipi gömülü, Type 42), TIFF (LZW). Genişlik 170 mm (Figure 1–3, S3, S5, S6) ya da 85 mm (dar olanlar; mevcut genişlikler korunur). Her figür için küçük bir kontrol görüntüsü (`Figures/kontrol/<ad>_onizleme.png`, 150 dpi) üretilir.

---

## 6. Rapor, numaralandırma ve teslim

- Supplementary numaraları Word'de yazarlar tarafından değiştirildi: S13a → S13, S13b → S14, S14 → S15, S15 → S16, S16 → S17, S17 → S18. `analiz.R`'deki `ek_no` listesi buna göre güncellenir; **mevcut tablolar yeniden üretilmez** (Word'deki sürümler ana dosyadır). Yeni tablolar S19–S21, yeni figür S6.
- `Rapor.md`: Bölüm 1'e "Ek 1" günlüğü; Bölüm 2'ye yeni K maddeleri (sonuç sonrası işaretli, bu talimatın tarihi ve önceden ilan edilen yönlerle); Bölüm 8'e T1–T3 ana sayıları; Bölüm 9'a Methods notu (İngilizce, LaTeX; X1 ve X2 denklemleri, A tanımı, TZE tanımı); Bölüm 10'a zaman kanalı değerlendirmesi: hangi test ne buldu, mevcut karşı kanıtla birlikte dürüst yorum. Bölüm 12'ye sınırlılık: zaman kullanımı ve gıda harcaması ölçülmedi; FI150 görüşme anı.
- `sayilar.json`: `zaman_kanali` kökü; `docs/CHANGELOG.md` güncellenir.
- Süre: X1 ve X2 M2 ile aynı ayarlarda yaklaşık 10–12 dk; standartlaştırmalar birkaç dakika; figürler 1 dk. Başka ağır koşu yoksa toplam 1 saatin altında. Önbellek kuralları geçerli; yeni modeller yeni anahtarla.
- İç denetim: bir tur, bir hakem (yöntem ve sayılar); özellikle A tanımı, TZE'nin sıfır yığılması, standartlaştırma kümeleri (D çiftleri; A alt grupları) ve ^p işaretleri.
- Teslim: Table S19–S21 (csv + docx), Figure S6 ve yeniden tasarlanmış bütün figürler (PNG, PDF, TIFF), `Figures/kontrol/`, `figur_altyazilari.md` güncel, `Rapor.md`, `sayilar.json`, `CHANGELOG.md`. Yazarlara kısa bir tamamlama raporu: hangi yazı tipi kullanıldı, T1–T3 ana sayıları, önceden ilan edilen ölçütlere göre sonuç, sorular.

Sorular ve varsayılanlar "Bize sorular"a yazılır; durmadan devam edilir.
