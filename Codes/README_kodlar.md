# Kodlar: çalıştırma sırası, süreler, ortam

Bütün komutlar proje kökünden çalıştırılır. Göreli yollar proje köküne göredir.

## Sıra

1. `Rscript Codes/analiz.R`

   Tek giriş noktası. Sırasıyla:
   - **Okuma** (yalnız ilk çalıştırmada): `R_Data ve Python Data/GYKA_2023_2025_birlesik.xlsx` (bu bilgisayarda önceki çalışmanın klasöründeki dosyaya sembolik bağ); kökte bir kopya varsa o okunur. Tarif belgesi Bölüm 1.4, Okuma 1: `col_types = sozluk$okuma_turu`. Çıktılar: `R_Data ve Python Data/gyka_2023_2025.parquet` ve `.rds`, `sozluk.csv`, `kodlar.csv`, `dogrulama_sayfasi.csv`.
   - **Doğrulama:** `Results/dogrulama_kontrolleri.csv`; aynı ham dosyadan önceki çalışmada üretilen parquet dosyasıyla (`R_Data ve Python Data/onceki_calisma_gyka_2023_2025.parquet`, sembolik bağ; yoksa atlanır) değer düzeyinde karşılaştırma.
   - **Çiftin belirlenmesi:** FK240 eş bağları, referans çift, uygunluk, kazanç, pay, kazanan yapısı, kovaryatlar ve bayraklar.
   - **Bağlantı zincirleri:** üye imzası, çift anahtarı, reis anahtarı; öncelikli birleştirme. Kalite raporu `Results/denetim/baglanti_*`, `zincir_*`.
   - **Fizibilite:** `Results/denetim/fizibilite_*`; eksik veri ve kayıtsız eşli çiftler.
   - **Ortak destek:** ağırlıklı `nnet::multinom`, dikdörtgen destek; `R_Data ve Python Data/uygun_ciftler.parquet`, `analiz_Q.parquet`, `Results/spline_dugumleri.json`.
   - **Önsel öngörü denetimi** ve **pilot** (CPU ve OpenCL denemesi; pilot sonucu `Results/log/pilot_sureleri.csv` varsa tekrarlanmaz).
   - **M1, M2, M3** (brms + cmdstanr), tanılar (`Results/denetim/model_tanilari.csv`), model protokolü (`Results/model_protokolu.csv`), standartlaştırma (Gauss–Hermite marjinalleştirme), posterior öngörü denetimi.
   - **İkincil analizler:** kocanın durumu (F × durum), yıllara göre farklılaşma.
   - **Ek 1, zaman kanalı (sonuç sonrası; `docs/analysis_plan_addendum_TR.md`):** çalışma yoğunluğu (TZE = FI260 + 0,5 × FI270) betimlemesi (T1), çalışma yoğunluğu modeli X1 (T2, T2′) ve başka yetişkin modelleri X2, X2′ (T3). Düğümler `Results/denetim/tze_dugumleri.json`; sonuçlar `Results/zaman_kanali_X1.csv`, `zaman_kanali_X2.csv`, `sayilar.json` → `zaman_kanali`.
   - **Duyarlılıklar:** 30 Bayesçi model (C21 bütün katsayılarda geniş prior dahil), M2 çekilişlerinden çapa duyarlılığı (C19) ve survey modeli (zincir düzeyinde 1.000 bootstrap replikatı). Prior karşılaştırmaları ve E4 özdeşliği `Results/model_protokolu.csv`'de.
   - **Tablolar:** Table 1–2, Table S1–S21 (docx + csv), `Results/tablolar_tumu.xlsx`. Supplementary'nin ana dosyası Word'dedir (yazarlar); `EK1_YALNIZ=1 Rscript Codes/analiz.R` mevcut tabloları, STROBE notlarını ve `tablolar_tumu.xlsx`'i yazmaz, yalnız Table S19–S21'i ve `Results/tablolar_ek1.xlsx`'i yazar (dört sonuç sonrası modelin tanı satırları tam kipte Table S8'in sonundadır); sayılar, protokol ve figür verileri her iki kipte de güncellenir. `Codes/xlsx_simge.py` alt ve üst simgeleri gerçek biçime çevirir ve başlıklarda yalnız "Table X." kısmını kalın yazar. Ek tablo numaraları `analiz.R`'deki `ek_no` listesindedir.
   - **Diğer çıktılar:** figür verileri (`R_Data ve Python Data/figur_verileri/`), `Results/sayilar.json`, `paket_atiflari.txt`, `sessionInfo.txt`, `python_ortam.txt`, `strobe_akis.md`.

2. `~/veri-ortami/bin/python3 Codes/figurler.py`

   Bütün figürler `R_Data ve Python Data/figur_verileri/*.csv` dosyalarından çizilir; bu klasör yoksa (ör. arşivden açılan depoda) `Figures/figur_verileri/` altındaki kopyalar okunur. Figür kodu veri hesaplamaz.
   - Ana metin: Figure 1–3.
   - Ek: Figure S1 (ortak destek örtüşmesi), S2 (önsel öngörü ve σ_zincir), S3 (posterior öngörü denetimi), S4 (yıllar), S5 (örneklem ve tanım duyarlılıkları), S6 (zaman kanalı; Ek 1).
   - Tek figür: `python Codes/figurler.py 2` ya da `python Codes/figurler.py S3`.
   - Stil ve palet `Codes/figur_stili.py` (Ek 1 tasarımı: Source Sans 3, `~/Library/Fonts/` altında TTF sürümü 3.052R, SIL OFL; yoksa IBM Plex Sans, sonra Gill Sans); metin etiketleri `Codes/etiketler.json` (R tabloları da aynı dosyayı okur).
   - Her figür için `Figures/kontrol/<ad>_onizleme.png` (150 dpi) ve `colorspacious` ile döteranopi, protanopi ve gri ton kopyaları. Kayıtta yazı çakışması, figür sınırından ve eksen çizgisinden taşma ile 6,5 pt'nin altındaki yazılar denetlenir.

3. İsteğe bağlı: `~/veri-ortami/bin/python3 Codes/sayilar_karsilastir.py <eski sayilar.json> <yeni sayilar.json>`

   İki koşunun `sayilar.json` dosyalarını alan alan karşılaştırır (süre alanları hariç). Her bölüm için ortak alan sayısını, birebir aynı alanları ve en büyük sayısal farkı yazar. Temiz koşu denetiminde kullanıldı (`Rapor.md` Bölüm 13).

4. Arşiv paketi: `~/veri-ortami/bin/python3 Teslim/paket_olustur.py` (`Teslim/` arşive girmez)

   `Teslim/ilcs2023-2025-couple-earnings-meal-affordability_v1.0.0/` klasörünü ve aynı adlı zip'i kurar: kökte `README.md`, `LICENSE`, `.zenodo.json`, `CITATION.cff`; `Codes/`, `Results/`, `Figures/` (figür verilerinin kopyaları `Figures/figur_verileri/`), `docs/`. Günlüklerde ve ortam kayıtlarında kullanıcı yolu `~/` ile kısaltılır (yalnız paket kopyasında). Word tablolarının ve `tablolar_tumu.xlsx`'in belge bilgisindeki yazar `Teslim/belge_yazari.py` ile "Salim Yılmaz" yapılır (yalnız `dc:creator` ve `cp:lastModifiedBy`). Ardından `Codes/gizlilik_taramasi.py <paket klasörü> <çıktı> <inceleme.json>` (arşive girmez) paketi tarar (satır sayısı, tanımlayıcı benzeri sütun adları, 20'nin altındaki sayım hücreleri, ham dosya adı, TÜİK tanımlayıcı adları, kullanıcı yolu ve dergi adı; docx, xlsx, pdf ve png üst verisi dahil) ve `Teslim/arsiv_v1.0.0_dosya_listesi.tsv`'yi yazar; zip içeriği listeyle karşılaştırılır.

## Önbellekler (`R_Data ve Python Data/onbellek/`)

- `fit_<model>_<ayar özeti>.rds`: brms model nesneleri (hane düzeyinde veri içerir; yalnız burada). Ad, örnekleme ayarlarının (iterasyon, ısınma, tohum, adapt_delta, iş parçacığı, prior ölçekleri) özetini taşır. `file_refit = "on_change"`: Stan kodu ya da Stan verisi değişirse model yeniden kurulur; yeniden kurulum dosya zamanından algılanır ve süre yalnız o zaman yazılır. Zincir düzeyindeki etkilerin çekilişleri kaydedilmez (`save_pars(group = "ibbs2")`).
- `stan_csv/<model>_<ayar özeti>/`: M1–M3, kocanın durumu ve yıl sapmalı modelin CmdStan CSV'leri; zincir düzeyindeki bütün parametrelerin tanıları buradan, en son yazılan `chains` dosyadan okunur.
- `std_<model>_<özet>.rds`: standartlaştırılmış olasılıkların çekilişleri (çekiliş × senaryo).
- `ppc_<model>_<özet>.rds`: posterior öngörü denetimi özetleri.
- `survey_B11_<özet>.rds`: survey modelinin nokta tahmini ve 1.000 replikat.
- `oncel_ongoru_<özet>.rds`: önsel öngörü simülasyonu.
- `<özet>`: modelin çekiliş diliminden, hedef veriden, senaryolardan ve hesabı yapan fonksiyonların kodundan hesaplanan içerik özeti (`rlang::hash`); standartlaştırmada Gauss–Hermite düğümleri de anahtarda. Veri, senaryo ya da bu fonksiyonların kodu değişince yeni dosya üretilir, eski dosya kullanılmaz. Anahtarda olmayan yardımcı fonksiyonlar değişirse önbellek elle arşive taşınmalıdır; son temiz koşu boş önbellekle yapılır.
- `model_sureleri.csv`: model başına duvar saati süresi.

Tanım değişikliklerinde önbellekler kendiliğinden yenilenir; eski dosyalar arşive taşınabilir. Sıfırdan üretim için `onbellek/`, `figur_verileri/` ve `Results/` arşiv klasörüne taşınır.

## Tohumlar

- R genel: 20261028 (`set.seed`, betiğin başında).
- Önsel öngörü simülasyonu: 20261029.
- brms modelleri: 20261030 (bütün modeller); pilot: 20261031.
- Posterior öngörü denetimi: 20261032.
- Survey bootstrap replikatları: 20261033.

## Süreler (64 GB, 18 çekirdekli Mac)

- xlsx okuma 5 sn (temiz koşu; ilk geliştirme koşusunda 9,9 sn, tepe bellek 19,2 GB); Aşama 0'ın geri kalanı yaklaşık 1 dk.
- Bir Bayesçi model (18.868 hane-yılı, 4 × 2.500 iterasyon): yaklaşık 5 dk; ana metin modelleri (4 × 5.500 iterasyon) yaklaşık 10 dk.
- Kocanın durumu modeli (4 × 11.000) yaklaşık 21 dk; yıl sapmalı model (4 × 10.000, CSV'ler saklanarak) yaklaşık 19 dk; tek yıllık modeller (4 × 20.000, zincirsiz, yaklaşık 6.300 hane-yılı) 4 dk dolayında; bütün uygun haneler modeli A9 (42.566 hane-yılı, 4 × 5.500) yaklaşık 24 dk.
- M2 standartlaştırması (93 senaryo × 18.000 çekiliş, 17 işçi): yaklaşık 6 dk.
- Son temiz koşu (ham xlsx'ten, bütün önbellekler boş, 35 modelin hepsi sıfırdan; 29–30.10.2026) 4 sa 24 dk; figürler 5 sn. Bütün sayılar ve çıktı dosyaları önbellekli koşuyla birebir aynı çıktı. Önbellekten tam koşu 15–35 dk: önbellekler geçerliyse yaklaşık 15 dk (çoğu zincir düzeyi tanıların CmdStan CSV'lerinden okunması), standartlaştırma önbelleği yenilenince 31–34 dk (`log/tur5_kosusu.txt`, `tur5b_kosusu.txt`, `tur6_kosusu.txt`). Teslim paketi için tabloları yeniden yazan koşu 16,5 dk (`log/teslim_kosusu.txt`; hiçbir model kurulmadı). Figürler, önizlemeler dahil, yaklaşık 10 sn.

Son temiz çalıştırmanın süreleri `Rapor.md` Bölüm 13'te; ayrıntı `Results/log/analiz_sureleri.csv` ve `R_Data ve Python Data/onbellek/model_sureleri.csv`.

## Ortam

- R 4.6.1, Apple Accelerate BLAS; paket sürümleri `Results/sessionInfo.txt`.
- brms 2.23.0, cmdstanr 0.9.0 (Stan r-universe deposu), CmdStan 2.40.0 (`~/.cmdstan`), rstan 2.32.7 (brms model nesnesi için gerekli), posterior 1.7.0, survey 4.5, nnet 7.3.20, statmod 1.5.2.
- Python 3.13.16, `~/veri-ortami` (uv sanal ortamı); paketler `Results/python_ortam.txt`. `colorspacious` 1.1.2 yalnız bu ortama kuruldu.
- Xcode derleyicisi güncellenirse CmdStan'in önceden derlenmiş başlığı (`~/.cmdstan/cmdstan-2.40.0/stan/src/stan/model/model_header.hpp.gch`) eski derleyiciyle yapılmış kalır ve yeni modeller derlenmez ("PCH file built from a different branch"). Dizin kaldırılınca CmdStan ilk derlemede yenisini üretir (1 Kasım 2026'da yapıldı).
- Paralel hesap:
  - Stan'de 4 zincir × 4 iş parçacığı (`threading(4, static = TRUE)`, statik `reduce_sum`: aynı tohumla çekilişler bit düzeyinde aynı).
  - R'de `future::plan(multisession, workers = 17)`; işçilerde `VECLIB_MAXIMUM_THREADS = 1`. 18 çekirdeğin biri işletim sistemine bırakılır (kullanıcı tercihi).
- GPU: brms `opencl()` Apple GPU'sunda çalışmadı (`Results/log/opencl_tani.txt`); bütün hesaplar CPU'da.

## Veri güvenliği

Mikro veri ve hane düzeyindeki ara dosyalar yalnız `R_Data ve Python Data/` altında. `Results/` ve `Figures/` yalnız toplulaştırılmış çıktı içerir. TÜİK'in tahmin güvenilirliği önerisi (tarif belgesi Bölüm 2.4) gereği ağırlıksız n < 20 olan hücrelerde tahmin (yüzde, ortalama, olasılık) verilmez, 20–50 arası işaretlenir (tablolarda ^a); gizlenen hücre başka bir hücreden ya da tablodan geri hesaplanamasın diye tamamlayıcı gizleme yapılır (iç denetimde eklendi). `Results/denetim/fizibilite_*` dosyalarında 1–19 arası sayılar "<20" yazılır ve bu hücrelerin yüzdeleri verilmez; `fizibilite_pay_dagilimi.csv`'de n < 20 olan pay bölmesinin olay sayısı ve ağırlıklı payı, `zincir_HE090_oruntuleri.csv`'de 20'den az zincire dayanan satırların sayısı ve yüzdesi tablolardaki gibi "–" yazılır; geri hesaplanamasın diye en küçük komşu bölme ya da bağ türü de gizlenir (K25). Aynı hücreler `sayilar.json`'da boştur (null). Akış, eş bağı ve zincir denetim dosyalarındaki (`es_baglari_ozet.csv`, `zincir_reddedilen_baglar.csv`, `hg110_negatif_kurali.csv`) ve Table S2'deki sayımlar tahmin değildir, maskelenmez.
