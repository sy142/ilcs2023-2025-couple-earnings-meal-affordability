# STROBE (kesitsel çalışmalar) notları

Her madde için bu çalışmanın çıktılarında nerede karşılandığı. Makale metni yazarlarca yazılacaktır.

Maddeler 1–3 (başlık, özet, giriş), 18 (ana sonuçların özeti), 20 (yorum) ve 22 (finansman) makale metninde yazarlarca yazılır; burada yer almaz.

- 4 Tasarım: TÜİK GYKA 2023–2025 kesit mikro verileri, hane-yılı birimli havuzlanmış kesitsel analiz; rotasyonlu panel nedeniyle tekrar eden haneler bağlantı zincirleriyle modellendi (Rapor Bölüm 4).
- 5 Ortam: alan uygulaması 2023 ve 2024'te Mart–Temmuz, 2025'te Şubat–Haziran; gelirler önceki takvim yılına ait (tarif Bölüm 2.1).
- 6 Katılımcılar: reis ve FK240 ile karşılıklı-tekil bağlı eşi olan, iki eşi de 18+ ve en az biri 18–64 yaşında, iki eşin de bireysel kaydı olan, net kazançları negatif olmayan ve toplamı pozitif çiftler: 42.566 hane-yılı; ortak destek örneklemi 18.868 (Table S2, Figure 1a).
- 7 Değişkenler: sonuç HE090 (tek maddelik gıda yoksunluğu); maruziyet kazanan yapısı ve kadının payı; kovaryatlar ve türetilmiş değişkenler Table S1, `Results/degisken_tanimlari.csv`.
- 8 Veri kaynakları ve ölçüm: tarif ve inceleme raporu; HE090 hane anketinden, yanıtlayan kişi veride yok.
- 9 Yanlılık: ortak destek (Table S7, Figure S1), bağlantı kuralları ve ağırlık duyarlılıkları (Table S10 ve Table S11), eksik veri (Table S6).
- 10 Örneklem büyüklüğü: önceden belirlenmiş fizibilite kuralları (köşe ≥ 200 hane, ≥ 50 olay ve olay olmayan; çapa ≥ 200 hane); 0,85–0,95 çapasında 74 hane, kural sağlanmadı (Rapor Bölüm 5).
- 11 Nicel değişkenler: gelirler yıl medyanına oran ve asinh dönüşümüyle; spline düğümleri `Results/spline_dugumleri.json`.
- 12a İstatistik yöntemler: ağırlıklı Bayesçi lojistik model (brms/Stan), İBBS-2 ve bağlantı zinciri düzeyleri, Gauss–Hermite marjinalleştirmeli standartlaştırma, ROPE ±2 puan (Rapor Bölüm 9).
- 12b Alt gruplar ve etkileşimler: yalnız kadının kazandığı çiftlerde kocanın gelir yılındaki durumu (Table S17, Figure 3a); her durum kendi çiftleri üzerinden standartlaştırıldı, durumlar arasında karşıtlık hesaplanmadı. Yıla özgü sapmalar (Table S18, Figure S4).
- 12c Eksik veri: model değişkenlerinde uygun örneklemde eksik yok; tam vaka. Kayıtsız eşli 51 çift dışlandı ve karşılaştırıldı (Table S6).
- 12d Örnekleme stratejisi: HB040 ağırlıkları olabilirlikte (pseudo-posterior); tabaka ve PSU yayımlanmıyor; survey modeli zincir kümeli bootstrap ile (Table S10).
- 12e Duyarlılık analizleri: örneklem, dönem, tahmin yaklaşımı ve tanım varyantları; sonuç sonrası eklenenler işaretli (Table S10 ve Table S11, Figure 3b ve S5).
- 13 Katılımcı akışı: Figure 1a ve Table S2. Anketin görüşme tamamlama oranı (görüşülen / ziyaret edilen hane) 2023'te %89,6, 2024'te %94,6, 2025'te %94,0 (inceleme raporu Tablo 1 notu).
- 14 Tanımlayıcı veriler: Table 1 (Q), Table S13 ve Table S14 (bütün uygun ve Q dışı).
- 15 Sonuç verileri: Table S3 (yıl ve kazanan yapısına göre olay sayıları).
- 16 Ana sonuçlar: ham (ayarlanmamış) tahminler Table 1'deki ağırlıklı yaygınlıklardır. Ayarlanmış tahminler Table 2 ve Figure 2'de: M1 (gelir terimlerinden önce; ham değildir) ve M2.
- 17 Diğer analizler: Figure 3; Table S10, Table S11, Table S15, Table S16, Table S17 ve Table S18; Figure S4–S5.
- 19 Sınırlılıklar: tek maddelik sonuç; gelir yılı ile görüşme anının farklı olması; eşlerin gelir yılı boyunca birlikte yaşadığının doğrulanamaması; tabaka ve PSU bilgisinin olmaması; bağlantının resmî anahtara dayanmaması; ortak desteğin örneklemin yarısını dışlaması; 0,9 çapasının verinin dışında kalması ve E1, E2, E3a ile E3a,k'nın pay spline'ının dış değerine ve prior'ına bağlı olması (C20, C21); zincir içi aynı sonucun model tarafından eksik üretilmesi; sonuç sonrası eklenen analizler (tablolarda ^p); kocanın durumunda dört kategoriden yalnız birinde aralığın sıfırı dışlaması (çoklu karşılaştırma) (Rapor Bölüm 12).
- 21 Genellenebilirlik: ana tahminler ortak destek örneklemine (Q) aittir; Q, uygun örneklemden daha yaşlı, daha az küçük çocuklu ve doğu bölgelerinden az haneli bir nüfustur (Table S13 ve Table S14, Rapor Aşama 0c ve Bölüm 12). Bütün uygun hanelerle (A9) E3b ve E4 en çok 0,1 puan değişiyor; E2 ve E3a maddi ölçüte göre değişiyor (Table S11), aralıkları sıfırı kapsıyor.
