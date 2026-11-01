options(warn = 1, width = 160, datatable.print.nrows = 200, survey.lonely.psu = "adjust")
suppressPackageStartupMessages({
  library(data.table)
  library(arrow)
  library(readxl)
  library(jsonlite)
  library(splines)
  library(flextable)
  library(officer)
  library(openxlsx)
})
set.seed(20261028)
baslangic <- Sys.time()
ddir <- "R_Data ve Python Data"
for (k in c("Results/log", "Results/denetim", "Results/Supplementary", "Figures/Supplementary", file.path(ddir, "onbellek"), file.path(ddir, "figur_verileri"))) dir.create(k, showWarnings = FALSE, recursive = TRUE)
sink("Results/log/analiz_log.txt", split = TRUE)
cat("analiz.R başladı:", format(baslangic), "\n")
sureler <- list()
sure_ekle <- function(adim, t0, yer = "CPU") {
  sureler[[length(sureler) + 1]] <<- data.table(adim = adim, yer = yer, dakika = round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 2))
  invisible(NULL)
}

kaynak_xlsx <- if (file.exists("GYKA_2023_2025_birlesik.xlsx")) "GYKA_2023_2025_birlesik.xlsx" else file.path(ddir, "GYKA_2023_2025_birlesik.xlsx")
pq <- file.path(ddir, "gyka_2023_2025.parquet")
t0 <- Sys.time()
if (!file.exists(pq)) {
  s <- read_excel(kaynak_xlsx, sheet = "sozluk")
  d0 <- as.data.table(read_excel(kaynak_xlsx, sheet = "veri", col_types = s$okuma_turu))
  writeLines(format(round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1)), file.path(ddir, "okuma_suresi_sn.txt"))
  write_parquet(d0, pq)
  saveRDS(d0, file.path(ddir, "gyka_2023_2025.rds"))
  fwrite(s, file.path(ddir, "sozluk.csv"))
  fwrite(as.data.table(read_excel(kaynak_xlsx, sheet = "kodlar")), file.path(ddir, "kodlar.csv"))
  fwrite(as.data.table(read_excel(kaynak_xlsx, sheet = "dogrulama")), file.path(ddir, "dogrulama_sayfasi.csv"))
  rm(d0, s)
  invisible(gc())
}
sozluk <- fread(file.path(ddir, "sozluk.csv"))
kodlar <- fread(file.path(ddir, "kodlar.csv"))
d <- as.data.table(read_parquet(pq))
cat("Veri:", nrow(d), "satır,", ncol(d), "sütun; xlsx okuma süresi (sn):", readLines(file.path(ddir, "okuma_suresi_sn.txt")), "\n")
sure_ekle("okuma", t0)

t0 <- Sys.time()
dogr <- list()
kontrol <- function(ad, beklenen, bulunan, tol = 0, kaynak = "talimat") {
  durum <- if (is.numeric(beklenen) && is.numeric(bulunan)) {
    if (abs(bulunan - beklenen) <= tol + 1e-9) "Tuttu" else "Tutmadı"
  } else if (identical(as.character(beklenen), as.character(bulunan))) "Tuttu" else "Tutmadı"
  dogr[[length(dogr) + 1]] <<- data.table(kontrol = ad, kaynak = kaynak, beklenen = as.character(beklenen), bulunan = as.character(bulunan), durum = durum)
  invisible(NULL)
}
kontrol("Satır sayısı", 239985, nrow(d))
kontrol("Sütun sayısı", 266, ncol(d))
kontrol("Her hanede tek hane_reisi", 0L, d[, .(k = sum(hane_reisi == 1)), by = hane_kimlik][k != 1, .N])
hane_bek <- c("2023" = 24932, "2024" = 25925, "2025" = 25836)
fk240_bek <- c("2023" = 38531, "2024" = 39747, "2025" = 39494)
fkayit_bek <- c("2023" = 60222, "2024" = 61846, "2025" = 61812)
he090_bek <- list("2023" = c(15407, 9525), "2024" = c(15893, 10032), "2025" = c(15772, 10064))
for (yy in 2023:2025) {
  hy <- d[yil == yy & hane_reisi == 1]
  kontrol(paste(yy, "hane sayısı"), hane_bek[[as.character(yy)]], nrow(hy))
  kontrol(paste(yy, "FK240 dolu fert"), fk240_bek[[as.character(yy)]], d[yil == yy & !is.na(FK240), .N])
  kontrol(paste(yy, "f_kayit = 1 fert"), fkayit_bek[[as.character(yy)]], d[yil == yy & f_kayit == 1, .N], kaynak = "tarif")
  kontrol(paste(yy, "HB040 toplamı (milyon hane, 26,7–27,2)"), 26.95, round(hy[, sum(HB040)] / 1e6, 3), tol = 0.25)
  kontrol(paste(yy, "HE090 = 1 hane"), he090_bek[[as.character(yy)]][1], hy[HE090 == 1, .N], kaynak = if (yy == 2025) "talimat" else "tarif")
  kontrol(paste(yy, "HE090 = 2 hane"), he090_bek[[as.character(yy)]][2], hy[HE090 == 2, .N], kaynak = if (yy == 2025) "talimat" else "tarif")
  kontrol(paste(yy, "HE090 boş hane"), 0L, hy[is.na(HE090), .N], kaynak = "tarif")
}
kontrol("2023 TR63 hanesi", 0L, d[yil == 2023 & HB031 == "TR63" & hane_reisi == 1, .N])
kontrol("2024 TR63 hanesi", 695L, d[yil == 2024 & HB031 == "TR63" & hane_reisi == 1, .N], kaynak = "tarif")
kontrol("FK070 = gelir_yili − FK080", 0L, d[FK070 != gelir_yili - FK080, .N], kaynak = "tarif")
hg_bil <- c("FG010", "FG020", "FG030", "FG040", "FG070", "FG080", "FG085", "FG090", "FG100", "FG110", "FG120")
hh_bil <- c("HG010", "HG020", "HG030N", "HG030A", "HG040", "HG050N", "HG050A", "HG060N", "HG060A", "HG065N", "HG070", "HG080", "HG085", "HG105")
hh_dus <- c("HG090N", "HG090A", "HG095N", "HG100", "HG103")
sifir <- function(x) fifelse(is.na(x), 0, as.numeric(x))
fg_top <- d[, .(fg = sum(Reduce(`+`, lapply(.SD, sifir)))), by = hane_kimlik, .SDcols = hg_bil]
hg_kont <- merge(d[hane_reisi == 1, c("yil", "hane_kimlik", "HG110", hh_bil, hh_dus), with = FALSE], fg_top, by = "hane_kimlik")
hg_kont[, formul := fg + Reduce(`+`, lapply(.SD, sifir)), .SDcols = hh_bil]
hg_kont[, formul := formul - Reduce(`+`, lapply(.SD, sifir)), .SDcols = hh_dus]
hg_kont[, tutmayan := abs(formul - HG110) > 1]
hg_tut <- hg_kont[, .(tutmayan = sum(tutmayan), negatif_formul = sum(tutmayan & formul < 0)), keyby = yil]
for (yy in 2023:2025) kontrol(paste(yy, "HG110 formülü tutmayan hane (negatif gelir kuralı)"), c(28, 5, 15)[yy - 2022], hg_tut[yil == yy, tutmayan], kaynak = "tarif")
kontrol("HG110 formülünü tutmayanların tamamı formülle negatif", 0L, hg_tut[, sum(tutmayan - negatif_formul)], kaynak = "tarif")
n1_pq <- file.path(ddir, "onceki_calisma_gyka_2023_2025.parquet")
n1_karsilastirma <- NULL
if (file.exists(n1_pq)) {
  d1 <- as.data.table(read_parquet(n1_pq))
  ayni_sira <- identical(d$fert_kimlik, d1$fert_kimlik)
  ortak <- intersect(names(d), names(d1))
  fark <- ortak[!vapply(ortak, function(v) isTRUE(all.equal(d[[v]], d1[[v]], tolerance = 0, check.attributes = FALSE)), NA)]
  tur_fark <- ortak[vapply(ortak, function(v) !identical(class(d[[v]]), class(d1[[v]])), NA)]
  n1_karsilastirma <- data.table(satir_bu = nrow(d), satir_n1 = nrow(d1), sutun_bu = ncol(d), sutun_n1 = ncol(d1), ad_ayni = identical(names(d), names(d1)), sira_ayni = ayni_sira,
                                 deger_farkli_sutun = length(fark), tur_farkli_sutun = length(tur_fark))
  kontrol("Önceki çalışmanın parquet dosyası ile satır/sütun/ad aynı", "TRUE", as.character(n1_karsilastirma$ad_ayni && nrow(d) == nrow(d1) && ayni_sira), kaynak = "önceki çalışma")
  kontrol("Önceki çalışmanın parquet dosyası ile değeri farklı sütun", 0L, length(fark), kaynak = "önceki çalışma")
  kontrol("Önceki çalışmanın parquet dosyası ile türü farklı sütun", 0L, length(tur_fark), kaynak = "önceki çalışma")
  rm(d1)
  invisible(gc())
}
sure_ekle("doğrulama", t0)

t0 <- Sys.time()
d[, es_fid := fifelse(is.na(FK240), NA_real_, yil * 1e7 + FK240)]
gelen <- d[!is.na(es_fid), .(n_gelen = .N), by = .(fert_kimlik = es_fid)]
d[, n_gelen := 0L]
d[gelen, n_gelen := i.n_gelen, on = "fert_kimlik"]
es_tab <- d[, .(fert_kimlik, hane_kimlik, es_fid, FK095, FK090, n_gelen)]
d[es_tab, `:=`(es_es_fid = i.es_fid, es_hane = i.hane_kimlik, es_fk095 = i.FK095, es_fk090 = i.FK090, es_n_gelen = i.n_gelen), on = .(es_fid = fert_kimlik)]
d[, bag := fcase(is.na(es_fid) & n_gelen == 0L, "yok",
                 is.na(es_fid), "yalniz_gelen",
                 is.na(es_hane), "es_bulunamadi",
                 es_hane != hane_kimlik, "farkli_hane",
                 !is.na(es_es_fid) & es_es_fid == fert_kimlik & n_gelen == 1L & es_n_gelen == 1L, "karsilikli_tekil",
                 !is.na(es_es_fid) & es_es_fid == fert_kimlik, "karsilikli_coklu",
                 default = "karsilikli_degil")]
bag_ozet <- d[, .(FK240_dolu = sum(!is.na(FK240)), karsilikli_tekil_fert = sum(bag == "karsilikli_tekil"), karsilikli_degil_fert = sum(bag == "karsilikli_degil"),
                  karsilikli_coklu_fert = sum(bag == "karsilikli_coklu"), yalniz_gelen_fert = sum(bag == "yalniz_gelen"), es_bulunamadi = sum(bag %in% c("es_bulunamadi", "farkli_hane")),
                  birden_cok_gelen_bag_fert = sum(n_gelen > 1L), es_18_alti_fert = sum(!is.na(FK240) & FK070 < 18)), keyby = yil]
hane_bag <- d[, .(n_cift = sum(bag == "karsilikli_tekil") / 2, karsiliksiz = any(bag %in% c("karsilikli_degil", "yalniz_gelen")), coklu = any(n_gelen > 1L)), by = .(yil, hane_kimlik)]
bag_ozet <- merge(bag_ozet, hane_bag[, .(karsiliksiz_bagli_hane = sum(karsiliksiz), cok_eslilik_hane = sum(coklu), cok_ciftli_hane = sum(n_cift >= 2), cift_sayisi_toplam = sum(n_cift)), keyby = yil], by = "yil")
print(bag_ozet)
kontrol("Karşılıklı olmayan eş bağı (fert, üç yıl)", 44L, d[bag %in% c("karsilikli_degil", "yalniz_gelen") & !is.na(es_fid), .N], kaynak = "tarif")
kontrol("Eşi kayıtlı 18 yaş altı fert", 31L, d[!is.na(FK240) & FK070 < 18, .N], kaynak = "tarif")
fwrite(bag_ozet, "Results/denetim/es_baglari_ozet.csv")

reis <- d[hane_reisi == 1, .(yil, hane_kimlik, reis_fid = fert_kimlik, reis_es = es_fid, reis_bag = bag, reis_cins = FK090, reis_ngelen = n_gelen, es_fk095, es_fk090)]
reis[, cift_durum := fcase(reis_bag == "karsilikli_tekil" & es_fk095 == 2 & reis_cins != es_fk090, "cift",
                           reis_bag == "karsilikli_tekil" & es_fk095 == 2, "ayni_cinsiyet",
                           reis_bag == "karsilikli_tekil", "es_fk095_2_degil",
                           reis_bag == "yok", "es_yok",
                           default = "belirsiz_bag")]
print(reis[, .N, keyby = .(yil, cift_durum)])
ki_deg <- c("FK070", "FK075", "FK080", "FK090", "FK095", "f_kayit", "FE030", "FG010", "FG020", "FG030", "FG040", "FG080", "FG110", "FI010", "FI120", "FI150",
            "FI260", "FI270", "FI280", "FI290", "FI300", "FI310", "FS020", "FS030", "bag")
ki <- d[, c("fert_kimlik", ki_deg), with = FALSE]
ki[, E := fifelse(f_kayit == 1, sifir(FG010) + sifir(FG020) + sifir(FG030) + sifir(FG040), NA_real_)]
ki[, mutesebbis := fifelse(f_kayit == 1, sifir(FG030) + sifir(FG040), NA_real_)]
ki[, u := sprintf("%04d%02d%d", as.integer(FK080), as.integer(FK075), as.integer(FK090))]
cf <- reis[cift_durum == "cift"]
cf[, `:=`(k_fid = fifelse(reis_cins == 2, reis_fid, reis_es), e_fid = fifelse(reis_cins == 1, reis_fid, reis_es))]
ki_k <- copy(ki)
setnames(ki_k, setdiff(names(ki_k), "fert_kimlik"), paste0("k_", setdiff(names(ki_k), "fert_kimlik")))
ki_e <- copy(ki)
setnames(ki_e, setdiff(names(ki_e), "fert_kimlik"), paste0("e_", setdiff(names(ki_e), "fert_kimlik")))
cf <- merge(cf, ki_k, by.x = "k_fid", by.y = "fert_kimlik")
cf <- merge(cf, ki_e, by.x = "e_fid", by.y = "fert_kimlik")
stopifnot(all(cf$k_FK090 == 2), all(cf$e_FK090 == 1))

h <- d[hane_reisi == 1, .(yil, gelir_yili, hane_kimlik, HB040, HB030, HB031, HH010, HH020, HE090, HG110, HG010, hane_buyuklugu, goreli_esdeger_gelir)]
bil <- d[, .(n_0_5 = sum(FK070 <= 5), n_6_13 = sum(FK070 >= 6 & FK070 <= 13), n_14_17 = sum(FK070 >= 14 & FK070 <= 17),
             n_18_64 = sum(FK070 >= 18 & FK070 <= 64), n_65 = sum(FK070 >= 65)), by = hane_kimlik]
h <- merge(h, bil, by = "hane_kimlik")
h <- merge(h, reis[, .(hane_kimlik, reis_cins, cift_durum)], by = "hane_kimlik")
h <- merge(h, hane_bag[, .(hane_kimlik, n_cift)], by = "hane_kimlik")
h <- merge(h, cf[, setdiff(names(cf), c("yil", "reis_fid", "reis_es", "reis_bag", "reis_cins", "reis_ngelen", "es_fk095", "es_fk090", "cift_durum")), with = FALSE], by = "hane_kimlik", all.x = TRUE)
agirlikli_medyan <- function(x, w) {
  o <- order(x)
  x[o][which(cumsum(w[o]) / sum(w) >= 0.5)[1]]
}
m_t <- h[, .(m_t = agirlikli_medyan(HG110, HB040)), keyby = yil]
print(m_t)
h <- merge(h, m_t, by = "yil")
ref_dis <- d[bag == "karsilikli_tekil", .(hane_kimlik, fert_kimlik, f_kayit, E = fifelse(f_kayit == 1, sifir(FG010) + sifir(FG020) + sifir(FG030) + sifir(FG040), NA_real_))]
ref_dis <- merge(ref_dis, h[!is.na(k_fid), .(hane_kimlik, k_fid, e_fid)], by = "hane_kimlik")
ref_dis <- ref_dis[fert_kimlik != k_fid & fert_kimlik != e_fid, .(E_refdisi = sum(E, na.rm = TRUE), refdisi_kayit_eksik = any(f_kayit != 1)), by = hane_kimlik]
h <- merge(h, ref_dis, by = "hane_kimlik", all.x = TRUE)
h[is.na(E_refdisi) & !is.na(k_fid), E_refdisi := 0]

h[, Y := as.integer(HE090 == 2)]
h[, `:=`(E_k = k_E, E_e = e_E)]
h[, dislama := fcase(cift_durum == "es_yok", "1a_referans_cift_yok_es_yok",
                     cift_durum != "cift", "1b_belirsiz_es_bagi",
                     k_FK070 < 18 | e_FK070 < 18, "2a_es_18_alti",
                     !(k_FK070 <= 64 | e_FK070 <= 64), "2b_iki_es_65_ustu",
                     k_f_kayit != 1 | e_f_kayit != 1, "3_bireysel_kayit_eksik",
                     E_k < 0 | E_e < 0, "4_negatif_net_kazanc",
                     E_k + E_e <= 0, "5_kazanc_yok",
                     default = "uygun")]
h[, uygun := as.integer(dislama == "uygun")]
h[, uygun_tumyas := as.integer(dislama %in% c("uygun", "2b_iki_es_65_ustu") & cift_durum == "cift" & k_FK070 >= 18 & e_FK070 >= 18 &
                                 k_f_kayit == 1 & e_f_kayit == 1 & E_k >= 0 & E_e >= 0 & E_k + E_e > 0)]
print(h[, .N, keyby = .(yil, dislama)])
h[, s := fifelse(!is.na(E_k) & !is.na(E_e) & E_k + E_e > 0, E_k / (E_k + E_e), NA_real_)]
h[, G := fcase(is.na(s), NA_character_, E_k == 0 & E_e > 0, "M", E_k > 0 & E_e == 0, "F", E_k > 0 & E_e > 0, "D")]
h[, `:=`(E = E_k + E_e, O = HG110 - (E_k + E_e), O_izk = HG110 - sifir(HG010) - (E_k + E_e))]
h[, `:=`(aE = asinh(E / m_t), aO = asinh(O / m_t), aO_izk = asinh(O_izk / m_t), E_oran = E / m_t, O_oran = O / m_t, a_esd = asinh(goreli_esdeger_gelir))]
h[, `:=`(n_diger_18_64 = n_18_64 - (k_FK070 >= 18 & k_FK070 <= 64) - (e_FK070 >= 18 & e_FK070 <= 64), n_diger_65 = n_65 - (k_FK070 >= 65) - (e_FK070 >= 65))]
egitim5 <- function(x) fcase(x %in% 0:1, 1L, x %in% 2:3, 2L, x == 4, 3L, x %in% 5:6, 4L, x %in% 7:10, 5L)
h[, `:=`(k_egitim = egitim5(k_FE030), e_egitim = egitim5(e_FE030), k_yas = k_FK070, e_yas = e_FK070)]
h[, `:=`(k_kisit = as.integer(k_FS030 %in% 1:2), e_kisit = as.integer(e_FS030 %in% 1:2), k_kronik = as.integer(k_FS020 == 1), e_kronik = as.integer(e_FS020 == 1))]
h[is.na(k_FS030), k_kisit := NA_integer_][is.na(e_FS030), e_kisit := NA_integer_][is.na(k_FS020), k_kronik := NA_integer_][is.na(e_FS020), e_kronik := NA_integer_]
h[, mulkiyet := factor(HH020, levels = 1:4, labels = c("sahip", "kiraci", "lojman", "kirasiz"))]
h[, `:=`(k_ucretsiz_aile = as.integer(sifir(k_FI120) == 5), e_ucretsiz_aile = as.integer(sifir(e_FI120) == 5))]
h[, ucret_ornegi := as.integer(sifir(k_FG030) == 0 & sifir(k_FG040) == 0 & sifir(e_FG030) == 0 & sifir(e_FG040) == 0)]
h[, `:=`(k_calisma_ay = k_FI260 + k_FI270, e_calisma_ay = e_FI260 + e_FI270)]
h[, `:=`(k_simdi_calisiyor = as.integer(k_FI010 %in% 1:4), e_simdi_calisiyor = as.integer(e_FI010 %in% 1:4))]
h[, durum_uyumu := as.integer(fcase(G == "M", e_simdi_calisiyor == 1 & k_simdi_calisiyor == 0,
                                    G == "D", e_simdi_calisiyor == 1 & k_simdi_calisiyor == 1,
                                    G == "F", e_simdi_calisiyor == 0 & k_simdi_calisiyor == 1, default = NA))]
h[, e_durum_gy := {
  a <- cbind(e_FI290, e_FI280, e_FI310 + e_FI300, e_FI260 + e_FI270)
  ii <- max.col(a, ties.method = "first")
  fifelse(is.na(a[, 1]), NA_character_, fifelse(rowSums(a) == 0, "belirsiz", c("emekli", "issiz", "diger_faal_olmayan", "calisti_kazancsiz")[ii]))
}]
h[, `:=`(e_emekli_ayligi = as.integer(sifir(e_FG080) > 0), e_malulen = as.integer(sifir(e_FG110) > 0), e_kazancsiz_calisma = as.integer(e_calisma_ay > 0 & E_e == 0),
         k_kazancsiz_calisma = as.integer(k_calisma_ay > 0 & E_k == 0))]
h[, tek_cift := as.integer(n_cift == 1)]
h[, `:=`(k_tze = k_FI260 + 0.5 * k_FI270, e_tze = e_FI260 + 0.5 * e_FI270)]
diger_yet <- merge(d[FK070 >= 18, .(hane_kimlik, fert_kimlik, f_kayit, FI010)], h[!is.na(k_fid), .(hane_kimlik, k_fid, e_fid)], by = "hane_kimlik")[fert_kimlik != k_fid & fert_kimlik != e_fid]
diger_yet <- diger_yet[, .(yet_A = as.integer(any(f_kayit == 1 & !(FI010 %in% 1:4))), yet_Ap = 1L, yet_kayitsiz = sum(f_kayit != 1)), by = hane_kimlik]
h[, `:=`(yet_A = 0L, yet_Ap = 0L, yet_kayitsiz = 0L)]
h[diger_yet, on = "hane_kimlik", `:=`(yet_A = i.yet_A, yet_Ap = i.yet_Ap, yet_kayitsiz = i.yet_kayitsiz)]
h[, ibbs1 := factor(HB030)]
h[, ibbs2 := factor(HB031)]
h[, yil_f := factor(yil)]
refdisi_rapor <- h[cift_durum == "cift" & k_f_kayit == 1 & e_f_kayit == 1, .(cok_ciftli_hane = sum(n_cift >= 2), ref_kazanc_yok_refdisi_kazaniyor = sum(n_cift >= 2 & E_k + E_e == 0 & E_refdisi > 0)), keyby = yil]
print(refdisi_rapor)
fwrite(refdisi_rapor, "Results/denetim/referans_disi_cift.csv")
sure_ekle("çift ve uygunluk", t0)

t0 <- Sys.time()
imza_dt <- d[hane_buyuklugu > 1, .(yil, hane_kimlik, u = sprintf("%04d%02d%d", as.integer(FK080), as.integer(FK075), as.integer(FK090)))][order(yil, hane_kimlik, u)][, .(anahtar = paste(u, collapse = "-")), by = .(yil, hane_kimlik)]
cift_dt <- h[!is.na(k_fid) & hane_buyuklugu > 1, .(yil, hane_kimlik, anahtar = paste(k_u, e_u, HB031, sep = "_"))]
reis_dt <- merge(d[hane_reisi == 1 & hane_buyuklugu > 1, .(yil, hane_kimlik, r_u = sprintf("%04d%02d%d", as.integer(FK080), as.integer(FK075), as.integer(FK090)))],
                 h[, .(hane_kimlik, HB031, HH010, HH020)], by = "hane_kimlik")[, .(yil, hane_kimlik, anahtar = paste(r_u, HB031, HH010, HH020, sep = "_"))]
yil_ciftleri <- list(c(2023, 2024), c(2024, 2025), c(2023, 2025))
esle_anahtar <- function(dt, yontem) {
  dt <- copy(dt)[, n := .N, by = .(yil, anahtar)][n == 1L]
  rbindlist(lapply(yil_ciftleri, function(yp) {
    m <- merge(dt[yil == yp[1], .(anahtar, h1 = hane_kimlik)], dt[yil == yp[2], .(anahtar, h2 = hane_kimlik)], by = "anahtar")
    m[, .(y1 = yp[1], y2 = yp[2], h1, h2, yontem = yontem)]
  }))
}
bag_ham <- rbind(esle_anahtar(imza_dt, "imza"), esle_anahtar(cift_dt, "cift"), esle_anahtar(reis_dt, "reis"))
bag_genis <- dcast(bag_ham, y1 + y2 + h1 + h2 ~ yontem, fun.aggregate = length, value.var = "yontem")
for (k in c("imza", "cift", "reis")) set(bag_genis, j = k, value = as.integer(bag_genis[[k]] > 0))
bag_genis[, tur := fcase(imza == 1 & cift == 1, "imza_ve_cift", imza == 1, "yalniz_imza", cift == 1, "yalniz_cift", default = "yalniz_reis")]
zincir_kur <- function(baglar, hane_id, hane_yil) {
  b <- copy(baglar)
  b[, oncelik := fcase(imza == 1 & cift == 1, 1L, imza == 1, 2L, cift == 1, 3L, default = 4L) * 10L + (y2 - y1)]
  setorder(b, oncelik, y1, y2, h1, h2)
  n <- length(hane_id)
  ebeveyn <- seq_len(n)
  maske <- c(1L, 2L, 4L)[hane_yil - 2022L]
  bul <- function(x) {
    while (ebeveyn[x] != x) x <- ebeveyn[x]
    x
  }
  i1 <- match(b$h1, hane_id)
  i2 <- match(b$h2, hane_id)
  kabul <- logical(nrow(b))
  for (r in seq_len(nrow(b))) {
    a1 <- bul(i1[r])
    a2 <- bul(i2[r])
    if (a1 == a2) {
      kabul[r] <- TRUE
    } else if (bitwAnd(maske[a1], maske[a2]) == 0L) {
      ebeveyn[a2] <- a1
      maske[a1] <- bitwOr(maske[a1], maske[a2])
      kabul[r] <- TRUE
    }
  }
  kok <- vapply(seq_len(n), bul, 0L)
  b[, kabul := kabul]
  list(zincir = hane_id[kok], baglar = b)
}
hane_tum <- h[, .(hane_kimlik, yil)]
kural_tanim <- list(ana = c("imza", "cift"), imza = "imza", ana_reis = c("imza", "cift", "reis"), ana_bolge = c("imza", "cift"))
bag_genis[, bolge_ayni := h$HB031[match(h1, h$hane_kimlik)] == h$HB031[match(h2, h$hane_kimlik)]]
zincirler <- list()
red_ozet <- list()
for (kr in names(kural_tanim)) {
  kb <- bag_genis[Reduce(`|`, lapply(kural_tanim[[kr]], function(k) get(k) == 1L))]
  if (kr == "ana_bolge") kb <- kb[!(imza == 1L & cift == 0L & !bolge_ayni)]
  if (kr != "ana_reis") kb[, reis := 0L]
  if (kr == "imza") kb[, cift := 0L]
  z <- zincir_kur(kb, hane_tum$hane_kimlik, hane_tum$yil)
  zincirler[[kr]] <- z
  set(h, j = paste0("zincir_", kr), value = z$zincir[match(h$hane_kimlik, hane_tum$hane_kimlik)])
  red_ozet[[kr]] <- z$baglar[, .(bag = .N, reddedilen = sum(!kabul)), keyby = .(y1, y2)][, kural := kr]
}
red_ozet <- rbindlist(red_ozet)
print(red_ozet)
fwrite(red_ozet, "Results/denetim/zincir_reddedilen_baglar.csv")
sure_ekle("bağlantı zincirleri", t0)

t0 <- Sys.time()
wq <- function(x, w, p) {
  o <- order(x)
  cw <- cumsum(w[o]) / sum(w)
  vapply(p, function(pp) x[o][which(cw >= pp - 1e-12)[1]], 0)
}
kish <- function(w) sum(w)^2 / sum(w^2)
hv <- h[, .(hane_kimlik, HB031, HH010, HH020, k_FE030, e_FE030, hane_buyuklugu)]
bag_kalite <- merge(bag_genis, setnames(copy(hv), c("h1", paste0(names(hv)[-1], "_1"))), by = "h1")
bag_kalite <- merge(bag_kalite, setnames(copy(hv), c("h2", paste0(names(hv)[-1], "_2"))), by = "h2")
anahtar_icerik <- c(imza_ve_cift = "hane büyüklüğü (imza); HB031 (çift anahtarı)", yalniz_imza = "hane büyüklüğü", yalniz_cift = "HB031", yalniz_reis = "HB031, HH010, HH020")
bag_kalite_ozet <- bag_kalite[, .(bag = .N, HB031_ayni = round(100 * mean(HB031_1 == HB031_2), 1), HH010_ayni = round(100 * mean(HH010_1 == HH010_2), 1),
                                  HH020_ayni = round(100 * mean(HH020_1 == HH020_2), 1), hane_buyuklugu_ayni = round(100 * mean(hane_buyuklugu_1 == hane_buyuklugu_2), 1),
                                  egitim_karsilastirilabilen = sum(!is.na(k_FE030_1) & !is.na(k_FE030_2) & !is.na(e_FE030_1) & !is.na(e_FE030_2)),
                                  iki_esin_egitimi_ayni = round(100 * mean((k_FE030_1 == k_FE030_2 & e_FE030_1 == e_FE030_2)[!is.na(k_FE030_1) & !is.na(k_FE030_2) & !is.na(e_FE030_1) & !is.na(e_FE030_2)]), 1)),
                              keyby = .(y1, y2, tur)]
bag_kalite_ozet[, anahtardaki_degisken := anahtar_icerik[tur]]
print(bag_kalite_ozet)
fwrite(bag_kalite_ozet, "Results/denetim/baglanti_kalitesi.csv")
eslesme_sayi <- bag_genis[, .(imza = sum(imza), cift = sum(cift), reis = sum(reis), ana_kural = sum(imza | cift), yalniz_imza = sum(imza & !cift), yalniz_cift = sum(cift & !imza),
                              imza_ve_cift = sum(imza & cift), ana_artı_reis = sum(imza | cift | reis), reis_ile_eklenen = sum(reis & !imza & !cift)), keyby = .(y1, y2)]
eslesme_sayi[, inceleme_raporu_imza := c(12924, 7432, 13396)[match(paste(y1, y2), c("2023 2024", "2023 2025", "2024 2025"))]]
print(eslesme_sayi)
for (i in seq_len(nrow(eslesme_sayi))) kontrol(paste0("İmza eşleşmesi ", eslesme_sayi$y1[i], "–", eslesme_sayi$y2[i]), eslesme_sayi$inceleme_raporu_imza[i], eslesme_sayi$imza[i], kaynak = "inceleme raporu")
fwrite(eslesme_sayi, "Results/denetim/baglanti_eslesme_sayilari.csv")

u <- h[uygun == 1]
zincir_uzunluk <- rbindlist(lapply(names(kural_tanim), function(kr) {
  zc <- paste0("zincir_", kr)
  rbind(h[, .N, by = zc][, .(kayit = N)][, .(zincir = .N), keyby = kayit][, `:=`(kural = kr, orneklem = "tüm haneler")],
        u[, .N, by = zc][, .(kayit = N)][, .(zincir = .N), keyby = kayit][, `:=`(kural = kr, orneklem = "uygun çiftler")])
}))
print(dcast(zincir_uzunluk, kural + orneklem ~ kayit, value.var = "zincir"))
fwrite(zincir_uzunluk, "Results/denetim/zincir_uzunluklari.csv")
for (kr in names(kural_tanim)) {
  zc <- paste0("zincir_", kr)
  h[, (paste0("zn_tum_", kr)) := .N, by = zc]
  u[, (paste0("zn_tum_", kr)) := h[match(u$hane_kimlik, h$hane_kimlik)][[paste0("zn_tum_", kr)]]]
  u[, (paste0("zn_uyg_", kr)) := .N, by = zc]
}
eslesme_G <- u[, .(hane = .N, herhangi_yila_bagli = round(100 * mean(zn_tum_ana > 1), 1), uygun_kayda_bagli = round(100 * mean(zn_uyg_ana > 1), 1),
                   uygun_kayda_bagli_imza = round(100 * mean(zn_uyg_imza > 1), 1), uygun_kayda_bagli_ana_reis = round(100 * mean(zn_uyg_ana_reis > 1), 1)), keyby = .(yil, G)]
print(eslesme_G)
fwrite(eslesme_G, "Results/denetim/baglanti_orani_G.csv")
dogrudan_tur <- bag_genis[, .(cift_anahtar = paste(pmin(h1, h2), pmax(h1, h2)), tur)]
oruntu <- rbindlist(lapply(names(kural_tanim), function(kr) {
  zc <- paste0("zincir_", kr)
  z2 <- u[get(paste0("zn_uyg_", kr)) == 2L, .(Ysum = sum(Y), ha = min(hane_kimlik), hb = max(hane_kimlik)), by = zc]
  z2[, tur := dogrudan_tur$tur[match(paste(ha, hb), dogrudan_tur$cift_anahtar)]]
  z2[is.na(tur), tur := "dolayli"]
  z2[, oruntu := c("00", "01/10", "11")[Ysum + 1]]
  rbind(z2[, .N, keyby = oruntu][, `:=`(kural = kr, tur = "tümü")], z2[, .N, keyby = .(tur, oruntu)][, kural := kr], use.names = TRUE)
}))
oruntu[, yuzde := round(100 * N / sum(N), 1), by = .(kural, tur)]
print(dcast(oruntu, kural + tur ~ oruntu, value.var = c("N", "yuzde")))
or_top <- oruntu[tur != "tümü", .(top = sum(N)), by = .(kural, tur)][, gizle := top < 20 | (any(top < 20) & top == min(top[top >= 20])), by = kural]
oruntu_yayin <- copy(oruntu)[or_top[gizle == TRUE], on = .(kural, tur), `:=`(N = NA_integer_, yuzde = NA_real_)]
fwrite(oruntu_yayin, "Results/denetim/zincir_HE090_oruntuleri.csv", na = "–")
sure_ekle("bağlantı kalitesi", t0)

t0 <- Sys.time()
akis_yil <- h[, .N, keyby = .(dislama, yil)]
akis_yil <- dcast(akis_yil, dislama ~ yil, value.var = "N", fill = 0)
akis_yil[, toplam := `2023` + `2024` + `2025`]
print(akis_yil)
fwrite(akis_yil, "Results/denetim/fizibilite_orneklem_akisi.csv")
f1 <- rbind(u[, .(n = .N, olay = sum(Y), olay_yok = sum(1 - Y), w = sum(HB040), kish_n = kish(HB040)), keyby = .(yil = as.character(yil), G)],
            u[, .(n = .N, olay = sum(Y), olay_yok = sum(1 - Y), w = sum(HB040), kish_n = kish(HB040)), keyby = .(G)][, yil := "havuz"], use.names = TRUE)
f1[, agirlikli_pay := round(100 * w / sum(w), 2), by = yil][, kish_n := round(kish_n, 1)][, w := NULL]
print(f1)
fwrite(f1, "Results/denetim/fizibilite_yil_G.csv")
ud <- u[G == "D"]
f2_q <- data.table(yuzdelik = c(0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.975, 0.99))
f2_q[, s := round(wq(ud$s, ud$HB040, yuzdelik), 4)]
print(f2_q)
fwrite(f2_q, "Results/denetim/fizibilite_pay_yuzdelikleri.csv")
ud[, kutu := cut(s, seq(0, 1, 0.05), include.lowest = TRUE)]
f2_h <- ud[, .(n = .N, olay = sum(Y), agirlikli_pay = sum(HB040)), keyby = kutu][, agirlikli_pay := round(100 * agirlikli_pay / sum(agirlikli_pay), 2)]
f2_h[, gizle := n < 20 | (any(n < 20) & n == min(n[n >= 20]))]
fwrite(f2_h[, .(kutu, n, olay = replace(olay, gizle, NA), agirlikli_pay = replace(agirlikli_pay, gizle, NA))], "Results/denetim/fizibilite_pay_dagilimi.csv", na = "–")
capa <- data.table(capa = c("D_dusuk", "D_orta", "D_yuksek"), alt = c(0.05, 0.45, 0.85), ust = c(0.15, 0.55, 0.95))
f2_c <- capa[, {
  x <- ud[s >= alt & s <= ust]
  .(n = nrow(x), olay = sum(x$Y), olay_yok = sum(1 - x$Y), kish_n = round(kish(x$HB040), 1))
}, by = .(capa, alt, ust)]
print(f2_c)
fwrite(f2_c, "Results/denetim/fizibilite_capa_destegi.csv")
uf <- u[G == "F"]
f4 <- rbind(uf[, .(n = .N, w = sum(HB040)), keyby = .(kategori = e_durum_gy)][, siniflama := "gelir_yili"],
            uf[, .(n = .N, w = sum(HB040)), keyby = .(kategori = as.character(e_FI010))][, siniflama := "guncel_FI010"])
f4[, agirlikli_yuzde := round(100 * w / sum(w), 1), by = siniflama][, w := NULL]
print(f4)
f4_capraz <- dcast(uf[, .N, keyby = .(e_durum_gy, e_FI010)], e_durum_gy ~ e_FI010, value.var = "N", fill = 0)
print(f4_capraz)
f4_bayrak <- uf[, .(n = .N, emekli_ayligi = sum(e_emekli_ayligi), malulen = sum(e_malulen), kazancsiz_calisma = sum(e_kazancsiz_calisma)), keyby = e_durum_gy]
print(f4_bayrak)
f4_ucretsiz <- u[, .(n = .N, kadin_ucretsiz_aile = sum(k_ucretsiz_aile), erkek_ucretsiz_aile = sum(e_ucretsiz_aile), en_az_biri = sum(k_ucretsiz_aile | e_ucretsiz_aile),
                     ucret_ornegi = sum(ucret_ornegi), durum_uyumlu = sum(durum_uyumu, na.rm = TRUE), tek_cift = sum(tek_cift),
                     kadin_kazancsiz_calisma = sum(k_kazancsiz_calisma), erkek_kazancsiz_calisma = sum(e_kazancsiz_calisma)), keyby = G]
print(f4_ucretsiz)
say_maske <- function(dt, sutunlar = names(dt)[vapply(dt, is.numeric, TRUE)]) {
  dt <- copy(dt)
  for (k in sutunlar) set(dt, j = k, value = fifelse(dt[[k]] > 0 & dt[[k]] < 20, "<20", as.character(dt[[k]])))
  dt
}
f4[n < 20, agirlikli_yuzde := NA_real_]
fwrite(say_maske(f4, "n"), "Results/denetim/fizibilite_koca_durumu.csv")
fwrite(f4_capraz, file.path(ddir, "fizibilite_koca_durumu_capraz.csv"))
fwrite(say_maske(f4_capraz), "Results/denetim/fizibilite_koca_durumu_capraz.csv")
fwrite(say_maske(f4_bayrak), "Results/denetim/fizibilite_koca_bayraklari.csv")
fwrite(say_maske(f4_ucretsiz), "Results/denetim/fizibilite_bayraklar_G.csv")
eksik_deg <- c("Y", "k_yas", "e_yas", "k_egitim", "e_egitim", "n_0_5", "n_6_13", "n_14_17", "n_diger_18_64", "n_diger_65", "aE", "aO", "aO_izk", "a_esd", "HB031", "HB030",
               "k_kisit", "e_kisit", "k_kronik", "e_kronik", "mulkiyet", "e_durum_gy", "k_FI010", "e_FI010", "k_FI120", "e_FI120")
f6 <- rbindlist(lapply(eksik_deg, function(v) u[, .(degisken = v, eksik = sum(is.na(get(v))), n = .N), keyby = .(yil, G)]))
f6 <- f6[eksik > 0 | degisken %in% eksik_deg[1:21]]
f6_genis <- dcast(f6, degisken ~ yil + G, value.var = "eksik", fill = 0)
print(f6_genis)
fwrite(f6, "Results/denetim/eksik_veri_degisken_yil_G.csv")
u[, hg110_kurali := as.integer(hane_kimlik %in% hg_kont[tutmayan == TRUE, hane_kimlik])]
hg_kural_ozet <- u[, .(hane = .N, hg110_negatif_kurali = sum(hg110_kurali), O_negatif = sum(O < 0), O_negatif_kural = sum(O < 0 & hg110_kurali == 1)), keyby = .(yil, G)]
print(hg_kural_ozet)
fwrite(hg_kural_ozet, "Results/denetim/hg110_negatif_kurali.csv")
kayitsiz <- h[dislama == "3_bireysel_kayit_eksik"]
kayitsiz[, gozlenen := fifelse(k_f_kayit == 1, "kadın", fifelse(e_f_kayit == 1, "erkek", "ikisi de kayıtsız"))]
kayitsiz[, `:=`(Ek_oran = fifelse(k_f_kayit == 1, k_E / m_t, NA_real_), Ee_oran = fifelse(e_f_kayit == 1, e_E / m_t, NA_real_), kayit_grubu = 1L)]
dahil <- copy(u)[, `:=`(Ek_oran = E_k / m_t, Ee_oran = E_e / m_t, gozlenen = "ikisi", kayit_grubu = 0L)]
kd <- rbind(kayitsiz[, .(kayit_grubu, Y, HG110_oran = HG110 / m_t, n_0_5, n_6_13, n_14_17, hane_buyuklugu, k_yas = k_FK070, e_yas = e_FK070, Ek_oran, Ee_oran, HB030, yil, HB040)],
            dahil[, .(kayit_grubu, Y, HG110_oran = HG110 / m_t, n_0_5, n_6_13, n_14_17, hane_buyuklugu, k_yas, e_yas, Ek_oran, Ee_oran, HB030, yil, HB040)])
kd[, `:=`(HG110_oran = pmin(HG110_oran, 10), Ek_oran = pmin(Ek_oran, 10), Ee_oran = pmin(Ee_oran, 10))]
for (yy in 2023:2025) kd[, (paste0("yil_", yy)) := as.integer(yil == yy)]
for (r in sort(unique(kd$HB030))) kd[, (paste0("bolge_", r)) := as.integer(HB030 == r)]
kd_deg <- c("Y", "HG110_oran", "n_0_5", "n_6_13", "n_14_17", "hane_buyuklugu", "k_yas", "e_yas", "Ek_oran", "Ee_oran", paste0("yil_", 2023:2025), paste0("bolge_", sort(unique(kd$HB030))))
kayitsiz_kars <- rbindlist(lapply(kd_deg, function(v) {
  g1 <- kd$kayit_grubu == 1 & !is.na(kd[[v]])
  g0 <- kd$kayit_grubu == 0 & !is.na(kd[[v]])
  m1 <- weighted.mean(kd[[v]][g1], kd$HB040[g1]); m0 <- weighted.mean(kd[[v]][g0], kd$HB040[g0])
  v1 <- sum(kd$HB040[g1] * (kd[[v]][g1] - m1)^2) / sum(kd$HB040[g1]); v0 <- sum(kd$HB040[g0] * (kd[[v]][g0] - m0)^2) / sum(kd$HB040[g0])
  data.table(degisken = v, kayitsiz_esli = round(m1, 3), dahil = round(m0, 3), smd = round((m1 - m0) / sqrt((v1 + v0) / 2), 3), n_kayitsiz = sum(g1))
}))
kayitsiz_kars <- rbind(kayitsiz_kars, data.table(degisken = c("n_kayitsiz_esli", "n_dahil", "gozlenen_es_kadin", "gozlenen_es_erkek"),
                                                 kayitsiz_esli = c(nrow(kayitsiz), NA, kayitsiz[gozlenen == "kadın", .N], kayitsiz[gozlenen == "erkek", .N]),
                                                 dahil = c(NA, nrow(u), NA, NA), smd = NA), fill = TRUE)
print(kayitsiz_kars)
fwrite(kayitsiz_kars, "Results/denetim/eksik_kayitsiz_es_karsilastirma.csv")
sure_ekle("fizibilite", t0)

t0 <- Sys.time()
suppressPackageStartupMessages(library(nnet))
dugum <- list()
ns_kur <- function(x, df, ad) {
  b <- ns(x, df = df)
  dugum[[ad]] <<- list(knots = unname(attr(b, "knots")), sinir = unname(attr(b, "Boundary.knots")), df = df)
  invisible(NULL)
}
ns_kur(u$aE, 4, "gE")
ns_kur(u$aO, 3, "hO")
ns_kur(u$aO_izk, 3, "hOizk")
ns_kur(u$a_esd, 4, "esd")
ns_kur(u$k_yas, 3, "ky")
ns_kur(u$e_yas, 3, "ey")
baz_kaynak <- c(gE = "aE", hO = "aO", hOizk = "aO_izk", esd = "a_esd", ky = "k_yas", ey = "e_yas")
bazlari_ekle <- function(dt) {
  for (ad in names(baz_kaynak)) {
    B <- unclass(ns(dt[[baz_kaynak[[ad]]]], knots = dugum[[ad]]$knots, Boundary.knots = dugum[[ad]]$sinir))
    set(dt, j = paste0(ad, seq_len(ncol(B))), value = as.data.table(B[, seq_len(ncol(B)), drop = FALSE]))
  }
  dt[, `:=`(k_egitim_f = factor(k_egitim, levels = 1:5), e_egitim_f = factor(e_egitim, levels = 1:5))]
  invisible(dt)
}
bazlari_ekle(u)
c5_ata <- function(dt, alt_esik = 0, ust_esik = 1) {
  dt[, C5 := fcase(G == "M", "M", G == "F", "F", G == "D" & s >= 0.05 & s <= 0.15, "D_dusuk", G == "D" & s >= 0.45 & s <= 0.55, "D_orta", G == "D" & s >= 0.85 & s <= 0.95, "D_yuksek", default = NA_character_)]
  invisible(dt)
}
c5_ata(u)
c5_sira <- c("M", "D_dusuk", "D_orta", "D_yuksek", "F")
kov_m1 <- c(paste0("ky", 1:3), paste0("ey", 1:3), "k_egitim_f", "e_egitim_f", "n_0_5", "n_6_13", "n_14_17", "n_diger_18_64", "n_diger_65", "yil_f")
kov_gelir <- c(paste0("gE", 1:4), paste0("hO", 1:3))
kov_m3 <- c("k_kisit", "e_kisit", "k_kronik", "e_kronik", "mulkiyet")
ps_form <- as.formula(paste("Kf ~", paste(c(kov_gelir, kov_m1, "ibbs1"), collapse = " + ")))
ortak_destek <- function(dt, etiket, kat_sutun = "C5", kat_sira = c5_sira) {
  x <- dt[!is.na(get(kat_sutun))]
  x[, Kf := factor(get(kat_sutun), levels = kat_sira)]
  x[, wps := .N * HB040 / sum(HB040)]
  fit <- multinom(ps_form, data = x, weights = wps, maxit = 3000, trace = FALSE, MaxNWts = 10000, abstol = 1e-10, reltol = 1e-12)
  P <- predict(fit, newdata = dt, type = "probs")
  colnames(P) <- kat_sira
  sinir <- rbindlist(lapply(kat_sira, function(k) {
    yz <- rbindlist(lapply(kat_sira, function(g) {
      ii <- which(dt[[kat_sutun]] == g)
      data.table(grup = g, p01 = wq(P[ii, k], dt$HB040[ii], 0.01), p99 = wq(P[ii, k], dt$HB040[ii], 0.99), n = length(ii))
    }))
    data.table(k = k, alt = max(yz$p01), ust = min(yz$p99), yz_grup_alt = yz$grup[which.max(yz$p01)], yz_grup_ust = yz$grup[which.min(yz$p99)])
  }))
  ic <- Reduce(`&`, lapply(seq_along(kat_sira), function(j) P[, j] >= sinir$alt[j] & P[, j] <= sinir$ust[j]))
  list(fit = fit, P = P, sinir = sinir[, etiket := etiket], Q = as.integer(ic), yakinsama = fit$convergence, iter = fit$iter)
}
od <- ortak_destek(u, "ana")
cat("Çok terimli model yakınsama kodu:", od$yakinsama, "\n")
print(od$sinir)
u[, Q := od$Q]
for (j in seq_along(c5_sira)) set(u, j = paste0("e_", c5_sira[j]), value = od$P[, j])
fwrite(od$sinir, "Results/denetim/ortak_destek_sinirlari.csv")
od_dis <- rbind(u[, .(n = .N, Q_disi_n = sum(Q == 0), Q_disi_agirlikli = round(100 * sum(HB040 * (Q == 0)) / sum(HB040), 2)), keyby = .(yil = as.character(yil), G)],
                u[, .(n = .N, Q_disi_n = sum(Q == 0), Q_disi_agirlikli = round(100 * sum(HB040 * (Q == 0)) / sum(HB040), 2)), keyby = .(G)][, yil := "havuz"],
                u[, .(n = .N, Q_disi_n = sum(Q == 0), Q_disi_agirlikli = round(100 * sum(HB040 * (Q == 0)) / sum(HB040), 2)), keyby = .(yil = as.character(yil))][, G := "tümü"],
                u[, .(yil = "havuz", G = "tümü", n = .N, Q_disi_n = sum(Q == 0), Q_disi_agirlikli = round(100 * sum(HB040 * (Q == 0)) / sum(HB040), 2))], use.names = TRUE)
print(od_dis)
fwrite(od_dis, "Results/denetim/ortak_destek_dislanan.csv")
od_tani <- rbindlist(lapply(seq_len(nrow(od$sinir)), function(r) rbindlist(lapply(c("alt", "ust"), function(b) {
  d <- if (b == "alt") od$P[, r] < od$sinir$alt[r] else od$P[, r] > od$sinir$ust[r]
  data.table(kontrol = paste0("yalnız bu sınır: ", od$sinir$k[r], ", ", b), tum = 100 * sum(u$HB040 * d) / sum(u$HB040), F = 100 * sum(u$HB040 * d * (u$G == "F")) / sum(u$HB040 * (u$G == "F")))
}))))
s4 <- setdiff(c5_sira, "D_yuksek")
ic4 <- Reduce(`&`, lapply(s4, function(k) {
  j <- match(k, c5_sira)
  yz <- rbindlist(lapply(s4, function(g) { ii <- which(u$C5 == g); data.table(p01 = wq(od$P[ii, j], u$HB040[ii], 0.01), p99 = wq(od$P[ii, j], u$HB040[ii], 0.99)) }))
  od$P[, j] >= max(yz$p01) & od$P[, j] <= min(yz$p99)
}))
od_tani <- rbind(od_tani, data.table(kontrol = "D_yüksek sınır hesabından çıkarılınca toplam dışlama", tum = 100 * sum(u$HB040 * !ic4) / sum(u$HB040), F = 100 * sum(u$HB040 * (!ic4) * (u$G == "F")) / sum(u$HB040 * (u$G == "F"))))
od_tani[, `:=`(tum = round(tum, 1), F = round(F, 1))]
print(od_tani)
fwrite(od_tani, "Results/denetim/ortak_destek_tani.csv")
od_yay <- u[, .(n = .N, ham_yayginlik = round(100 * sum(HB040 * Y) / sum(HB040), 1)), keyby = .(Q, G)]
print(od_yay)
fwrite(od_yay, "Results/denetim/ortak_destek_ic_dis_yayginlik.csv")
od_uyari <- c(toplam = od_dis[yil == "havuz" & G == "tümü", Q_disi_agirlikli], F = od_dis[yil == "havuz" & G == "F", Q_disi_agirlikli])
cat("Q dışı ağırlıklı pay: toplam", od_uyari[["toplam"]], "%, F", od_uyari[["F"]], "%; uyarı eşiği 10 / 25\n")
smd <- function(x, g, w) {
  m1 <- weighted.mean(x[g == 1], w[g == 1]); m0 <- weighted.mean(x[g == 0], w[g == 0])
  v1 <- sum(w[g == 1] * (x[g == 1] - m1)^2) / sum(w[g == 1]); v0 <- sum(w[g == 0] * (x[g == 0] - m0)^2) / sum(w[g == 0])
  c(ic = m1, dis = m0, smd = (m1 - m0) / sqrt((v1 + v0) / 2))
}
karsilastirma_deg <- c("Y", "E_oran", "O_oran", "k_yas", "e_yas", "n_0_5", "n_6_13", "n_14_17", "n_diger_18_64", "n_diger_65", "k_kisit", "e_kisit", "k_kronik", "e_kronik")
u_kar <- copy(u)
u_kar[, `:=`(E_oran_k = pmin(E_oran, 10), O_oran_k = pmax(pmin(O_oran, 10), -2))]
u_kar[, `:=`(E_oran = E_oran_k, O_oran = O_oran_k)]
for (k in 1:5) u_kar[, (paste0("k_egitim_", k)) := as.integer(k_egitim == k)][, (paste0("e_egitim_", k)) := as.integer(e_egitim == k)]
for (r in sort(unique(u$HB030))) u_kar[, (paste0("bolge_", r)) := as.integer(HB030 == r)]
for (yy in 2023:2025) u_kar[, (paste0("yil_", yy)) := as.integer(yil == yy)]
kar_deg <- c(karsilastirma_deg, paste0("k_egitim_", 1:5), paste0("e_egitim_", 1:5), paste0("bolge_", sort(unique(u$HB030))), paste0("yil_", 2023:2025))
od_kars <- rbindlist(lapply(kar_deg, function(v) as.data.table(as.list(smd(u_kar[[v]], u_kar$Q, u_kar$HB040)))[, degisken := v]))
setcolorder(od_kars, "degisken")
od_kars[, (c("ic", "dis", "smd")) := lapply(.SD, round, 3), .SDcols = c("ic", "dis", "smd")]
print(od_kars)
fwrite(od_kars, "Results/denetim/ortak_destek_ic_dis_karsilastirma.csv")
yog <- rbindlist(lapply(c5_sira, function(k) rbindlist(lapply(c5_sira, function(g) {
  x <- u[!is.na(C5) & C5 == g]
  lz <- qlogis(pmin(pmax(x[[paste0("e_", k)]], 1e-6), 1 - 1e-6))
  dd <- density(lz, weights = x$HB040 / sum(x$HB040), from = qlogis(1e-5), to = qlogis(1 - 1e-3), n = 301, bw = bw.SJ(lz))
  data.table(k = k, G = g, logit = dd$x, yogunluk = dd$y, n = nrow(x))
}))))
fwrite(yog, file.path(ddir, "figur_verileri", "figS_ortusme.csv"))
fwrite(od$sinir[, .(k, alt, ust, logit_alt = qlogis(alt), logit_ust = qlogis(ust))], file.path(ddir, "figur_verileri", "figS_ortusme_sinirlar.csv"))
q <- u[Q == 1]
q[, w_norm := .N * HB040 / sum(HB040)]
dugum_s <- unname(wq(q[G == "D", s], q[G == "D", w_norm], c(0.25, 0.5, 0.75)))
dugum$fs <- list(knots = dugum_s, sinir = c(0, 1), df = 4)
cat("f(s) iç düğümleri (D ∩ Q, ağırlıklı 25/50/75):", round(dugum_s, 4), "\n")
fs_baz <- function(s_vek, G_vek, dug = dugum_s) {
  s_bos <- ifelse(G_vek == "D", s_vek, 0.5)
  B <- ns(s_bos, knots = dug, Boundary.knots = c(0, 1))
  B05 <- predict(B, 0.5)
  Bs <- sweep(unclass(B)[, seq_len(ncol(B)), drop = FALSE], 2, as.vector(B05)) * (G_vek == "D")
  colnames(Bs) <- paste0("fs", seq_len(ncol(Bs)))
  Bs
}
fs_nokta <- function(s0, dug = dugum_s) {
  B <- ns(c(s0, 0.5), knots = dug, Boundary.knots = c(0, 1))
  b <- unclass(B)[, seq_len(ncol(B)), drop = FALSE]
  sweep(b[seq_along(s0), , drop = FALSE], 2, b[length(s0) + 1, ])
}
q[, (paste0("fs", 1:4)) := as.data.table(fs_baz(s, G))]
q[, `:=`(gM = as.integer(G == "M"), gF = as.integer(G == "F"))]
stopifnot(q[G != "D", all(fs1 == 0 & fs2 == 0 & fs3 == 0 & fs4 == 0)], q[, !anyNA(.SD), .SDcols = c(kov_gelir, kov_m1, "gM", "gF", paste0("fs", 1:4))])
fiz_q <- rbind(q[, .(n = .N, olay = sum(Y), olay_yok = sum(1 - Y), kish_n = round(kish(HB040), 1), agirlikli_pay = round(100 * sum(w_norm) / nrow(q), 2)), keyby = .(grup = G)],
               rbindlist(lapply(seq_len(nrow(capa)), function(i) q[G == "D" & s >= capa$alt[i] & s <= capa$ust[i], .(grup = capa$capa[i], n = .N, olay = sum(Y), olay_yok = sum(1 - Y), kish_n = round(kish(HB040), 1), agirlikli_pay = round(100 * sum(w_norm) / nrow(q), 2))])),
               q[G == "F", .(n = .N, olay = sum(Y), olay_yok = sum(1 - Y), kish_n = round(kish(HB040), 1), agirlikli_pay = round(100 * sum(w_norm) / nrow(q), 2)), keyby = .(grup = paste0("F_", e_durum_gy))])
fiz_q[, kural := fcase(grup %in% c("M", "F"), "köşe: n ≥ 200, olay ≥ 50, olay yok ≥ 50", grepl("^D_", grup), "çapa: n ≥ 200", grepl("^F_", grup), "koca durumu: n ≥ 50", default = "")]
fiz_q[, saglandi := fcase(grup %in% c("M", "F"), n >= 200 & olay >= 50 & olay_yok >= 50, grepl("^D_", grup), n >= 200, grepl("^F_", grup), n >= 50, default = NA)]
print(fiz_q)
fwrite(fiz_q, "Results/denetim/fizibilite_Q_kurallari.csv")
reis_kadin <- rbind(u[, .(orneklem = "uygun", n = .N, kadin_reis = sum(reis_cins == 2), kadin_reis_agirlikli_yuzde = round(100 * sum(HB040 * (reis_cins == 2)) / sum(HB040), 1)), keyby = G],
                    q[, .(orneklem = "Q", n = .N, kadin_reis = sum(reis_cins == 2), kadin_reis_agirlikli_yuzde = round(100 * sum(HB040 * (reis_cins == 2)) / sum(HB040), 1)), keyby = G])
print(reis_kadin)
fwrite(say_maske(reis_kadin, c("n", "kadin_reis")), "Results/denetim/reis_cinsiyeti_G.csv")
pay_q <- data.table(yuzdelik = c(0.025, 0.25, 0.5, 0.75, 0.975), s = wq(q[G == "D", s], q[G == "D", w_norm], c(0.025, 0.25, 0.5, 0.75, 0.975)))
print(pay_q)
egri_aralik <- pay_q[yuzdelik %in% c(0.025, 0.975), s]
fwrite(pay_q, "Results/denetim/pay_yuzdelikleri_Q.csv")
esit_kazanc <- rbind(u[G == "D", .(orneklem = "uygun", n_D = .N, esit = sum(abs(E_k - E_e) < 1), esit_agirlikli = 100 * sum(HB040 * (abs(E_k - E_e) < 1)) / sum(HB040),
                                   pay_045_055 = sum(s >= 0.45 & s <= 0.55))],
                     q[G == "D", .(orneklem = "Q", n_D = .N, esit = sum(abs(E_k - E_e) < 1), esit_agirlikli = 100 * sum(HB040 * (abs(E_k - E_e) < 1)) / sum(HB040),
                                   pay_045_055 = sum(s >= 0.45 & s <= 0.55))])
print(esit_kazanc)
fwrite(esit_kazanc, "Results/denetim/esit_kazanc.csv")
write_parquet(u, file.path(ddir, "uygun_ciftler.parquet"))
write_parquet(q, file.path(ddir, "analiz_Q.parquet"))
write_json(dugum, "Results/spline_dugumleri.json", digits = NA, auto_unbox = TRUE, pretty = TRUE)
sure_ekle("ortak destek", t0)
fwrite(rbindlist(dogr), "Results/dogrulama_kontrolleri.csv")
cat("Doğrulama:", sum(rbindlist(dogr)$durum == "Tuttu"), "/", length(dogr), "tuttu\n")
print(rbindlist(dogr)[durum != "Tuttu"])

t0 <- Sys.time()
Sys.setenv(VECLIB_MAXIMUM_THREADS = "1")
suppressPackageStartupMessages({
  library(brms)
  library(cmdstanr)
  library(posterior)
  library(statmod)
  library(future)
  library(furrr)
})
plan(multisession, workers = 17)
odir <- file.path(ddir, "onbellek")
gh <- statmod::gauss.quad(20, kind = "hermite")
p_marj <- function(eta, sigma) {
  rowSums(vapply(seq_along(gh$nodes),
    function(j) gh$weights[j] / sqrt(pi) * plogis(eta + sqrt(2) * sigma * gh$nodes[j]),
    numeric(length(eta))))
}
q[, zincir := factor(zincir_ana)]
sag_m1 <- c("gM", "gF", paste0("fs", 1:4), kov_m1)
sag_m2 <- c("gM", "gF", paste0("fs", 1:4), kov_gelir, kov_m1)
sag_m3 <- c(sag_m2, kov_m3)
x_kur <- function(veri, sag) {
  X <- model.matrix(as.formula(paste("~", paste(sag, collapse = " + "))), data = veri)
  X[, colnames(X) != "(Intercept)", drop = FALSE]
}
oncel_tohum <- 20261029L
oncel_ongoru <- function(veri, sag, B = 2000L, sd_b = 1, sd_zincir = 1, sd_ibbs = 1) {
  set.seed(oncel_tohum)
  X <- x_kur(veri, sag)
  Xc <- sweep(X, 2, colMeans(X))
  ib <- as.integer(veri$ibbs2)
  zn <- as.integer(factor(veri$zincir))
  w <- veri$w_norm
  out <- rbindlist(lapply(seq_len(B), function(b) {
    a <- 2.5 * rt(1, 3)
    beta <- rnorm(ncol(X), 0, sd_b)
    s_ib <- abs(rnorm(1, 0, sd_ibbs))
    s_zn <- abs(rnorm(1, 0, sd_zincir))
    u_ib <- rnorm(nlevels(veri$ibbs2), 0, s_ib)[ib]
    eta <- a + drop(Xc %*% beta) + u_ib
    eta_z <- eta + rnorm(max(zn), 0, s_zn)[zn]
    p <- plogis(eta_z)
    pm <- function(gg) sum(w[veri$G == gg] * p[veri$G == gg]) / sum(w[veri$G == gg])
    gk <- colnames(X) %in% c("gM", "gF", paste0("fs", 1:4))
    eta_ortak <- a + drop(Xc[, !gk, drop = FALSE] %*% beta[!gk]) - sum(colMeans(X[, gk, drop = FALSE]) * beta[gk]) + u_ib
    d_k <- function(dlt) 100 * sum(w * p_marj(eta_ortak + dlt, s_zn)) / sum(w)
    pM <- d_k(beta[colnames(X) == "gM"])
    pF <- d_k(beta[colnames(X) == "gF"])
    data.table(cekilis = b, yayginlik = 100 * sum(w * p) / sum(w), yayginlik_M = 100 * pm("M"), yayginlik_D = 100 * pm("D"), yayginlik_F = 100 * pm("F"),
               E4 = pF - pM, sigma_zincir = s_zn, rho = s_zn^2 / (s_zn^2 + pi^2 / 3), sigma_ibbs2 = s_ib)
  }))
  out
}
oo_dosya <- file.path(odir, paste0("oncel_ongoru_", substr(rlang::hash(list(x_kur(q, sag_m2), q$w_norm, as.character(q$zincir), as.character(q$ibbs2), oncel_tohum, rlang::hash(deparse(oncel_ongoru)))), 1, 10), ".rds"))
if (!file.exists(oo_dosya)) saveRDS(list(n1 = oncel_ongoru(q, sag_m2), n2 = oncel_ongoru(q, sag_m2, sd_zincir = 2)), oo_dosya)
oo <- readRDS(oo_dosya)
oo_ozet <- rbindlist(lapply(names(oo), function(k) {
  x <- oo[[k]]
  data.table(sd_zincir_oncel = c(n1 = 1, n2 = 2)[[k]], yayginlik_q05 = quantile(x$yayginlik, 0.05), yayginlik_q50 = median(x$yayginlik), yayginlik_q95 = quantile(x$yayginlik, 0.95),
             pay_1_alti_99_ustu = mean(x$yayginlik < 1 | x$yayginlik > 99), E4_q05 = quantile(x$E4, 0.05), E4_q50 = median(x$E4), E4_q95 = quantile(x$E4, 0.95),
             rho_q05 = quantile(x$rho, 0.05), rho_q50 = median(x$rho), rho_q95 = quantile(x$rho, 0.95))
}))
print(oo_ozet, digits = 3)
fwrite(oo_ozet, "Results/denetim/oncel_ongoru_ozeti.csv")
fwrite(oo$n1[, .(cekilis, yayginlik, yayginlik_M, yayginlik_D, yayginlik_F, E4, rho)], file.path(ddir, "figur_verileri", "figS_oncel_ongoru.csv"))
oncel_karar <- if (oo_ozet[sd_zincir_oncel == 1, pay_1_alti_99_ustu] > 0.5) "b ~ N(0, 0,5)" else "başlangıç prior'ları korundu"
cat("Önsel öngörü kararı:", oncel_karar, "\n")
sd_b_ana <- if (oncel_karar == "b ~ N(0, 0,5)") 0.5 else 1
sure_ekle("önsel öngörü denetimi", t0)

model_sureleri <- if (file.exists(file.path(odir, "model_sureleri.csv"))) fread(file.path(odir, "model_sureleri.csv")) else data.table(model = character(), dakika = numeric(), yer = character(), n = integer())
model_kur <- function(ad, veri, sag, zincir = TRUE, ibbs = TRUE, agirlikli = TRUE, sd_zincir = 1, sd_b = sd_b_ana, iter = 2500L, warmup = 1000L, tohum = 20261030L,
                      adapt_delta = 0.9, threads = 4L, ek_prior = NULL, opencl_ac = FALSE, chains = 4L, max_treedepth = 10L, csv_sakla = FALSE) {
  ayar_ozeti <- substr(rlang::hash(list(iter, warmup, tohum, adapt_delta, threads, sd_b, sd_zincir, max_treedepth, chains, ek_prior, ibbs, zincir, agirlikli, "static")), 1, 8)
  dosya <- file.path(odir, paste0("fit_", ad, "_", ayar_ozeti))
  csv_dizin <- if (csv_sakla) file.path(odir, "stan_csv", paste0(ad, "_", ayar_ozeti)) else NULL
  if (!is.null(csv_dizin)) dir.create(csv_dizin, showWarnings = FALSE, recursive = TRUE)
  re <- c(if (ibbs) "(1 | ibbs2)", if (zincir) "(1 | zincir)")
  lhs <- if (agirlikli) "Y | weights(w_norm)" else "Y"
  f <- bf(as.formula(paste(lhs, "~", paste(c(sag, re), collapse = " + "))))
  pr <- c(prior(student_t(3, 0, 2.5), class = Intercept), prior_string(sprintf("normal(0, %s)", sd_b), class = "b"))
  if (ibbs) pr <- c(pr, prior(normal(0, 1), class = sd, group = ibbs2))
  if (zincir) pr <- c(pr, prior_string(sprintf("normal(0, %s)", sd_zincir), class = "sd", group = "zincir"))
  if (!is.null(ek_prior)) pr <- c(pr, ek_prior)
  yeni <- !file.exists(paste0(dosya, ".rds"))
  eski_zaman <- if (yeni) NA else file.mtime(paste0(dosya, ".rds"))
  t1 <- Sys.time()
  if (!is.null(csv_dizin) && yeni) unlink(list.files(csv_dizin, pattern = "\\.csv$", full.names = TRUE))
  fit <- brm(f, data = veri, family = bernoulli(), prior = pr, chains = chains, cores = chains, threads = if (opencl_ac) NULL else threading(threads, static = TRUE), output_dir = csv_dizin,
             opencl = if (opencl_ac) opencl(c(0, 0)) else NULL, iter = iter, warmup = warmup, seed = tohum, backend = "cmdstanr", save_pars = save_pars(group = if (ibbs) "ibbs2" else FALSE),
             control = list(adapt_delta = adapt_delta, max_treedepth = max_treedepth), file = dosya, file_refit = "on_change", refresh = 0, silent = 2)
  attr(fit, "max_treedepth") <- max_treedepth
  attr(fit, "csv_dizin") <- csv_dizin
  attr(fit, "zincir_sayisi") <- chains
  if (yeni || !identical(file.mtime(paste0(dosya, ".rds")), eski_zaman)) {
    model_sureleri <<- rbind(model_sureleri[model != ad], data.table(model = ad, dakika = round(as.numeric(difftime(Sys.time(), t1, units = "mins")), 2), yer = if (opencl_ac) "GPU (OpenCL)" else sprintf("CPU (%d zincir × %d iş parçacığı)", chains, threads), n = nrow(veri)))
    fwrite(model_sureleri, file.path(odir, "model_sureleri.csv"))
  }
  if (nrow(fit$data) != nrow(veri)) stop("brms satır düşürdü: ", ad, " ", nrow(fit$data), " / ", nrow(veri))
  fit
}
tani_hesap <- function(fit, ad) {
  sm <- summarise_draws(as_draws_array(fit), "rhat", "ess_bulk", "ess_tail", .cores = 8)
  np <- nuts_params(fit)
  en <- as.data.table(np)[Parameter == "energy__"]
  ebfmi <- en[, .(e = sum(diff(Value)^2) / sum((Value - mean(Value))^2)), by = Chain]$e
  td_max <- attr(fit, "max_treedepth") %||% 10L
  data.table(model = ad, parametre = nrow(sm), rhat_max = round(max(sm$rhat, na.rm = TRUE), 4), ess_bulk_min = round(min(sm$ess_bulk, na.rm = TRUE)), ess_tail_min = round(min(sm$ess_tail, na.rm = TRUE)),
             rhat_buyuk_101 = sum(sm$rhat > 1.01, na.rm = TRUE), ess_400_alti = sum(sm$ess_bulk < 400 | sm$ess_tail < 400, na.rm = TRUE),
             diverjans = sum(as.data.table(np)[Parameter == "divergent__", Value]), agac_derinligi_siniri = sum(as.data.table(np)[Parameter == "treedepth__", Value] >= td_max),
             ebfmi_min = round(min(ebfmi), 3), en_kotu_rhat = sub("^(r_zincir)\\[.*$", "\\1[·]", sm$variable[which.max(sm$rhat)]),
             en_kotu_ess = sub("^(r_zincir)\\[.*$", "\\1[·]", sm$variable[which.min(pmin(sm$ess_bulk, sm$ess_tail))]))
}
`%||%` <- function(a, b) if (is.null(a)) b else a
tani_tam <- function(fit, ad) {
  dizin <- attr(fit, "csv_dizin")
  dosyalar <- list.files(dizin, pattern = "\\.csv$", full.names = TRUE)
  dosyalar <- tail(dosyalar[order(file.mtime(dosyalar))], attr(fit, "zincir_sayisi") %||% 4L)
  if (!length(dosyalar)) return(NULL)
  dr <- cmdstanr::read_cmdstan_csv(dosyalar, variables = "z_2", sampler_diagnostics = "", format = "draws_array")$post_warmup_draws
  degiskenler <- dimnames(dr)[[3]]
  sm <- rbindlist(lapply(split(degiskenler, ceiling(seq_along(degiskenler) / 500)), function(v) as.data.table(summarise_draws(dr[, , v], "rhat", "ess_bulk", "ess_tail"))))
  rm(dr)
  invisible(gc())
  data.table(model = ad, parametre_grubu = "zincir düzeyi standart normal sapmalar (z_2)", parametre = nrow(sm), rhat_max = round(max(sm$rhat, na.rm = TRUE), 4),
             ess_bulk_min = round(min(sm$ess_bulk, na.rm = TRUE)), ess_tail_min = round(min(sm$ess_tail, na.rm = TRUE)), rhat_buyuk_101 = sum(sm$rhat > 1.01, na.rm = TRUE),
             ess_400_alti = sum(sm$ess_bulk < 400 | sm$ess_tail < 400, na.rm = TRUE))
}
pilot_dosya <- "Results/log/pilot_sureleri.csv"
if (!file.exists(pilot_dosya)) {
  t0 <- Sys.time()
  pilot <- list()
  t1 <- Sys.time()
  fp <- model_kur("pilot_cpu", q, sag_m2, iter = 300L, warmup = 150L, tohum = 20261031L)
  pilot[[1]] <- data.table(deneme = "CPU, 4 zincir × 4 iş parçacığı, reduce_sum", iter = 300, warmup = 150, dakika = round(as.numeric(difftime(Sys.time(), t1, units = "mins")), 2), durum = "çalıştı")
  writeLines(stancode(fp), "Results/denetim/stan_kodu_M2.stan")
  t1 <- Sys.time()
  sonuc_gpu <- tryCatch({
    fg <- model_kur("pilot_gpu", q, sag_m2, iter = 300L, warmup = 150L, tohum = 20261031L, opencl_ac = TRUE)
    writeLines(stancode(fg), "Results/denetim/stan_kodu_M2_opencl.stan")
    "çalıştı"
  }, error = function(e) paste("hata:", substr(gsub("[\r\n]+", " ", conditionMessage(e)), 1, 400)))
  pilot[[2]] <- data.table(deneme = "GPU, brms opencl(c(0, 0)), 4 zincir", iter = 300, warmup = 150, dakika = round(as.numeric(difftime(Sys.time(), t1, units = "mins")), 2), durum = sonuc_gpu)
  fwrite(rbindlist(pilot), pilot_dosya)
  sure_ekle("pilot", t0)
}
print(fread(pilot_dosya))

t0 <- Sys.time()
ghw <- gh$weights / sqrt(pi)
s_izgara <- round(seq(0.05, 0.95, by = 0.01), 2)
sen_ad_D <- sprintf("D%.2f", s_izgara)
g_sutun <- c("gM", "gF", paste0("fs", 1:4))
sen_temel <- function(gs = g_sutun, s_vek = c(0.1, 0.5, 0.9), dug = dugum_s) {
  fsn <- grep("^fs[0-9]+$", gs, value = TRUE)
  bos <- setNames(rep(0, length(gs)), gs)
  out <- list(M = replace(bos, "gM", 1), F = replace(bos, "gF", 1))
  B <- fs_nokta(s_vek, dug)
  stopifnot(ncol(B) == length(fsn))
  for (i in seq_along(s_vek)) out[[sprintf("D%.2f", s_vek[i])]] <- replace(bos, fsn, B[i, ])
  lapply(out, function(v) matrix(v, nrow = 1, dimnames = list(NULL, gs)))
}
cek_al <- function(fit, hedef, sag, gs, zincir = TRUE) {
  bm <- as_draws_matrix(fit, variable = "^b_", regex = TRUE)
  dfc <- as_draws_df(fit, variable = "b_Intercept")
  X <- x_kur(hedef, sag)
  bn <- paste0("b_", colnames(X))
  if (!all(bn %in% colnames(bm))) stop("katsayı adları eşleşmedi: ", paste(setdiff(bn, colnames(bm)), collapse = ", "))
  gi <- colnames(X) %in% gs
  ib_var <- "ibbs2" %in% names(fit$data)
  ru <- if (ib_var) as.matrix(as_draws_matrix(fit, variable = "^r_ibbs2\\[", regex = TRUE)) else NULL
  ib_idx <- if (ib_var) match(paste0("r_ibbs2[", as.character(hedef$ibbs2), ",Intercept]"), colnames(ru)) else NULL
  if (ib_var && anyNA(ib_idx)) stop("İBBS-2 düzeyi bulunamadı")
  list(Bo = cbind(as.matrix(bm)[, "b_Intercept"], as.matrix(bm)[, bn[!gi], drop = FALSE]), Xo = cbind(1, X[, !gi, drop = FALSE]),
       BG = as.matrix(bm)[, bn[gi], drop = FALSE], g_ad = colnames(X)[gi], RU = ru, ib_idx = ib_idx,
       sig = if (zincir) as.numeric(as.matrix(as_draws_matrix(fit, variable = "sd_zincir__Intercept"))) else rep(0, nrow(bm)),
       zincir_no = dfc$.chain, w = hedef$w_norm)
}
standart <- function(ck, senaryolar, parca = 16L) {
  for (a in names(senaryolar)) senaryolar[[a]] <- senaryolar[[a]][, ck$g_ad, drop = FALSE]
  nd <- nrow(ck$Bo)
  gruplar <- split(seq_len(nd), cut(seq_len(nd), parca, labels = FALSE))
  sw <- sum(ck$w)
  sonuc <- future_map(gruplar, function(ii) {
    E0 <- tcrossprod(ck$Bo[ii, , drop = FALSE], ck$Xo)
    out <- matrix(NA_real_, length(ii), length(senaryolar))
    for (r in seq_along(ii)) {
      e0 <- E0[r, ] + if (is.null(ck$RU)) 0 else ck$RU[ii[r], ck$ib_idx]
      sg <- ck$sig[ii[r]]
      taban <- if (sg > 0) outer(e0, sqrt(2) * sg * gh$nodes, "+") else NULL
      bg <- ck$BG[ii[r], ]
      for (a in seq_along(senaryolar)) {
        S <- senaryolar[[a]]
        dl <- if (nrow(S) == 1L) sum(S * bg) else drop(S %*% bg)
        pm <- if (sg > 0) drop(plogis(taban + dl) %*% ghw) else plogis(e0 + dl)
        out[r, a] <- sum(ck$w * pm) / sw
      }
    }
    out
  }, .options = furrr_options(seed = NULL, globals = c("ck", "senaryolar", "gh", "ghw", "sw")))
  P <- 100 * do.call(rbind, sonuc)
  colnames(P) <- names(senaryolar)
  P
}
e_hesap <- function(P) {
  E <- cbind(E1 = (P[, "D0.10"] + P[, "D0.90"]) / 2 - P[, "D0.50"], E2 = P[, "D0.90"] - P[, "D0.10"], E3a = P[, "F"] - P[, "D0.90"], E3b = P[, "M"] - P[, "D0.10"], E4 = P[, "F"] - P[, "M"])
  stopifnot(max(abs(E[, "E4"] - (E[, "E3a"] + E[, "E2"] - E[, "E3b"]))) < 1e-9)
  E
}
mcse_g <- function(f, m) tryCatch(f(m), error = function(e) NA_real_)
e_ozet <- function(E, zincir_no, model, rope = 2, etiket = NULL) {
  stopifnot(!is.unsorted(zincir_no))
  nz <- length(unique(zincir_no))
  rbindlist(lapply(colnames(E), function(k) {
    x <- E[, k]
    m <- matrix(x, ncol = nz)
    data.table(model = model, buyukluk = k, rope = rope, tahmin = median(x), alt = unname(quantile(x, 0.025)), ust = unname(quantile(x, 0.975)),
               p_alt = mean(x < -rope), p_ic = mean(abs(x) <= rope), p_ust = mean(x > rope), p_poz = mean(x > 0),
               mcse_tahmin = mcse_g(function(z) mcse_quantile(z, 0.5), m), mcse_alt = mcse_g(function(z) mcse_quantile(z, 0.025), m), mcse_ust = mcse_g(function(z) mcse_quantile(z, 0.975), m),
               mcse_p_alt = mcse_g(mcse_mean, m < -rope), mcse_p_ic = mcse_g(mcse_mean, abs(m) <= rope), mcse_p_ust = mcse_g(mcse_mean, m > rope), cekilis = length(x),
               mcse_d_alt_ic = mcse_g(mcse_mean, (m < -rope) - (abs(m) <= rope)), mcse_d_alt_ust = mcse_g(mcse_mean, (m < -rope) - (m > rope)), mcse_d_ic_ust = mcse_g(mcse_mean, (abs(m) <= rope) - (m > rope)),
               etiket = if (is.null(etiket)) model else etiket, alt80 = unname(quantile(x, 0.10)), ust80 = unname(quantile(x, 0.90)), alt50 = unname(quantile(x, 0.25)), ust50 = unname(quantile(x, 0.75)))
  }))
}
p_ozet <- function(P, model, zincir_no = NULL) rbindlist(lapply(colnames(P), function(k) {
  x <- P[, k]
  out <- data.table(model = model, senaryo = k, tahmin = median(x), alt = unname(quantile(x, 0.025)), ust = unname(quantile(x, 0.975)))
  if (!is.null(zincir_no)) {
    m <- matrix(x, ncol = length(unique(zincir_no)))
    out[, `:=`(mcse_tahmin = mcse_g(function(z) mcse_quantile(z, 0.5), m), mcse_sinir = max(mcse_g(function(z) mcse_quantile(z, 0.025), m), mcse_g(function(z) mcse_quantile(z, 0.975), m)))]
  }
  out[, `:=`(alt80 = unname(quantile(x, 0.10)), ust80 = unname(quantile(x, 0.90)), alt50 = unname(quantile(x, 0.25)), ust50 = unname(quantile(x, 0.75)))]
  out
}))
ppc_hesap <- function(fit, veri, ad, n_cek = 400L, tohum = 20261032L) {
  set.seed(tohum)
  ids <- sort(sample(ndraws(fit), n_cek))
  zincir_var <- "zincir" %in% names(fit$data)
  ibbs_var <- "ibbs2" %in% names(fit$data)
  eta_m <- posterior_linpred(fit, draw_ids = ids, re_formula = if (ibbs_var) ~ (1 | ibbs2) else NA)
  sig <- if (zincir_var) as.numeric(as.matrix(as_draws_matrix(fit, variable = "sd_zincir__Intercept")))[ids] else rep(0, n_cek)
  zn <- as.integer(droplevels(factor(veri$zincir)))
  ym <- t(vapply(seq_len(n_cek), function(dd) rbinom(nrow(veri), 1, plogis(eta_m[dd, ] + rnorm(max(zn), 0, sig[dd])[zn])), numeric(nrow(veri))))
  tekrar_ad <- if (zincir_var) "yeni zincir etkileri" else "zincir etkisi yok (kayıtlar bağımsız)"
  w <- veri$w_norm
  pay_bin <- fcase(veri$G == "M", "M", veri$G == "F", "F", veri$s < 0.2, "D [0, 0.2)", veri$s < 0.4, "D [0.2, 0.4)", veri$s < 0.6, "D [0.4, 0.6)", veri$s < 0.8, "D [0.6, 0.8)", default = "D [0.8, 1]")
  gruplar <- list(G_yil = paste(veri$G, veri$yil), pay = pay_bin, ibbs2 = as.character(veri$ibbs2))
  ist <- function(Y, gr) {
    lv <- sort(unique(gr))
    vapply(lv, function(l) { i <- gr == l; 100 * sum(w[i] * Y[i]) / sum(w[i]) }, 0)
  }
  out <- rbindlist(lapply(names(gruplar), function(gn) {
    gr <- gruplar[[gn]]
    gozlem <- ist(veri$Y, gr)
    rk <- t(apply(ym, 1, ist, gr = gr))
    data.table(model = ad, kontrol = gn, grup = names(gozlem), n = as.integer(table(gr)[names(gozlem)]), gozlenen = gozlem, rep_medyan = apply(rk, 2, median),
               rep_alt = apply(rk, 2, quantile, 0.025), rep_ust = apply(rk, 2, quantile, 0.975), ppp = colMeans(rk >= rep(gozlem, each = nrow(rk))), tekrar = tekrar_ad)
  }))
  z2 <- veri[, .N, by = zincir][N == 2L, zincir]
  i2 <- which(veri$zincir %in% z2)
  zz <- as.integer(droplevels(factor(veri$zincir[i2])))
  uyum <- function(Y) { s <- tapply(Y[i2], zz, sum); 100 * mean(s != 1) }
  g_uyum <- uyum(veri$Y)
  rm_ <- apply(ym, 1, uyum)
  z3 <- veri[, .N, by = zincir][N == 3L, zincir]
  i3 <- which(veri$zincir %in% z3)
  z33 <- as.integer(droplevels(factor(veri$zincir[i3])))
  uyum3 <- function(Y) { s <- tapply(Y[i3], z33, sum); 100 * mean(s == 0 | s == 3) }
  g3 <- uyum3(veri$Y)
  r3 <- apply(ym, 1, uyum3)
  rbind(out, data.table(model = ad, kontrol = "zincir_ici_ayni_sonuc", grup = "iki kayıtlı zincirler", n = length(z2), gozlenen = g_uyum,
                        rep_medyan = median(rm_), rep_alt = quantile(rm_, 0.025), rep_ust = quantile(rm_, 0.975), ppp = mean(rm_ >= g_uyum), tekrar = tekrar_ad),
        data.table(model = ad, kontrol = "zincir_ici_ayni_sonuc_3", grup = "üç kayıtlı zincirler", n = length(z3), gozlenen = g3,
                   rep_medyan = median(r3), rep_alt = quantile(r3, 0.025), rep_ust = quantile(r3, 0.975), ppp = mean(r3 >= g3), tekrar = tekrar_ad))
}
model_ozet_yaz <- function(fit, ad) {
  cat("\n==== ", ad, " ====\n", file = "Results/model_ozetleri.txt", append = TRUE)
  capture.output(print(summary(fit, robust = FALSE), digits = 3), file = "Results/model_ozetleri.txt", append = TRUE)
}
protokol <- data.table()
prot_ekle <- function(m_ad, k_ad, olcut, sonuc, karar, onceden = "talimat") {
  eski <- if (nrow(protokol)) protokol[!(model == m_ad & kontrol == k_ad)] else protokol
  protokol <<- rbind(eski, data.table(model = m_ad, kontrol = k_ad, onceden_belirlenmis = onceden, olcut = olcut, sonuc = sonuc, karar = karar), fill = TRUE)
  fwrite(protokol, "Results/model_protokolu.csv")
}
prot_ekle("M2 yapısı", "önsel öngörü", "ağırlıklı yaygınlık çekilişlerinin > %50'si %1'in altında ya da %99'un üstündeyse b ~ N(0, 0,5²)",
          sprintf("pay %.4f (σ_zincir HalfNormal(0, 1)); %.4f (HalfNormal(0, 2))", oo_ozet[sd_zincir_oncel == 1, pay_1_alti_99_ustu], oo_ozet[sd_zincir_oncel == 2, pay_1_alti_99_ustu]), oncel_karar,
          onceden = "analist, sonuçlardan önce (K11)")
pil <- fread(pilot_dosya)
prot_ekle("pilot", "hesaplama yolu", "CPU (4 zincir × 4 iş parçacığı) ve OpenCL denenir; çalışan yol seçilir",
          paste(sprintf("%s: %.2f dk, %s", pil$deneme, pil$dakika, pil$durum), collapse = " | "),
          "CPU; OpenCL hatası brms'in sarmalayıcı iletisiyle kaydedildi, asıl hata (CL_INVALID_KERNEL) Results/log/opencl_tani.txt'te")
tani_tum <- data.table()
tani_kaydet <- function(fit, ad) {
  tn <- tani_hesap(fit, ad)
  tani_tum <<- rbind(if (nrow(tani_tum)) tani_tum[model != ad] else tani_tum, tn, fill = TRUE)
  fwrite(tani_tum, "Results/denetim/model_tanilari.csv")
  ok <- tn$rhat_max <= 1.01 & tn$ess_bulk_min >= 400 & tn$ess_tail_min >= 400 & tn$diverjans == 0 & tn$ebfmi_min > 0.3
  prot_ekle(ad, "yakınsama", "R-hat ≤ 1,01; bulk ve tail ESS ≥ 400; divergence 0; E-BFMI > 0,3",
            sprintf("R-hat en büyük %.4f; ESS en küçük %d / %d; divergence %d; E-BFMI en küçük %.3f", tn$rhat_max, tn$ess_bulk_min, tn$ess_tail_min, tn$diverjans, tn$ebfmi_min),
            if (ok) "kabul" else "düzeltme gerekli")
  print(tn)
  ok
}
model_protokol <- function(ad, veri, sag, ...) {
  fit <- model_kur(ad, veri, sag, ...)
  ok <- tani_kaydet(fit, ad)
  if (!ok) {
    tn <- tani_tum[model == ad]
    if (tn$diverjans > 0 || tn$rhat_max > 1.01) {
      for (ad_d in c(0.95, 0.99)) {
        ad2 <- paste0(ad, "_ad", round(ad_d * 100))
        fit <- model_kur(ad2, veri, sag, adapt_delta = ad_d, ...)
        ok <- tani_kaydet(fit, ad2)
        prot_ekle(ad, "geri dönüş 1", "divergence ya da R-hat sorunu: adapt_delta artırılır", paste("adapt_delta", ad_d), if (ok) paste("kabul:", ad2) else "sürüyor")
        if (ok) break
      }
    } else if (tn$ess_bulk_min < 400 || tn$ess_tail_min < 400) {
      ad2 <- paste0(ad, "_uzun")
      ek <- list(...)
      ek$iter <- max(ek$iter %||% 2500L, 4500L) + 1500L
      ek$warmup <- 1500L
      fit <- do.call(model_kur, c(list(ad = ad2, veri = veri, sag = sag), ek))
      ok <- tani_kaydet(fit, ad2)
      prot_ekle(ad, "ESS", "ESS < 400: iterasyon artırılır", sprintf("%d ısınma + %d örnekleme", ek$warmup, ek$iter - ek$warmup), if (ok) paste("kabul:", ad2) else "sorun sürüyor")
    } else {
      prot_ekle(ad, "E-BFMI", "E-BFMI ≤ 0,3: iterasyon artırmak çözmez; yeniden parametreleme gerekir", sprintf("E-BFMI en küçük %.3f", tn$ebfmi_min), "betik durduruldu")
    }
    if (!ok) stop("Yakınsama ölçütleri sağlanmadı, betik durduruldu: ", ad)
  }
  fit
}
invisible(file.create("Results/model_ozetleri.txt"))
sure_ekle("model fonksiyonları", t0)

t0 <- Sys.time()
iter_ana <- 5500L
fit_M2 <- model_protokol("M2", q, sag_m2, iter = iter_ana, csv_sakla = TRUE)
writeLines(stancode(fit_M2), "Results/denetim/stan_kodu_M2.stan")
fit_M1 <- model_protokol("M1", q, sag_m1, iter = iter_ana, csv_sakla = TRUE)
fit_M3 <- model_protokol("M3", q, sag_m3, iter = iter_ana, csv_sakla = TRUE)
tam_tani <- rbindlist(lapply(c("M1", "M2", "M3"), function(m) tani_tam(get(paste0("fit_", m)), m)))
print(tam_tani)
kb_m2 <- as.data.table(summarise_draws(as_draws_matrix(fit_M2, variable = "^b_", regex = TRUE), "median", "sd"))[variable != "b_Intercept"]
prot_ekle("M2", "katsayı prior'ı ile çatışma", "b ~ N(0, 1) altında |medyan| > 3 (prior'ın 3 SS dışı) ya da posterior SS > 0,75 (prior'a yakın) olan katsayılar",
          sprintf("|medyan| > 3: %s; posterior SS > 0,75: %s", paste(sub("^b_", "", kb_m2[abs(median) > 3, variable]), collapse = ", "), paste(sub("^b_", "", kb_m2[sd > 0.75, variable]), collapse = ", ")),
          "katsayı prior'ı gelir ve yaş spline'larında bilgilendirici: C21 (b ~ N(0, 2,5²) ve N(0, 5²)) ile E1–E4 karşılaştırılır", onceden = "sonuç sonrası (K18)")
sure_ekle("M1–M3 kurulum ve tanı", t0)
t0 <- Sys.time()
kod_ozeti <- function(f) rlang::hash(deparse(f))
sv_surum <- "zincir kümeli bootstrap, replikatlarda model ve standartlaştırma"
cek_ozeti <- function(fit, ...) {
  bm <- as.matrix(as_draws_matrix(fit, variable = "^(b_|sd_)", regex = TRUE))
  substr(rlang::hash(list(bm[unique(round(seq(1, nrow(bm), length.out = 50))), , drop = FALSE], dim(bm), ...)), 1, 10)
}
std_kayit <- function(ad, fit, hedef, sag, senaryolar, gs = g_sutun, zincir = TRUE) {
  dosya <- file.path(odir, paste0("std_", ad, "_", cek_ozeti(fit, hedef$w_norm, as.character(hedef$ibbs2), x_kur(hedef, sag), senaryolar, gs, zincir, kod_ozeti(cek_al), kod_ozeti(standart), gh), ".rds"))
  if (!file.exists(dosya)) {
    t1 <- Sys.time()
    ck <- cek_al(fit, hedef, sag, gs, zincir = zincir)
    P <- standart(ck, senaryolar)
    saveRDS(list(P = P, zincir_no = ck$zincir_no, dakika = round(as.numeric(difftime(Sys.time(), t1, units = "mins")), 2)), dosya)
  }
  readRDS(dosya)
}
st_M2 <- std_kayit("M2", fit_M2, q, sag_m2, sen_temel(s_vek = s_izgara))
st_M1 <- std_kayit("M1", fit_M1, q, sag_m1, sen_temel())
st_M3 <- std_kayit("M3", fit_M3, q, sag_m3, sen_temel())
E_M2 <- e_hesap(st_M2$P)
E_tum <- rbind(e_ozet(E_M2, st_M2$zincir_no, "M2"), e_ozet(e_hesap(st_M1$P), st_M1$zincir_no, "M1"), e_ozet(e_hesap(st_M3$P), st_M3$zincir_no, "M3"),
               e_ozet(E_M2, st_M2$zincir_no, "M2", rope = 1), e_ozet(E_M2, st_M2$zincir_no, "M2", rope = 3))
print(E_tum[, .(model, buyukluk, rope, tahmin = round(tahmin, 2), alt = round(alt, 2), ust = round(ust, 2), p_alt = round(p_alt, 3), p_ic = round(p_ic, 3), p_ust = round(p_ust, 3),
                mcse_tahmin = round(mcse_tahmin, 3), mcse_p = round(pmax(mcse_p_alt, mcse_p_ic, mcse_p_ust, na.rm = TRUE), 4))])
P_tum <- rbind(p_ozet(st_M2$P[, c("M", "F", "D0.10", "D0.50", "D0.90")], "M2", st_M2$zincir_no), p_ozet(st_M1$P, "M1", st_M1$zincir_no), p_ozet(st_M3$P, "M3", st_M3$zincir_no))
prot_ekle("M1–M3", "Monte Carlo hatası, standartlaştırılmış olasılıklar", "p_M, p_D(0,1), p_D(0,5), p_D(0,9), p_F medyan ve aralık sınırlarında MCSE < 0,1 puan",
          sprintf("en büyük MCSE: medyan %.3f, sınır %.3f", max(P_tum$mcse_tahmin), max(P_tum$mcse_sinir)), if (max(P_tum$mcse_tahmin, P_tum$mcse_sinir) < 0.1) "kabul" else "sınır MCSE'si 0,1'in üstünde; tabloda raporlandı")
e4_sapma <- max(vapply(list(st_M1$P, st_M2$P, st_M3$P), function(P) { E <- e_hesap(P); max(abs(E[, "E4"] - (E[, "E3a"] + E[, "E2"] - E[, "E3b"]))) }, 0))
prot_ekle("M1–M3", "E4 özdeşliği", "her çekilişte |E4 − (E3a + E2 − E3b)| < 1e−9 puan; e_hesap() bütün modellerde denetler, sağlanmazsa betik durur",
          sprintf("en büyük sapma %.1e puan", e4_sapma), "sağlandı")
for (m in c("M1", "M2", "M3")) {
  x <- E_tum[model == m & rope == 2]
  prot_ekle(m, "Monte Carlo hatası", "E1–E4 medyan ve aralık sınırlarında MCSE < 0,1 puan; ROPE olasılıklarında < 0,01",
            sprintf("en büyük MCSE: tahmin %.3f, sınır %.3f, olasılık %.4f", max(x$mcse_tahmin), max(x$mcse_alt, x$mcse_ust), max(x$mcse_p_alt, x$mcse_p_ic, x$mcse_p_ust, na.rm = TRUE)),
            if (max(x$mcse_tahmin, x$mcse_alt, x$mcse_ust) < 0.1 & max(x$mcse_p_alt, x$mcse_p_ic, x$mcse_p_ust, na.rm = TRUE) < 0.01) "kabul" else "iterasyon artırılmalı",
            onceden = "talimat (6.3); sınırlara genişletme analistin, ilk geçişten sonra (K14)")
}
egri <- data.table(s = s_izgara, tahmin = apply(st_M2$P[, sen_ad_D], 2, median), alt = apply(st_M2$P[, sen_ad_D], 2, quantile, 0.025), ust = apply(st_M2$P[, sen_ad_D], 2, quantile, 0.975))
egri[, destek_ici := s >= egri_aralik[1] - 1e-9 & s <= egri_aralik[2] + 1e-9]
egri[, `:=`(alt80 = apply(st_M2$P[, sen_ad_D], 2, quantile, 0.10), ust80 = apply(st_M2$P[, sen_ad_D], 2, quantile, 0.90), alt50 = apply(st_M2$P[, sen_ad_D], 2, quantile, 0.25), ust50 = apply(st_M2$P[, sen_ad_D], 2, quantile, 0.75))]
egri_genlik <- apply(st_M2$P[, sen_ad_D[egri$destek_ici], drop = FALSE], 1, function(x) max(x) - min(x))
egri_genlik_ozet <- data.table(s_alt = min(egri[destek_ici == TRUE, s]), s_ust = max(egri[destek_ici == TRUE, s]), medyan = median(egri_genlik), alt = unname(quantile(egri_genlik, 0.025)),
                               ust = unname(quantile(egri_genlik, 0.975)), p_2_ustu = mean(egri_genlik > 2), p_3_ustu = mean(egri_genlik > 3))
print(egri_genlik_ozet, digits = 3)
fwrite(egri_genlik_ozet, "Results/denetim/egri_genligi.csv")
fwrite(egri, file.path(ddir, "figur_verileri", "fig2a_egri.csv"))
fwrite(P_tum[model == "M2"], file.path(ddir, "figur_verileri", "fig2a_noktalar.csv"))
qd <- q[G == "D"]
yog_s <- density(qd$s, weights = qd$w_norm / sum(qd$w_norm), from = 0, to = 1, n = 201, bw = "SJ")
fwrite(data.table(s = yog_s$x, yogunluk = yog_s$y, n = nrow(qd), p025 = egri_aralik[1], p975 = egri_aralik[2]), file.path(ddir, "figur_verileri", "fig2a_pay_yogunlugu.csv"))
sz <- as.numeric(as.matrix(as_draws_matrix(fit_M2, variable = "sd_zincir__Intercept")))
sz_yog <- density(sz, from = 0, to = 6, n = 601)
fwrite(data.table(sigma = sz_yog$x, posterior = sz_yog$y, prior_hn1 = 2 * dnorm(sz_yog$x, 0, 1), prior_hn2 = 2 * dnorm(sz_yog$x, 0, 2), prior_hn5 = 2 * dnorm(sz_yog$x, 0, 5)), file.path(ddir, "figur_verileri", "figS_sigma_zincir.csv"))
sz_ozet <- data.table(model = "M2", medyan = median(sz), alt = quantile(sz, 0.025), ust = quantile(sz, 0.975), rho_medyan = median(sz^2 / (sz^2 + pi^2 / 3)),
                      rho_alt = quantile(sz^2 / (sz^2 + pi^2 / 3), 0.025), rho_ust = quantile(sz^2 / (sz^2 + pi^2 / 3), 0.975), daralma = 1 - var(sz) / (1 - 2 / pi))
print(sz_ozet)
fwrite(sz_ozet, "Results/denetim/sigma_zincir_ozeti.csv")
prot_ekle("M2", "σ_zincir öğrenimi", "posterior varyansının HalfNormal(0, 1) varyansına oranı; daralma < 0,5 ise zayıf öğrenilmiş sayılır",
          sprintf("medyan %.3f (%.3f–%.3f); daralma %.3f", sz_ozet$medyan, sz_ozet$alt, sz_ozet$ust, sz_ozet$daralma), if (sz_ozet$daralma < 0.5) "zayıf öğrenilmiş: HalfNormal(0, 2) ile tekrar (B14) ana metinde" else "yeterince öğrenilmiş; B14 duyarlılık",
          onceden = "talimat (kural); 0,5 eşiği analistin, sonuçlardan önce (K11)")
sz_cakisma <- mean(sz > qnorm(0.995))
prot_ekle("M2", "σ_zincir prior–veri çatışması", "posterior kütlesinin HalfNormal(0, 1)'in 99. yüzdeliğinin (2,58) üstündeki payı; > 0,5 ise çatışma",
          sprintf("pay %.3f", sz_cakisma), if (sz_cakisma > 0.5) "çatışma: HalfNormal(0, 2) ve (sonuç sonrası) HalfNormal(0, 5) ile karşılaştırılır; E1–E4 maddi değişirse ana metinde" else "çatışma yok", onceden = "sonuç sonrası (K13, K16)")
ppc_dosya <- file.path(odir, paste0("ppc_M2_", cek_ozeti(fit_M2, q$Y, as.character(q$zincir), q$w_norm, kod_ozeti(ppc_hesap)), ".rds"))
if (!file.exists(ppc_dosya)) saveRDS(ppc_hesap(fit_M2, q, "M2"), ppc_dosya)
ppc_M2 <- readRDS(ppc_dosya)
pp_y <- ppc_M2[kontrol %in% c("G_yil", "pay", "ibbs2")]
pp_z <- ppc_M2[grepl("^zincir_ici", kontrol)]
prot_ekle("M2", "posterior öngörü", "gözlenen ağırlıklı yaygınlıklar (yıl × G, pay aralıkları, İBBS-2) %95 öngörü aralığında; iki ve üç kayıtlı zincirlerde aynı sonuç oranı",
          sprintf("%d/%d yaygınlık aralık içinde, en küçük ppp %.3f; aynı sonuç: %s", pp_y[gozlenen >= rep_alt & gozlenen <= rep_ust, .N], nrow(pp_y), min(pmin(pp_y$ppp, 1 - pp_y$ppp)),
                  paste(sprintf("%s gözlenen %.1f, tekrarlanan %.1f (%.1f–%.1f), ppp %.3f", pp_z$grup, pp_z$gozlenen, pp_z$rep_medyan, pp_z$rep_alt, pp_z$rep_ust, pp_z$ppp), collapse = "; ")),
          "yaygınlıklar uyumlu; tekrar bağımlılığı eksik üretiliyor: sınırlılık (Rapor Bölüm 12)")
print(ppc_M2[kontrol != "ibbs2"], digits = 3)
fwrite(ppc_M2, "Results/denetim/ppc_M2.csv")
fwrite(ppc_M2, file.path(ddir, "figur_verileri", "figS_ppc.csv"))
for (m in c("M1", "M2", "M3")) model_ozet_yaz(get(paste0("fit_", m)), m)
e_capa <- function(P, a) {
  ka <- sprintf("D%.2f", a)
  kb <- sprintf("D%.2f", 1 - a)
  cbind(E1 = (P[, ka] + P[, kb]) / 2 - P[, "D0.50"], E2 = P[, kb] - P[, ka], E3a = P[, "F"] - P[, kb], E3b = P[, "M"] - P[, ka], E4 = P[, "F"] - P[, "M"])
}
E_capa <- rbind(e_ozet(e_capa(st_M2$P, 0.25), st_M2$zincir_no, "C19_capa25"), e_ozet(e_capa(st_M2$P, 0.2), st_M2$zincir_no, "C19_capa20"))
print(E_capa[, .(model, buyukluk, tahmin = round(tahmin, 2), alt = round(alt, 2), ust = round(ust, 2))])
fwrite(E_capa, "Results/E_capa_duyarliligi.csv")
c19_olcek <- rbindlist(lapply(c(0.25, 0.2), function(a) {
  k <- E_capa[model == sprintf("C19_capa%d", round(100 * a))]
  carpan <- c(E1 = ((0.5 - 0.1) / (0.5 - a))^2, E2 = 0.8 / (1 - 2 * a))
  data.table(model = k$model[1], buyukluk = names(carpan), carpan = round(carpan, 3),
             genislik = round(k[match(names(carpan), buyukluk), ust - alt], 2),
             olcekli_genislik = round(k[match(names(carpan), buyukluk), ust - alt] * carpan, 1),
             M2_genislik = round(E_tum[model == "M2" & rope == 2][match(names(carpan), buyukluk), ust - alt], 1))
}))
print(c19_olcek)
fwrite(E_tum, "Results/E_tahminleri_ana.csv")
sure_ekle("M1–M3 standartlaştırma", t0)

t0 <- Sys.time()
fd_kat <- c(emekli = "emekli", issiz = "issiz", diger = "diger_faal_olmayan", calisti = "calisti_kazancsiz")
for (k in names(fd_kat)) q[, (paste0("gF_", k)) := as.integer(G == "F" & e_durum_gy == fd_kat[[k]])]
stopifnot(q[, all(gF == gF_emekli + gF_issiz + gF_diger + gF_calisti)])
g_sutun_fd <- c("gM", paste0("gF_", names(fd_kat)), paste0("fs", 1:4))
sag_fd <- c(g_sutun_fd, kov_gelir, kov_m1)
iter_fd <- 11000L
fit_FD <- model_protokol("M2_Fdurum", q, sag_fd, iter = iter_fd, csv_sakla = TRUE)
tam_tani <- rbind(tam_tani, tani_tam(fit_FD, "M2_Fdurum"))
fwrite(tam_tani, "Results/denetim/model_tanilari_tum_parametreler.csv")
model_ozet_yaz(fit_FD, "M2_Fdurum")
bos_fd <- setNames(rep(0, length(g_sutun_fd)), g_sutun_fd)
fd_sonuc <- rbindlist(lapply(names(fd_kat), function(k) {
  hedef <- q[G == "F" & e_durum_gy == fd_kat[[k]]]
  sen <- list(F_k = matrix(replace(bos_fd, paste0("gF_", k), 1), 1, dimnames = list(NULL, g_sutun_fd)),
              D0.90 = matrix(replace(bos_fd, paste0("fs", 1:4), fs_nokta(0.9)[1, ]), 1, dimnames = list(NULL, g_sutun_fd)),
              D0.75 = matrix(replace(bos_fd, paste0("fs", 1:4), fs_nokta(0.75)[1, ]), 1, dimnames = list(NULL, g_sutun_fd)),
              M = matrix(replace(bos_fd, "gM", 1), 1, dimnames = list(NULL, g_sutun_fd)))
  st <- std_kayit(paste0("Fdurum_", k), fit_FD, hedef, sag_fd, sen, gs = g_sutun_fd)
  oz <- e_ozet(cbind(E3a = st$P[, "F_k"] - st$P[, "D0.90"]), st$zincir_no, paste0("Fdurum_", k))
  e75 <- e_ozet(cbind(E = st$P[, "F_k"] - st$P[, "D0.75"]), st$zincir_no, "x")
  eM <- e_ozet(cbind(E = st$P[, "F_k"] - st$P[, "M"]), st$zincir_no, "x")
  cbind(data.table(kategori = k, n = nrow(hedef), olay = sum(hedef$Y), ham_yayginlik = 100 * sum(hedef$w_norm * hedef$Y) / sum(hedef$w_norm),
                   E075_tahmin = e75$tahmin, E075_alt = e75$alt, E075_ust = e75$ust, EM_tahmin = eM$tahmin, EM_alt = eM$alt, EM_ust = eM$ust,
                   ek_mcse = max(e75$mcse_tahmin, e75$mcse_alt, e75$mcse_ust, eM$mcse_tahmin, eM$mcse_alt, eM$mcse_ust),
                   pF_tahmin = median(st$P[, "F_k"]), pF_alt = quantile(st$P[, "F_k"], 0.025), pF_ust = quantile(st$P[, "F_k"], 0.975),
                   pD09_tahmin = median(st$P[, "D0.90"]), pD09_alt = quantile(st$P[, "D0.90"], 0.025), pD09_ust = quantile(st$P[, "D0.90"], 0.975)), oz)
}))
fd_sonuc[, isaret := fcase(n < 20, "verilmez", n <= 50, "20–50", default = "")]
print(fd_sonuc[, .(kategori, n, olay, ham = round(ham_yayginlik, 1), pF = round(pF_tahmin, 1), pD09 = round(pD09_tahmin, 1), E3a = round(tahmin, 1), alt = round(alt, 1), ust = round(ust, 1), p_alt = round(p_alt, 3), p_ic = round(p_ic, 3), p_ust = round(p_ust, 3))])
prot_ekle("M2_Fdurum", "Monte Carlo hatası", "E3a,k medyan ve aralık sınırlarında MCSE < 0,1 puan; olasılıklarda < 0,01",
          sprintf("en büyük MCSE: tahmin %.3f, sınır %.3f, olasılık %.4f", max(fd_sonuc$mcse_tahmin), max(fd_sonuc$mcse_alt, fd_sonuc$mcse_ust), max(fd_sonuc$mcse_p_alt, fd_sonuc$mcse_p_ic, fd_sonuc$mcse_p_ust, na.rm = TRUE)),
          if (max(fd_sonuc$mcse_tahmin, fd_sonuc$mcse_alt, fd_sonuc$mcse_ust) < 0.1 & max(fd_sonuc$mcse_p_alt, fd_sonuc$mcse_p_ic, fd_sonuc$mcse_p_ust, na.rm = TRUE) < 0.01) "kabul" else "sınır MCSE'si 0,1'in üstünde; tabloda raporlandı",
          onceden = "talimat (6.3); sınırlara genişletme analistin (K14)")
prot_ekle("M2_Fdurum", "Monte Carlo hatası, ek karşılaştırmalar", "p_F,k − p_D(0,75) ve p_F,k − p_M medyan ve aralık sınırlarında MCSE < 0,1 puan",
          sprintf("en büyük MCSE %.3f", max(fd_sonuc$ek_mcse)), if (max(fd_sonuc$ek_mcse) < 0.1) "kabul" else "sınır MCSE'si 0,1'in üstünde; tabloda raporlandı", onceden = "sonuç sonrası (K20)")
fwrite(fd_sonuc, "Results/ikincil_koca_durumu.csv")
fwrite(fd_sonuc, file.path(ddir, "figur_verileri", "fig3a_koca_durumu.csv"))
sure_ekle("ikincil: kocanın durumu", t0)

t0 <- Sys.time()
c1 <- c(`2023` = 1, `2024` = -1, `2025` = 0) / sqrt(2)
c2 <- c(`2023` = 1, `2024` = 1, `2025` = -2) / sqrt(6)
q[, `:=`(gM_c1 = gM * c1[as.character(yil)], gM_c2 = gM * c2[as.character(yil)], gF_c1 = gF * c1[as.character(yil)], gF_c2 = gF * c2[as.character(yil)])]
sd_d <- 0.5 / sqrt(2 / 3)
g_sutun_yil <- c(g_sutun, "gM_c1", "gM_c2", "gF_c1", "gF_c2")
sag_yil <- c(sag_m2, "gM_c1", "gM_c2", "gF_c1", "gF_c2")
pr_yil <- do.call(c, lapply(c("gM_c1", "gM_c2", "gF_c1", "gF_c2"), function(k) prior_string(sprintf("normal(0, %.6f)", sd_d), class = "b", coef = k)))
iter_yil <- 10000L
fit_YIL <- model_protokol("M2_yil", q, sag_yil, ek_prior = pr_yil, iter = iter_yil, csv_sakla = TRUE)
tam_tani <- rbind(tam_tani, tani_tam(fit_YIL, "M2_yil"))
fwrite(tam_tani, "Results/denetim/model_tanilari_tum_parametreler.csv")
model_ozet_yaz(fit_YIL, "M2_yil")
bm_y <- as.matrix(as_draws_matrix(fit_YIL, variable = "^b_g[MF]", regex = TRUE))
yil_d <- rbindlist(lapply(c("M", "F"), function(k) rbindlist(lapply(2023:2025, function(tt) {
  dd <- c1[as.character(tt)] * bm_y[, paste0("b_g", k, "_c1")] + c2[as.character(tt)] * bm_y[, paste0("b_g", k, "_c2")]
  de <- bm_y[, paste0("b_g", k)] + dd
  data.table(kose = k, yil = tt, olcek = c("d_k,t (logit)", "delta_k + d_k,t (logit)"), tahmin = c(median(dd), median(de)), alt = c(quantile(dd, 0.025), quantile(de, 0.025)), ust = c(quantile(dd, 0.975), quantile(de, 0.975)))
}))))
yil_P <- list()
yil_turet <- function(P) cbind(P[, c("M", "D0.10", "D0.50", "D0.90", "F")], egim_01_05 = P[, "D0.10"] - P[, "D0.50"], E3b = P[, "M"] - P[, "D0.10"])
yil_E <- rbindlist(lapply(2023:2025, function(tt) {
  hedef <- q[yil == tt]
  ck <- as.character(tt)
  sen <- sen_temel(g_sutun_yil)
  sen$M[, c("gM_c1", "gM_c2")] <- c(c1[ck], c2[ck])
  sen$F[, c("gF_c1", "gF_c2")] <- c(c1[ck], c2[ck])
  st <- std_kayit(paste0("yil_", tt), fit_YIL, hedef, sag_yil, sen, gs = g_sutun_yil)
  yil_P[[ck]] <<- p_ozet(yil_turet(st$P), "M2_yil", st$zincir_no)[, yil := tt]
  e_ozet(e_hesap(st$P), st$zincir_no, paste0("M2_yil_", tt))[, yil := tt]
}))
print(yil_d, digits = 3)
print(yil_E[, .(yil, buyukluk, tahmin = round(tahmin, 2), alt = round(alt, 2), ust = round(ust, 2))])
fwrite(yil_d, "Results/ikincil_yil_logit.csv")
yil_mcse_p <- max(yil_E$mcse_p_alt, yil_E$mcse_p_ic, yil_E$mcse_p_ust, na.rm = TRUE)
prot_ekle("M2_yil", "Monte Carlo hatası", "yıla özgü E1–E4 medyan ve aralık sınırlarında MCSE < 0,1 puan; ROPE olasılıklarında < 0,01",
          sprintf("en büyük MCSE: tahmin %.3f, sınır %.3f, olasılık %.4f", max(yil_E$mcse_tahmin), max(yil_E$mcse_alt, yil_E$mcse_ust), yil_mcse_p),
          if (max(yil_E$mcse_tahmin, yil_E$mcse_alt, yil_E$mcse_ust) < 0.1 & yil_mcse_p < 0.01) "kabul" else "sınır MCSE'si 0,1'in üstünde; tabloda raporlandı")
fwrite(yil_E, "Results/ikincil_yil_E.csv")
sure_ekle("ikincil: yıllar", t0)

t0 <- Sys.time()
ek1_modeller <- c("X1_tze", "X1_tze_sabit", "X2_A", "X2_Ap")
ek1_onceden <- "sonuç sonrası; yönler Ek 1'de model kurulmadan ilan edildi (K24)"
tze_dugum <- function(x, w) {
  aday <- list(tum = unname(wq(x, w, c(1, 2) / 3)), pozitif = unname(wq(x[x > 0], w[x > 0], c(1, 2) / 3)), ara = unname(wq(x[x > 0 & x < 12], w[x > 0 & x < 12], c(1, 2) / 3)))
  gecerli <- vapply(aday, function(k) all(k > 0 & k < 12) && k[1] < k[2], TRUE)
  list(knots = aday[[which(gecerli)[1]]], sinir = c(0, 12), kural = names(aday)[which(gecerli)[1]], adaylar = aday)
}
tze_baz <- function(x, dg) {
  B <- unclass(ns(x, knots = dg$knots, Boundary.knots = dg$sinir))
  B[, seq_len(ncol(B)), drop = FALSE]
}
tz_k <- tze_dugum(q$k_tze, q$w_norm)
tz_e <- tze_dugum(q$e_tze, q$w_norm)
cat("TZE düğümleri: kadın", tz_k$knots, "(", tz_k$kural, "); koca", tz_e$knots, "(", tz_e$kural, ")\n")
write_json(list(kadin = tz_k, koca = tz_e), "Results/denetim/tze_dugumleri.json", digits = NA, auto_unbox = TRUE, pretty = TRUE)
tk_ad <- paste0("tk", 1:3)
te_ad <- paste0("te", 1:3)
q[, (tk_ad) := as.data.table(tze_baz(k_tze, tz_k))]
q[, (te_ad) := as.data.table(tze_baz(e_tze, tz_e))]
sag_x1 <- c(sag_m2, tk_ad, te_ad)
fit_X1 <- model_protokol("X1_tze", q, sag_x1, iter = iter_ana)
model_ozet_yaz(fit_X1, "X1_tze")
qD <- q[G == "D"]
sen_tze <- function(ad, dg) setNames(lapply(0:12, function(v) matrix(tze_baz(v, dg), 1, dimnames = list(NULL, ad))), paste0("t", 0:12))
st_T2k <- std_kayit("X1_T2_kadin", fit_X1, qD, sag_x1, sen_tze(tk_ad, tz_k), gs = tk_ad)
st_T2e <- std_kayit("X1_T2_koca", fit_X1, qD, sag_x1, sen_tze(te_ad, tz_e), gs = te_ad)
T2_cek <- cbind(T2 = st_T2k$P[, "t12"] - st_T2k$P[, "t6"], T2p = st_T2e$P[, "t12"] - st_T2e$P[, "t6"])
T2_cek <- cbind(T2_cek, T2_eksi_T2p = T2_cek[, "T2"] - T2_cek[, "T2p"])
x1_T <- e_ozet(T2_cek, st_T2k$zincir_no, "X1")
x1_egri <- rbind(p_ozet(st_T2k$P, "X1", st_T2k$zincir_no)[, `:=`(es = "kadin", tze = 0:12)], p_ozet(st_T2e$P, "X1", st_T2e$zincir_no)[, `:=`(es = "koca", tze = 0:12)])
sen_x1 <- lapply(sen_temel(c(g_sutun, tk_ad)), function(S) S[rep(1L, nrow(q)), , drop = FALSE])
tk_gozlenen <- as.matrix(q[, ..tk_ad])
for (a in names(sen_x1)) sen_x1[[a]][, tk_ad] <- if (a == "M") matrix(tze_baz(0, tz_k), nrow(q), length(tk_ad), byrow = TRUE) else tk_gozlenen
st_X1 <- std_kayit("X1_E", fit_X1, q, sag_x1, sen_x1, gs = c(g_sutun, tk_ad))
E_X1 <- e_ozet(e_hesap(st_X1$P), st_X1$zincir_no, "X1")
st_X1g <- std_kayit("X1_E_gozlenen", fit_X1, q, sag_x1, sen_temel(), gs = g_sutun)
E_X1g <- e_ozet(e_hesap(st_X1g$P), st_X1g$zincir_no, "X1_gozlenen")
x1_eslesme <- list(M_hane = q[G == "M", .N], D_kadin_tze_sifir = q[G == "D" & k_tze == 0, .N], M_kadin_tze_pozitif = q[G == "M" & k_tze > 0, .N])
tz_s <- list(knots = c(4, 8), sinir = c(0, 12), kural = "sabit 4 ve 8 ay (duyarlılık)")
tks_ad <- paste0("tks", 1:3)
tes_ad <- paste0("tes", 1:3)
q[, (tks_ad) := as.data.table(tze_baz(k_tze, tz_s))]
q[, (tes_ad) := as.data.table(tze_baz(e_tze, tz_s))]
sag_x1s <- c(sag_m2, tks_ad, tes_ad)
fit_X1s <- model_protokol("X1_tze_sabit", q, sag_x1s, iter = iter_ana)
model_ozet_yaz(fit_X1s, "X1_tze_sabit")
st_T2ks <- std_kayit("X1s_T2_kadin", fit_X1s, q[G == "D"], sag_x1s, sen_tze(tks_ad, tz_s), gs = tks_ad)
st_T2es <- std_kayit("X1s_T2_koca", fit_X1s, q[G == "D"], sag_x1s, sen_tze(tes_ad, tz_s), gs = tes_ad)
T2s_cek <- cbind(T2 = st_T2ks$P[, "t12"] - st_T2ks$P[, "t6"], T2p = st_T2es$P[, "t12"] - st_T2es$P[, "t6"])
x1s_T <- e_ozet(cbind(T2s_cek, T2_eksi_T2p = T2s_cek[, "T2"] - T2s_cek[, "T2p"]), st_T2ks$zincir_no, "X1_sabit")
print(E_X1g[, .(buyukluk, tahmin = round(tahmin, 2), alt = round(alt, 2), ust = round(ust, 2))])
print(x1s_T[, .(buyukluk, tahmin = round(tahmin, 2), alt = round(alt, 2), ust = round(ust, 2), p_poz = round(p_poz, 3))])
print(x1_T[, .(buyukluk, tahmin = round(tahmin, 2), alt = round(alt, 2), ust = round(ust, 2), p_alt = round(p_alt, 3), p_ic = round(p_ic, 3), p_ust = round(p_ust, 3), p_poz = round(p_poz, 3))])
print(E_X1[, .(buyukluk, tahmin = round(tahmin, 2), alt = round(alt, 2), ust = round(ust, 2))])
x1_mcse <- rbind(x1_T, E_X1, E_X1g, x1s_T)
prot_ekle("X1_tze, X1_tze_sabit", "Monte Carlo hatası", "T2, T2′, T2 − T2′ (iki düğüm kuralıyla) ve X1'de E1–E4 (iki senaryo kurgusuyla): medyan ve aralık sınırlarında MCSE < 0,1 puan; ROPE olasılıklarında < 0,01",
          sprintf("en büyük MCSE: tahmin %.3f, sınır %.3f, olasılık %.4f", max(x1_mcse$mcse_tahmin), max(x1_mcse$mcse_alt, x1_mcse$mcse_ust), max(x1_mcse$mcse_p_alt, x1_mcse$mcse_p_ic, x1_mcse$mcse_p_ust, na.rm = TRUE)),
          if (max(x1_mcse$mcse_tahmin, x1_mcse$mcse_alt, x1_mcse$mcse_ust) < 0.1 & max(x1_mcse$mcse_p_alt, x1_mcse$mcse_p_ic, x1_mcse$mcse_p_ust, na.rm = TRUE) < 0.01) "kabul" else "sınır MCSE'si 0,1'in üstünde; tabloda raporlandı",
          onceden = ek1_onceden)
prot_ekle("X1_tze", "TZE spline düğümleri", "Q'daki ağırlıklı tertiller; 0 yığılması varsa pozitif değerlerin tertilleri (Ek 1); ikisi de geçersizse 0 < TZE < 12 değerlerinin tertilleri (analist)",
          sprintf("kadın %s (%s); koca %s (%s); sınırlar 0 ve 12", paste(tz_k$knots, collapse = " / "), tz_k$kural, paste(tz_e$knots, collapse = " / "), tz_e$kural),
          "düğümler 0 ve 12'deki yığılma nedeniyle ara değerlerden; raporlandı", onceden = ek1_onceden)

for (av in c("yet_A", "yet_Ap")) q[, (paste0(av, "_", g_sutun)) := lapply(g_sutun, function(g) get(av) * get(g))]
sag_x2 <- function(av) c(sag_m2, av, paste0(av, "_", g_sutun))
x2_hucre <- rbindlist(lapply(c("yet_A", "yet_Ap"), function(av) q[, .(n = .N, olay = sum(Y), olay_yok = sum(1 - Y), ham = 100 * sum(w_norm * Y) / sum(w_norm)), keyby = .(deger = get(av), G)][, degisken := av]))
x2_dusuk <- x2_hucre[G %in% c("M", "F"), .(kesinligi_dusuk = any(olay < 50 | olay_yok < 50)), by = degisken]
print(x2_hucre)
print(x2_dusuk)
x2_kayitsiz <- q[, .(uye = sum(yet_kayitsiz), hane = sum(yet_kayitsiz > 0))]
fit_X2 <- list(yet_A = model_protokol("X2_A", q, sag_x2("yet_A"), iter = iter_ana), yet_Ap = model_protokol("X2_Ap", q, sag_x2("yet_Ap"), iter = iter_ana))
model_ozet_yaz(fit_X2$yet_A, "X2_A")
model_ozet_yaz(fit_X2$yet_Ap, "X2_Ap")
sen_A <- function(av, a) {
  ek <- paste0(av, "_", g_sutun)
  lapply(sen_temel(c(g_sutun, ek)), function(S) {
    S[, ek] <- a * S[, g_sutun]
    S
  })
}
x2_E <- list()
x2_fark <- list()
x2_etk <- list()
x2_cek <- list()
for (av in names(fit_X2)) {
  gs_a <- c(g_sutun, paste0(av, "_", g_sutun))
  E01 <- lapply(0:1, function(a) {
    st <- std_kayit(paste0("X2_", av, "_", a), fit_X2[[av]], q[get(av) == a], sag_x2(av), sen_A(av, a), gs = gs_a)
    list(E = e_hesap(st$P), z = st$zincir_no)
  })
  x2_cek[[av]] <- E01
  x2_E[[av]] <- rbind(e_ozet(E01[[1]]$E, E01[[1]]$z, paste0(av, "_0"))[, deger := 0L], e_ozet(E01[[2]]$E, E01[[2]]$z, paste0(av, "_1"))[, deger := 1L])[, degisken := av]
  x2_fark[[av]] <- e_ozet(E01[[2]]$E[, c("E3b", "E4")] - E01[[1]]$E[, c("E3b", "E4")], E01[[1]]$z, paste0(av, "_fark"))[, degisken := av]
  bi <- as.numeric(as.matrix(as_draws_matrix(fit_X2[[av]], variable = paste0("b_", av, "_gM"))))
  x2_etk[[av]] <- data.table(degisken = av, tahmin = median(bi), alt = unname(quantile(bi, 0.025)), ust = unname(quantile(bi, 0.975)), p_poz = mean(bi > 0))
}
x2_E <- rbindlist(x2_E)
x2_fark <- rbindlist(x2_fark)
x2_etk <- rbindlist(x2_etk)
x2_olcut <- rbindlist(lapply(names(fit_X2), function(av) {
  e0 <- x2_E[degisken == av & deger == 0 & buyukluk == "E3b", tahmin]
  e1 <- x2_E[degisken == av & deger == 1 & buyukluk == "E3b", tahmin]
  f <- x2_fark[degisken == av & buyukluk == "E3b"]
  data.table(degisken = av, E3b_mutlak_kuculur = abs(e1) < abs(e0), fark_araligi_sifiri_disliyor = f$alt > 0 | f$ust < 0,
             sonuc = fifelse(abs(e1) < abs(e0) & (f$alt > 0 | f$ust < 0), "ölçüt sağlandı: zaman kanalı lehine", "ayırt edemedi"))
}))
print(x2_E[buyukluk %in% c("E3b", "E4"), .(degisken, deger, buyukluk, tahmin = round(tahmin, 2), alt = round(alt, 2), ust = round(ust, 2))])
print(x2_fark[, .(degisken, buyukluk, tahmin = round(tahmin, 2), alt = round(alt, 2), ust = round(ust, 2), p_poz = round(p_poz, 3))])
print(x2_etk)
print(x2_olcut)
x2_mcse <- rbind(x2_E, x2_fark, fill = TRUE)
prot_ekle("X2_A, X2_Ap", "Monte Carlo hatası", "alt gruplarda E1–E4 ve E3b, E4 farkları: medyan ve aralık sınırlarında MCSE < 0,1 puan; ROPE olasılıklarında < 0,01",
          sprintf("en büyük MCSE: tahmin %.3f, sınır %.3f, olasılık %.4f", max(x2_mcse$mcse_tahmin), max(x2_mcse$mcse_alt, x2_mcse$mcse_ust), max(x2_mcse$mcse_p_alt, x2_mcse$mcse_p_ic, x2_mcse$mcse_p_ust, na.rm = TRUE)),
          if (max(x2_mcse$mcse_tahmin, x2_mcse$mcse_alt, x2_mcse$mcse_ust) < 0.1 & max(x2_mcse$mcse_p_alt, x2_mcse$mcse_p_ic, x2_mcse$mcse_p_ust, na.rm = TRUE) < 0.01) "kabul" else "sınır MCSE'si 0,1'in üstünde; tabloda raporlandı",
          onceden = ek1_onceden)
prot_ekle("X2_A, X2_Ap", "T3 ölçütü", "zaman kanalı lehine yorum için |E3b(A = 1)| < |E3b(A = 0)| ve farkın %95 aralığının sıfırı dışlaması (Ek 1'de model kurulmadan ilan edildi)",
          paste(sprintf("%s: %s", x2_olcut$degisken, x2_olcut$sonuc), collapse = "; "), "raporlandı", onceden = ek1_onceden)
fwrite(rbind(x1_T, E_X1, E_X1g, x1s_T), "Results/zaman_kanali_X1.csv")
fwrite(rbind(x2_E, x2_fark, fill = TRUE), "Results/zaman_kanali_X2.csv")
fwrite(x2_hucre, "Results/denetim/zaman_kanali_X2_hucreler.csv")
fwrite(x1_egri, file.path(ddir, "figur_verileri", "figS6b_tze_egrileri.csv"))
fwrite(x2_E[degisken == "yet_A" & buyukluk %in% c("E3b", "E4")], file.path(ddir, "figur_verileri", "figS6c_yetiskin.csv"))
sure_ekle("Ek 1: zaman kanalı modelleri", t0)

t0 <- Sys.time()
veri_alt <- function(x) {
  x <- copy(x)
  x[, w_norm := .N * HB040 / sum(HB040)]
  x[, zincir := droplevels(factor(zincir))]
  x[, ibbs2 := droplevels(ibbs2)]
  x
}
g_hazirla <- function(x, dug = dugum_s, G_sutun = "G") {
  x <- copy(x)
  x[, G := get(G_sutun)]
  old <- grep("^fs[0-9]+$", names(x), value = TRUE)
  if (length(old)) x[, (old) := NULL]
  B <- fs_baz(x$s, x$G, dug)
  x[, (colnames(B)) := as.data.table(B)]
  x[, `:=`(gM = as.integer(G == "M"), gF = as.integer(G == "F"))]
  x
}
yilsiz <- function(sag) setdiff(sag, "yil_f")
duy_tanim <- list()
duy_ekle <- function(kod, grup, soru, veri, sag, gs = g_sutun, dug = dugum_s, zincir = TRUE, aciklama = "", ...) {
  duy_tanim[[kod]] <<- list(kod = kod, grup = grup, soru = soru, veri = veri, sag = sag, gs = gs, dug = dug, zincir = zincir, aciklama = aciklama, ek = list(...))
}
iter_tek <- 20000L
duy_ekle("A1_2025", "A", "Tek dönem (2025) ve zincir etkisi olmadan; hedef nüfus 2025'teki Q", veri_alt(q[yil == 2025]), yilsiz(sag_m2), zincir = FALSE, iter = iter_tek)
duy_ekle("A2_2023", "A", "2023 tek başına", veri_alt(q[yil == 2023]), yilsiz(sag_m2), zincir = FALSE, iter = iter_tek)
duy_ekle("A2_2024", "A", "2024 tek başına", veri_alt(q[yil == 2024]), yilsiz(sag_m2), zincir = FALSE, iter = iter_tek)
duy_ekle("A3_ucret", "A", "Ücret örneği: iki eşte de müteşebbis geliri yok (kazancın aile işletmesinde tek eşe yazılması)", veri_alt(q[ucret_ornegi == 1]), sag_m2, iter = iter_ana)
duy_ekle("A4_ucretsiz_aile_yok", "A", "Eşlerden biri ücretsiz aile işçisi olan çiftler çıkarıldı", veri_alt(q[k_ucretsiz_aile == 0 & e_ucretsiz_aile == 0]), sag_m2)
duy_ekle("A5_tek_cift", "A", "Yalnız tek çiftli haneler", veri_alt(q[tek_cift == 1]), sag_m2)
duy_ekle("A7_TR63_yok", "A", "Üç yılda da TR63 çıkarıldı (ortak coğrafi kapsam)", veri_alt(q[HB031 != "TR63"]), sag_m2)
duy_ekle("A8_durum_uyumu", "A", "Gelir yılındaki kazanan yapısı ile görüşme anındaki çalışma durumu uyuşan çiftler (istikrarlı çalışma düzeni)", veri_alt(q[durum_uyumu == 1]), sag_m2)
ua <- g_hazirla(u)
ua[, zincir := factor(zincir_ana)]
duy_ekle("A9_tum_uygun", "A", "Ortak destek yerine bütün uygun haneler", veri_alt(ua), sag_m2, iter = iter_ana)
ut <- h[uygun_tumyas == 1]
bazlari_ekle(ut)
c5_ata(ut)
od6 <- ortak_destek(ut, "tum_yaslar")
fwrite(od6$sinir, "Results/denetim/ortak_destek_sinirlari_tum_yaslar.csv")
ut[, Q := od6$Q]
cat("A6 tüm yaşlar: uygun", nrow(ut), "Q", sum(ut$Q), "\n")
q6 <- g_hazirla(ut[Q == 1])
q6[, zincir := factor(zincir_ana)]
duy_ekle("A6_tum_yaslar", "A", "Tüm yaşlar (iki eş de 18+; 65+ çiftler dahil), kendi ortak desteğiyle", veri_alt(q6), sag_m2)
duy_ekle("B10_agirliksiz", "B", "Ağırlıksız Bayesçi model; standartlaştırma HB040 ağırlıklı", q, sag_m2, agirlikli = FALSE, iter = iter_ana)
duy_ekle("B12_zincirsiz", "B", "Zincir etkisi olmadan (kayıtlar bağımsız)", q, sag_m2, zincir = FALSE)
q_imza <- copy(q)[, zincir := factor(zincir_imza)]
q_reis <- copy(q)[, zincir := factor(zincir_ana_reis)]
duy_ekle("B13_imza", "B", "Bağlantı kuralı: yalnız üye imzası", q_imza, sag_m2)
duy_ekle("B13_ana_reis", "B", "Bağlantı kuralı: ana kural + hane reisi anahtarı", q_reis, sag_m2)
duy_ekle("B14_sigma2", "B", "σ_zincir prior'ı HalfNormal(0, 2)", q, sag_m2, sd_zincir = 2)
duy_ekle("B14b_sigma5", "B", "σ_zincir prior'ı HalfNormal(0, 5): önsel–veri çatışması tanısı (M2 sonuçları görüldükten sonra eklendi)", q, sag_m2, sd_zincir = 5)
q_bolge <- copy(q)[, zincir := factor(zincir_ana_bolge)]
duy_ekle("B13_ana_bolge", "B", "Bağlantı kuralı: yalnız imzayla kurulan bağlarda aynı İBBS-2 koşulu (iç denetim önerisi, sonuç sonrası)", q_bolge, sag_m2)
qk <- copy(q)
qk[, w_norm := kish(HB040) * HB040 / sum(HB040)]
duy_ekle("B15_kish", "B", "Ağırlıklar Kish etkin örneklem büyüklüğüne normalize edildi (iç denetim önerisi, sonuç sonrası)", qk, sag_m2)
u3 <- copy(u)
u3[, C3 := G]
od3 <- ortak_destek(u3, "uc_kategori", "C3", c("M", "D", "F"))
fwrite(od3$sinir, "Results/denetim/ortak_destek_sinirlari_uc_kategori.csv")
q3 <- g_hazirla(u3[od3$Q == 1])
q3[, zincir := factor(zincir_ana)]
a10_dis <- round(100 * u3[od3$Q == 0, sum(HB040)] / u3[, sum(HB040)], 1)
cat("A10 üç kategorili ortak destek: uygun", nrow(u3), "Q3", nrow(q3), "; dışarıda ağırlıklı %", a10_dis, "\n")
duy_ekle("A10_destek3", "A", "Ortak destek üç kategoriyle (M, D, F) tanımlandı (iç denetim önerisi, sonuç sonrası)", veri_alt(q3), sag_m2)
duy_ekle("A11_esit_haric", "A", "Kazançları birebir eşit (|E_k − E_e| < 1 TL) iki kazançlı çiftler çıkarıldı (iç denetim önerisi, sonuç sonrası)", veri_alt(q[!(G == "D" & abs(E_k - E_e) < 1)]), sag_m2)
q15 <- copy(q)
q15[, G15 := fcase(G == "D" & s < 0.05, "M", G == "D" & s > 0.95, "F", default = G)]
dug15 <- unname(wq(q15[G15 == "D", s], q15[G15 == "D", w_norm], c(0.25, 0.5, 0.75)))
q15 <- g_hazirla(q15, dug15, "G15")
duy_ekle("C15_esik5", "C", "Kazanan eşiği: payı < %5 olan M, > %95 olan F sayıldı", q15, sag_m2, dug = dug15)
duy_ekle("C16_O_izk", "C", "O yerine izafi kira hariç O", q, c(g_sutun, paste0("gE", 1:4), paste0("hOizk", 1:3), kov_m1))
duy_ekle("C17_esdeger", "C", "g(E) ve h(O) yerine eşdeğer hane gelirinin yıl medyanına oranı (asinh, spline)", q, c(g_sutun, paste0("esd", 1:4), kov_m1))
dug3 <- unname(wq(q[G == "D", s], q[G == "D", w_norm], c(1 / 3, 2 / 3)))
dug5 <- unname(wq(q[G == "D", s], q[G == "D", w_norm], c(0.2, 0.4, 0.6, 0.8)))
q_df3 <- g_hazirla(q, dug3)
q_df5 <- g_hazirla(q, dug5)
dug_sabit <- c(0.25, 0.5, 0.75)
q_sabit <- g_hazirla(q, dug_sabit)
duy_ekle("C18_fs_sabit", "C", "f(s) iç düğümleri sabit 0,25 / 0,5 / 0,75 (iç denetim önerisi, sonuç sonrası)", q_sabit, sag_m2, dug = dug_sabit)
duy_ekle("C18_fs_df3", "C", "f(s) df 3 (iç düğümler ağırlıklı 33,3. ve 66,7. yüzdelik)", q_df3, c("gM", "gF", paste0("fs", 1:3), kov_gelir, kov_m1), gs = c("gM", "gF", paste0("fs", 1:3)), dug = dug3)
duy_ekle("C18_fs_df5", "C", "f(s) df 5 (iç düğümler ağırlıklı 20., 40., 60., 80. yüzdelik)", q_df5, c("gM", "gF", paste0("fs", 1:5), kov_gelir, kov_m1), gs = c("gM", "gF", paste0("fs", 1:5)), dug = dug5)
fs_prior <- function(sdv) do.call(c, lapply(paste0("fs", 1:4), function(k) prior_string(sprintf("normal(0, %s)", sdv), class = "b", coef = k)))
duy_ekle("C20_fs_prior05", "C", "f(s) katsayılarının prior'ı N(0, 0,5) (iç denetim önerisi, sonuç sonrası)", q, sag_m2, ek_prior = fs_prior(0.5))
duy_ekle("C20_fs_prior2", "C", "f(s) katsayılarının prior'ı N(0, 2) (iç denetim önerisi, sonuç sonrası)", q, sag_m2, ek_prior = fs_prior(2))
duy_ekle("C21_b25", "C", "Bütün katsayıların prior'ı N(0, 2,5) (iç denetim önerisi, sonuç sonrası)", q, sag_m2, sd_b = 2.5)
duy_ekle("C21_b5", "C", "Bütün katsayıların prior'ı N(0, 5) (iç denetim önerisi, sonuç sonrası)", q, sag_m2, sd_b = 5)
capa_say <- rbindlist(lapply(list(Q = q, A9_tum_uygun = ua, A10_destek3 = q3), function(x) x[G == "D", .(D = .N, s_005_015 = sum(s >= 0.05 & s <= 0.15), s_045_055 = sum(s >= 0.45 & s <= 0.55), s_085_095 = sum(s >= 0.85 & s <= 0.95))]), idcol = "orneklem")
print(capa_say)
fwrite(capa_say, "Results/denetim/capa_destegi_Q_A9_A10.csv")
duy_dugum <- data.table(analiz = c("C15_esik5", "C18_fs_df3", "C18_fs_df5"), dugumler = c(paste(round(dug15, 4), collapse = "; "), paste(round(dug3, 4), collapse = "; "), paste(round(dug5, 4), collapse = "; ")))
fwrite(duy_dugum, "Results/denetim/duyarlilik_dugumleri.csv")
duy_sonuc <- list()
kb_c21 <- list()
ppc_ek <- list()
sigma_ek <- list()
sigma_yog <- list()
for (kod in names(duy_tanim)) {
  dt <- duy_tanim[[kod]]
  args <- c(list(ad = kod, veri = dt$veri, sag = dt$sag, zincir = dt$zincir), dt$ek)
  fit_d <- do.call(model_protokol, args)
  if (kod %in% c("C21_b25", "C21_b5")) kb_c21[[kod]] <- as.data.table(summarise_draws(as_draws_matrix(fit_d, variable = "^b_", regex = TRUE), "median", "sd"))[variable != "b_Intercept"][, model := kod]
  sen <- sen_temel(dt$gs, dug = dt$dug)
  st <- std_kayit(kod, fit_d, dt$veri, dt$sag, sen, gs = dt$gs, zincir = dt$zincir)
  duy_sonuc[[kod]] <- e_ozet(e_hesap(st$P), st$zincir_no, kod)[, `:=`(grup = dt$grup, soru = dt$soru, n = nrow(dt$veri), olay = sum(dt$veri$Y), aralik = "posterior")]
  if (kod %in% c("A2_2023", "A2_2024", "A1_2025")) yil_P[[kod]] <- p_ozet(yil_turet(st$P), "tek_yil", st$zincir_no)[, yil := as.integer(sub("^A[12]_", "", kod))]
  if (kod %in% c("B14_sigma2", "B14b_sigma5", "B12_zincirsiz", "B13_imza", "B13_ana_reis", "B10_agirliksiz")) {
    pd <- file.path(odir, paste0("ppc_", kod, "_", cek_ozeti(fit_d, dt$veri$Y, as.character(dt$veri$zincir), dt$veri$w_norm, kod_ozeti(ppc_hesap)), ".rds"))
    if (!file.exists(pd)) saveRDS(ppc_hesap(fit_d, dt$veri, kod), pd)
    ppc_ek[[kod]] <- readRDS(pd)
    if (dt$zincir) {
      szd <- as.numeric(as.matrix(as_draws_matrix(fit_d, variable = "sd_zincir__Intercept")))
      sigma_ek[[kod]] <- data.table(model = kod, medyan = median(szd), alt = quantile(szd, 0.025), ust = quantile(szd, 0.975), rho_medyan = median(szd^2 / (szd^2 + pi^2 / 3)))
      dz <- density(szd, from = 0, to = 6, n = 601)
      sigma_yog[[kod]] <- data.table(model = kod, sigma = dz$x, posterior = dz$y)
    }
  }
  model_ozet_yaz(fit_d, kod)
  rm(fit_d)
  invisible(gc())
  cat(kod, "tamam:", format(Sys.time()), "\n")
}
ppc_ek <- rbindlist(ppc_ek)
sigma_ek <- rbind(sz_ozet[, .(model, medyan, alt, ust, rho_medyan)], rbindlist(sigma_ek))
print(sigma_ek, digits = 3)
print(rbind(ppc_M2, ppc_ek)[kontrol == "zincir_ici_ayni_sonuc", .(model, tekrar, gozlenen, rep_medyan, rep_alt, rep_ust, ppp)], digits = 3)
fwrite(ppc_ek, "Results/denetim/ppc_duyarlilik.csv")
yil_olas <- rbindlist(yil_P)
print(dcast(yil_olas, model + senaryo ~ yil, value.var = "tahmin"), digits = 3)
fwrite(yil_olas, "Results/ikincil_yil_olasiliklar.csv")
kb_kars <- dcast(rbind(kb_m2[, model := "M2"], rbindlist(kb_c21)), variable ~ model, value.var = c("median", "sd"))
fwrite(kb_kars, "Results/denetim/katsayi_prior_catisma_M2.csv")
fwrite(rbind(ppc_M2, ppc_ek)[kontrol == "zincir_ici_ayni_sonuc"], file.path(ddir, "figur_verileri", "figS_ppc_zincir.csv"))
fwrite(sigma_ek, "Results/denetim/sigma_zincir_duyarlilik.csv")
fwrite(rbindlist(sigma_yog), file.path(ddir, "figur_verileri", "figS_sigma_zincir_duyarlilik.csv"))
sure_ekle("duyarlılık: Bayesçi", t0)

t0 <- Sys.time()
suppressPackageStartupMessages(library(survey))
sv_dosya <- file.path(odir, paste0("survey_B11_", substr(rlang::hash(list(q$Y, q$HB040, q$zincir_ana, x_kur(q, c(sag_m2, "ibbs2")), 1000L, 20261033L, kod_ozeti(e_hesap), kod_ozeti(sen_temel), sv_surum)), 1, 10), ".rds"))
if (!file.exists(sv_dosya)) {
  qs <- copy(q)
  des <- svydesign(ids = ~zincir_ana, weights = ~HB040, data = qs)
  sv_form <- as.formula(paste("Y ~", paste(c(sag_m2, "ibbs2"), collapse = " + ")))
  sg <- svyglm(sv_form, design = des, family = quasibinomial())
  X0 <- model.matrix(sg)
  gk <- match(g_sutun, colnames(X0))
  sen <- sen_temel()
  S_mat <- do.call(rbind, lapply(sen, function(S) S[, g_sutun]))
  E_bul <- function(beta, w) {
    eta0 <- drop(X0 %*% beta) - drop(X0[, gk] %*% beta[gk])
    p <- vapply(seq_len(nrow(S_mat)), function(a) 100 * sum(w * plogis(eta0 + sum(S_mat[a, ] * beta[gk]))) / sum(w), 0)
    names(p) <- names(sen)
    drop(e_hesap(matrix(p, nrow = 1, dimnames = list(NULL, names(p)))))
  }
  E_nokta <- E_bul(coef(sg), qs$HB040)
  set.seed(20261033)
  rdes <- as.svrepdesign(des, type = "bootstrap", replicates = 1000)
  W <- weights(rdes, type = "analysis")
  parcalar <- split(seq_len(ncol(W)), cut(seq_len(ncol(W)), 16, labels = FALSE))
  b0 <- coef(sg)
  rep_E <- do.call(rbind, future_map(parcalar, function(jj) {
    t(vapply(jj, function(r) {
      wr <- W[, r]
      f <- suppressWarnings(glm.fit(X0, qs$Y, weights = wr / mean(wr), family = quasibinomial(), start = b0, control = glm.control(epsilon = 1e-10, maxit = 100)))
      c(E_bul(f$coefficients, wr), yakinsadi = as.numeric(f$converged))
    }, numeric(6)))
  }, .options = furrr_options(seed = NULL, globals = c("W", "X0", "qs", "b0", "E_bul", "gk", "S_mat", "sen", "e_hesap"))))
  saveRDS(list(E_nokta = E_nokta, rep_E = rep_E, scale = rdes$scale, rscales = rdes$rscales, mse = rdes$mse, katsayi = coef(sg), vcov = vcov(sg), n = nrow(qs), zincir = length(unique(qs$zincir_ana))), sv_dosya)
}
sv <- readRDS(sv_dosya)
cat("Survey replikatlarında yakınsamayan:", sum(sv$rep_E[, "yakinsadi"] == 0), "\n")
sv_rep <- sv$rep_E[, 1:5]
sv_se <- sqrt(diag(as.matrix(svrVar(sv_rep, sv$scale, sv$rscales, mse = sv$mse, coef = sv$E_nokta))))
duy_sonuc[["B11_survey"]] <- data.table(model = "B11_survey", buyukluk = names(sv$E_nokta), rope = NA_real_, tahmin = unname(sv$E_nokta), alt = unname(sv$E_nokta - qnorm(0.975) * sv_se),
                                        ust = unname(sv$E_nokta + qnorm(0.975) * sv_se), se = unname(sv_se), alt_yuzdelik = apply(sv_rep, 2, quantile, 0.025), ust_yuzdelik = apply(sv_rep, 2, quantile, 0.975),
                                        alt80 = unname(sv$E_nokta - qnorm(0.90) * sv_se), ust80 = unname(sv$E_nokta + qnorm(0.90) * sv_se), alt50 = unname(sv$E_nokta - qnorm(0.75) * sv_se), ust50 = unname(sv$E_nokta + qnorm(0.75) * sv_se),
                                        grup = "B", soru = "Mevcut tasarım bilgileriyle kurulmuş ağırlıklı duyarlılık modeli (svyglm, zincir kümeli; 1.000 bootstrap replikatı)", n = sv$n, olay = sum(q$Y), aralik = "güven aralığı", etiket = "B11_survey")
print(duy_sonuc[["B11_survey"]])
sure_ekle("duyarlılık: survey modeli", t0)

yuv0 <- function(x, d) { x <- round(x, d); x[!is.na(x) & x == 0] <- 0; x }
f1 <- function(x) formatC(yuv0(x, 1), format = "f", digits = 1, big.mark = ",")
f2 <- function(x) formatC(yuv0(x, 2), format = "f", digits = 2, big.mark = ",")
nfmt <- function(n) formatC(n, format = "d", big.mark = ",")
sinir_f <- function(x, d) ifelse(!is.na(x) & x < 0 & round(x, d) == 0, paste0("-", formatC(0, format = "f", digits = d)), formatC(yuv0(x, d), format = "f", digits = d))
ga <- function(e, l, u, d = 1) paste0(formatC(yuv0(e, d), format = "f", digits = d), " (", sinir_f(l, d), ", ", sinir_f(u, d), ")")
pfmt <- function(p) fifelse(is.na(p), "", fifelse(p < 0.001, "<0.001", formatC(p, format = "f", digits = 3)))
yazi_tipi_t <- "Times New Roman"
tablo_bicim <- function(ft, notlar = character(0), grup_satir = integer(0)) {
  ft <- font(ft, fontname = yazi_tipi_t, part = "all")
  ft <- fontsize(ft, size = 9, part = "all")
  ft <- border_remove(ft)
  ust <- fp_border(color = "black", width = 1)
  ince <- fp_border(color = "black", width = 0.5)
  ft <- hline_top(ft, border = ust, part = "header")
  ft <- hline_bottom(ft, border = ince, part = "header")
  ft <- hline_bottom(ft, border = ust, part = "body")
  ft <- bold(ft, part = "header")
  ft <- align(ft, align = "center", part = "header")
  ft <- align(ft, j = 1, align = "left", part = "all")
  ft <- valign(ft, valign = "center", part = "header")
  ft <- padding(ft, padding.top = 1, padding.bottom = 1, part = "all")
  if (length(grup_satir)) ft <- bold(ft, i = grup_satir, j = 1, part = "body")
  for (k in seq_along(notlar)) ft <- add_footer_lines(ft, values = notlar[k])
  if (length(notlar)) {
    ft <- fontsize(ft, size = 8, part = "footer")
    ft <- font(ft, fontname = yazi_tipi_t, part = "footer")
  }
  ft <- autofit(ft)
  ft
}
simge_re <- "(_|\\^)\\{([^}]*)\\}"
duz_csv <- function(x) gsub("\\^\\{([^}]*)\\}", " [\\1]", gsub("_\\{([^}]*)\\}", "_\\1", x))
duz <- function(x) gsub(simge_re, "\\2", x)
parcala <- function(s) {
  m <- gregexpr(simge_re, s, perl = TRUE)[[1]]
  bas <- c(1, m + attr(m, "match.length"))
  out <- list()
  for (k in seq_along(m)) {
    if (m[k] > bas[k]) out[[length(out) + 1]] <- as_chunk(substr(s, bas[k], m[k] - 1))
    tok <- substr(s, m[k], m[k] + attr(m, "match.length")[k] - 1)
    ic <- sub(simge_re, "\\2", tok)
    out[[length(out) + 1]] <- if (substr(tok, 1, 1) == "_") as_sub(ic) else as_sup(ic)
  }
  if (bas[length(bas)] <= nchar(s)) out[[length(out) + 1]] <- as_chunk(substr(s, bas[length(bas)], nchar(s)))
  out
}
simge_uygula <- function(ft, disp, notlar, ust_lab = NULL) {
  for (j in seq_len(ncol(disp))) for (i in which(grepl(simge_re, disp[[j]]))) ft <- compose(ft, i = i, j = j, part = "body", value = do.call(as_paragraph, parcala(disp[[j]][i])))
  for (k in which(grepl(simge_re, notlar))) ft <- compose(ft, i = k, j = 1, part = "footer", value = do.call(as_paragraph, parcala(notlar[k])))
  hi <- nrow_part(ft, "header")
  for (j in which(grepl(simge_re, names(disp)))) ft <- compose(ft, i = hi, j = j, part = "header", value = do.call(as_paragraph, parcala(trimws(names(disp)[j]))))
  ft
}
tablo_yaz <- function(ft, dosya, baslik, yatay = FALSE) {
  doc <- read_docx()
  doc <- body_set_default_section(doc, prop_section(page_size = page_size(orient = if (yatay) "landscape" else "portrait"), page_margins = page_mar(top = 0.8, bottom = 0.8, left = 0.8, right = 0.8)))
  etiket <- regmatches(baslik, regexpr("^Table S?[0-9]+[ab]?\\.", baslik))
  doc <- body_add_fpar(doc, fpar(ftext(etiket, prop = fp_text(font.family = yazi_tipi_t, font.size = 10, bold = TRUE)),
                                 ftext(substring(baslik, nchar(etiket) + 1), prop = fp_text(font.family = yazi_tipi_t, font.size = 10))))
  doc <- body_add_flextable(doc, ft)
  print(doc, target = dosya)
}
wb <- createWorkbook()
xl_stil <- list(
  govde = createStyle(fontName = yazi_tipi_t, fontSize = 9, valign = "center"),
  baslik = createStyle(fontName = yazi_tipi_t, fontSize = 9, textDecoration = "bold", halign = "center", valign = "center", wrapText = TRUE),
  ust = createStyle(border = "top", borderStyle = "medium"),
  alt_ince = createStyle(border = "bottom", borderStyle = "thin"),
  alt_kalin = createStyle(border = "bottom", borderStyle = "medium"),
  not = createStyle(fontName = yazi_tipi_t, fontSize = 8),
  kalin = createStyle(textDecoration = "bold"),
  girinti = createStyle(indent = 1),
  tbaslik = createStyle(fontName = yazi_tipi_t, fontSize = 10, textDecoration = "bold")
)
tablo_listesi <- list()
yalniz_ek1 <- Sys.getenv("EK1_YALNIZ") == "1"
ek1_tablolar <- c("TableS19", "TableS20", "TableS21")
metin_inc <- function(x, kalin = FALSE) {
  x <- duz(as.character(x))
  x[is.na(x)] <- ""
  vapply(x, function(s) {
    ch <- strsplit(s, "")[[1]]
    if (!length(ch)) return(0)
    w <- rep(0.5, length(ch))
    w[grepl("^[a-z]$", ch)] <- 0.47
    w[ch %in% c("i", "j", "l", "t")] <- 0.28
    w[ch %in% c("f", "r")] <- 0.34
    w[ch %in% c("m", "w")] <- 0.75
    w[grepl("^[A-Z]$", ch)] <- 0.68
    w[ch %in% c("I", "J")] <- 0.36
    w[ch %in% c("M", "W")] <- 0.9
    w[ch %in% c(" ", " ", ".", ",", ":", ";", "'")] <- 0.25
    w[ch %in% c("(", ")", "[", "]", "-", "/")] <- 0.333
    w[ch %in% c("=", "+", "<", ">", "−", "≤", "≥", "±", "×", "Δ")] <- 0.6
    w[ch == "%"] <- 0.833
    w[ch == "—"] <- 1
    w[ch == "|"] <- 0.2
    sum(w) * 0.125 * if (kalin) 1.06 else 1
  }, 0, USE.NAMES = FALSE)
}
tablo_cikar <- function(disp, ad, baslik, ust = NULL, notlar = character(0), grup_satir = integer(0), girinti = integer(0), yatay = FALSE, klasor = "Results", soluk = integer(0), orta = TRUE, ilk_gen = NULL) {
  if (yalniz_ek1 && !(ad %in% ek1_tablolar)) return(invisible(NULL))
  disp <- as.data.frame(disp, stringsAsFactors = FALSE, check.names = FALSE)
  disp[] <- lapply(disp, function(x) gsub("(^|[ (\\[,;])-([0-9.])", "\\1−\\2", x))
  notlar <- gsub("(^|[ (\\[,;])-([0-9.])", "\\1−\\2", notlar)
  ft <- flextable(disp)
  jj_cizgi <- integer(0)
  if (!is.null(ust)) {
    seg <- rep(ust$degerler, ust$genislik)
    alt_lab <- trimws(names(disp))
    alt_lab[ust$dikey] <- seg[ust$dikey]
    ft <- set_header_df(ft, mapping = data.frame(col_keys = names(disp), ust = seg, alt = alt_lab, stringsAsFactors = FALSE), key = "col_keys")
    ft <- merge_h(ft, i = 1, part = "header")
    ft <- merge_v(ft, j = ust$dikey, part = "header")
    bas_j <- cumsum(c(1, head(ust$genislik, -1)))
    jj_cizgi <- unlist(lapply(which(ust$genislik > 1), function(k) bas_j[k]:(bas_j[k] + ust$genislik[k] - 1)))
  } else {
    ft <- set_header_labels(ft, values = setNames(as.list(trimws(names(disp))), names(disp)))
  }
  ft <- tablo_bicim(ft, duz(notlar), grup_satir)
  ft <- simge_uygula(ft, disp, notlar)
  if (!is.null(ust)) {
    bas_j <- cumsum(c(1, head(ust$genislik, -1)))
    for (k in which(grepl(simge_re, ust$degerler) & !(bas_j %in% ust$dikey))) ft <- compose(ft, i = 1, j = bas_j[k], part = "header", value = do.call(as_paragraph, parcala(ust$degerler[k])))
    for (j in intersect(ust$dikey, which(grepl(simge_re, rep(ust$degerler, ust$genislik))))) ft <- compose(ft, i = 1, j = j, part = "header", value = do.call(as_paragraph, parcala(rep(ust$degerler, ust$genislik)[j])))
  }
  ft <- font(ft, fontname = yazi_tipi_t, part = "all")
  ft <- fontsize(ft, size = 8, part = "footer")
  if (length(soluk)) {
    ft <- color(ft, i = soluk, color = "#5A5A5A", part = "body")
    ft <- italic(ft, i = soluk, part = "body")
  }
  dar <- ncol(disp) >= 9
  if (dar) ft <- padding(ft, padding.left = 2, padding.right = 2, part = "all")
  if (length(girinti)) ft <- padding(ft, i = girinti, j = 1, padding.left = 12, part = "body")
  if (length(jj_cizgi)) ft <- hline(ft, i = 1, j = jj_cizgi, border = fp_border(color = "black", width = 0.5), part = "header")
  ft <- align(ft, j = 1, align = "left", part = "header")
  if (orta && ncol(disp) > 1) ft <- align(ft, j = 2:ncol(disp), align = "center", part = "body")
  pad <- if (dar) 0.21 else 0.32
  bas_m <- lapply(seq_len(ncol(disp)), function(j) trimws(names(disp)[j]))
  if (!is.null(ust)) {
    tek <- which(rep(ust$genislik, ust$genislik) == 1)
    ust_m <- rep(ust$degerler, ust$genislik)
    for (j in tek) bas_m[[j]] <- unique(c(bas_m[[j]], ust_m[j]))
  }
  govde_g <- vapply(seq_len(ncol(disp)), function(j) max(c(0, metin_inc(disp[[j]]))), 0) + pad
  if (length(girinti)) govde_g[1] <- max(c(0, metin_inc(disp[[1]][girinti]) + 7 / 72, metin_inc(disp[[1]][-girinti]))) + pad
  govde_g <- pmin(govde_g, c(3.6, rep(3.2, ncol(disp) - 1)))
  bas_tam <- vapply(bas_m, function(b) max(metin_inc(b, kalin = TRUE)), 0) + pad
  bas_kelime <- vapply(bas_m, function(b) max(metin_inc(unlist(strsplit(b, " ")), kalin = TRUE)), 0) + pad
  tam <- pmax(govde_g, bas_tam, 0.45)
  en_az <- pmax(govde_g, bas_kelime, 0.45)
  en_az[1] <- max(bas_kelime[1], min(govde_g[1], 1.5))
  maks <- if (yatay) 9.6 else 6.9
  sar <- vapply(seq_len(ncol(disp)), function(j) any(grepl("[A-Za-z]{3,} [A-Za-z(]", duz(disp[[j]]))), NA)
  sar[1] <- FALSE
  kelime_g <- vapply(seq_len(ncol(disp)), function(j) max(c(0, metin_inc(unlist(strsplit(duz(disp[[j]]), " "))))), 0) + pad
  sar_alt <- pmax(bas_kelime, kelime_g, 1.1)
  daralt <- function(g, alt, j, fazla) {
    pay <- pmax(g[j] - alt[j], 0)
    if (!length(j) || sum(pay) <= 0 || fazla <= 0) return(g)
    g[j] <- g[j] - pay * min(1, fazla / sum(pay))
    g
  }
  gen <- tam
  if (sum(gen) > maks) gen[-1] <- en_az[-1]
  if (sum(gen) > maks) gen <- daralt(gen, replace(en_az, 1, max(en_az[1], min(tam[1], 2))), 1, sum(gen) - maks)
  if (sum(gen) > maks) gen <- daralt(gen, sar_alt, which(sar), sum(gen) - maks)
  if (sum(gen) > maks) gen <- daralt(gen, en_az, 1, sum(gen) - maks)
  if (sum(gen) > maks) {
    gen <- gen * maks / sum(gen)
  } else if (sum(gen) < maks && any(gen[-1] < tam[-1])) {
    ek <- tam[-1] - gen[-1]
    gen[-1] <- gen[-1] + ek * min(1, (maks - sum(gen)) / sum(ek))
  }
  if (!is.null(ilk_gen)) {
    gen[1] <- ilk_gen
    gen[-1] <- (maks - ilk_gen) / (length(gen) - 1)
  }
  bos_s <- which(trimws(names(disp)) == "")
  if (length(bos_s)) {
    fazla <- sum(gen[bos_s]) - 0.1 * length(bos_s)
    gen[bos_s] <- 0.1
    gen[-c(1, bos_s)] <- gen[-c(1, bos_s)] + fazla / (length(gen) - 1 - length(bos_s))
  }
  ft <- width(ft, width = gen)
  tablo_yaz(ft, file.path(klasor, paste0(ad, ".docx")), baslik, yatay)
  names(disp) <- gsub(" ", " ", names(disp), fixed = TRUE)
  disp_x <- disp
  notlar_x <- notlar
  disp[] <- lapply(disp, duz_csv)
  csv_ad <- trimws(names(disp))
  if (!is.null(ust)) csv_ad <- ifelse(rep(ust$genislik, ust$genislik) > 1, paste(rep(ust$degerler, ust$genislik), csv_ad), csv_ad)
  csv_tut <- trimws(names(disp)) != ""
  fwrite(setNames(disp, duz_csv(csv_ad))[, csv_tut, drop = FALSE], file.path(klasor, paste0(ad, ".csv")))
  if (length(notlar)) cat(c("", paste0("\"Note: ", gsub("\"", "\"\"", trimws(duz_csv(notlar))), "\""), ""), file = file.path(klasor, paste0(ad, ".csv")), sep = "\n", append = TRUE)
  sayfa <- ad
  addWorksheet(wb, sayfa)
  writeData(wb, sayfa, baslik, startRow = 1, startCol = 1)
  addStyle(wb, sayfa, xl_stil$tbaslik, rows = 1, cols = 1)
  r0 <- 3
  nc <- ncol(disp)
  if (!is.null(ust)) {
    bas <- unlist(mapply(function(v, w) c(v, rep("", w - 1)), ust$degerler, ust$genislik))
    writeData(wb, sayfa, t(bas), startRow = r0, startCol = 1, colNames = FALSE)
    cc <- 1
    for (k in seq_along(ust$genislik)) {
      if (ust$genislik[k] > 1) mergeCells(wb, sayfa, cols = cc:(cc + ust$genislik[k] - 1), rows = r0)
      cc <- cc + ust$genislik[k]
    }
    for (j in ust$dikey) {
      mergeCells(wb, sayfa, cols = j, rows = r0:(r0 + 1))
      writeData(wb, sayfa, trimws(names(disp)[j]), startRow = r0, startCol = j)
    }
    addStyle(wb, sayfa, xl_stil$baslik, rows = r0, cols = 1:nc, gridExpand = TRUE)
    addStyle(wb, sayfa, xl_stil$ust, rows = r0, cols = 1:nc, gridExpand = TRUE, stack = TRUE)
    r0 <- r0 + 1
    hdr <- trimws(names(disp))
    hdr[ust$dikey] <- ""
    writeData(wb, sayfa, t(hdr), startRow = r0, startCol = 1, colNames = FALSE)
  } else {
    writeData(wb, sayfa, t(trimws(names(disp))), startRow = r0, startCol = 1, colNames = FALSE)
    addStyle(wb, sayfa, xl_stil$ust, rows = r0, cols = 1:nc, gridExpand = TRUE, stack = TRUE)
  }
  addStyle(wb, sayfa, xl_stil$baslik, rows = r0, cols = 1:nc, gridExpand = TRUE, stack = TRUE)
  addStyle(wb, sayfa, xl_stil$alt_ince, rows = r0, cols = 1:nc, gridExpand = TRUE, stack = TRUE)
  writeData(wb, sayfa, disp_x, startRow = r0 + 1, startCol = 1, colNames = FALSE)
  addStyle(wb, sayfa, xl_stil$govde, rows = (r0 + 1):(r0 + nrow(disp)), cols = 1:nc, gridExpand = TRUE, stack = TRUE)
  if (orta && nc > 1) addStyle(wb, sayfa, createStyle(halign = "center"), rows = (r0 + 1):(r0 + nrow(disp)), cols = 2:nc, gridExpand = TRUE, stack = TRUE)
  addStyle(wb, sayfa, xl_stil$alt_kalin, rows = r0 + nrow(disp), cols = 1:nc, gridExpand = TRUE, stack = TRUE)
  if (length(grup_satir)) addStyle(wb, sayfa, xl_stil$kalin, rows = r0 + grup_satir, cols = 1, stack = TRUE)
  if (length(soluk)) addStyle(wb, sayfa, createStyle(fontColour = "#5A5A5A", textDecoration = "italic"), rows = r0 + soluk, cols = 1:nc, gridExpand = TRUE, stack = TRUE)
  if (length(girinti)) addStyle(wb, sayfa, xl_stil$girinti, rows = r0 + girinti, cols = 1, stack = TRUE)
  if (length(notlar)) {
    writeData(wb, sayfa, notlar_x, startRow = r0 + nrow(disp) + 1, startCol = 1)
    addStyle(wb, sayfa, xl_stil$not, rows = r0 + nrow(disp) + seq_along(notlar), cols = 1, stack = TRUE)
  }
  setColWidths(wb, sayfa, cols = 1:nc, widths = c(48, rep(16, nc - 1)))
  tablo_listesi[[ad]] <<- disp
  invisible(ft)
}

t0 <- Sys.time()
suppressPackageStartupMessages({
  library(flextable)
  library(officer)
  library(openxlsx)
})
etk <- fromJSON("Codes/etiketler.json", simplifyVector = TRUE)
etk <- lapply(etk, function(x) if (is.list(x) && all(lengths(x) == 1)) unlist(x) else x)
py <- path.expand("~/veri-ortami/bin/python3")
if (!file.exists(py)) py <- Sys.which("python3")
ek_kl <- "Results/Supplementary"
kucuk <- function(deger, n) fifelse(n < 20, "–", fifelse(n <= 50, paste0(deger, "^{a}"), deger))
t1_sutun <- function(x) fcase(x$G == "M", "M", x$G == "F", "F", x$s < 0.40, "D1", x$s <= 0.60, "D2", default = "D3")
t1_sira <- c("M", "D1", "D2", "D3", "F")
medq <- function(v, w, d = 2) {
  qq <- wq(v, w, c(0.25, 0.5, 0.75))
  paste0(formatC(yuv0(qq[2], d), format = "f", digits = d), " (", formatC(yuv0(qq[1], d), format = "f", digits = d), "–", formatC(yuv0(qq[3], d), format = "f", digits = d), ")")
}
tablo1_disp <- function(x, m3 = FALSE) {
  x <- copy(x)
  x[, sutun := factor(t1_sutun(x), levels = t1_sira)]
  satir <- list()
  grup <- integer(0)
  gir <- integer(0)
  bloklar <- list()
  ekle <- function(et, deg, g = FALSE, i = FALSE) {
    satir[[length(satir) + 1]] <<- c(et, deg)
    if (g) grup <<- c(grup, length(satir))
    if (i) gir <<- c(gir, length(satir))
  }
  sutun_uygula <- function(f) vapply(t1_sira, function(k) f(x[sutun == k]), "")
  ekle("Household-years, n", sutun_uygula(function(z) nfmt(nrow(z))))
  ekle("Weighted share, %", sutun_uygula(function(z) f1(100 * sum(z$HB040) / sum(x$HB040))))
  ekle("Food deprivation, %", sutun_uygula(function(z) f1(100 * weighted.mean(z$Y, z$HB040))))
  ekle("Income / year median, median (Q_{1}–Q_{3})", rep("", 5), g = TRUE)
  ekle("Couple's net labor earnings", sutun_uygula(function(z) medq(z$E_oran, z$HB040)), i = TRUE)
  ekle("Other household income", sutun_uygula(function(z) medq(z$O_oran, z$HB040)), i = TRUE)
  ekle("Age, years, median (Q_{1}–Q_{3})", rep("", 5), g = TRUE)
  ekle("Wife", sutun_uygula(function(z) medq(z$k_yas, z$HB040, 0)), i = TRUE)
  ekle("Husband", sutun_uygula(function(z) medq(z$e_yas, z$HB040, 0)), i = TRUE)
  kat_blok <- function(baslik, vekfn, lv, et) {
    ekle(baslik, rep("", 5), g = TRUE)
    N <- matrix(sapply(t1_sira, function(k) { v <- vekfn(x[sutun == k]); vapply(lv, function(l) sum(v == l), 0) }), nrow = length(lv))
    P <- matrix(sapply(t1_sira, function(k) { z <- x[sutun == k]; v <- vekfn(z); vapply(lv, function(l) 100 * weighted.mean(v == l, z$HB040), 0) }), nrow = length(lv))
    G <- N < 20
    for (j in seq_along(t1_sira)) if (sum(G[, j]) == 1 && any(!G[, j])) G[which(!G[, j])[which.min(N[!G[, j], j])], j] <- TRUE
    for (i in seq_along(lv)) ekle(et[i], ifelse(G[i, ], "–", ifelse(N[i, ] <= 50, paste0(f1(P[i, ]), "^{a}"), f1(P[i, ]))), i = TRUE)
    bloklar[[baslik]] <<- list(satir = length(satir) - length(lv) + seq_along(lv), N = N)
  }
  for (es in c("k", "e")) kat_blok(if (es == "k") "Education of wife, %" else "Education of husband, %", function(z) z[[paste0(es, "_egitim")]], 1:5, unname(etk$egitim[as.character(1:5)]))
  ekle("Other household members, % with ≥1", rep("", 5), g = TRUE)
  for (v in list(c("n_0_5", "Children aged 0–5"), c("n_6_13", "Children aged 6–13"), c("n_14_17", "Children aged 14–17"), c("n_diger_18_64", "Other adults aged 18–64"), c("n_diger_65", "Other adults aged ≥65")))
    ekle(v[2], sutun_uygula(function(z) kucuk(f1(100 * weighted.mean(z[[v[1]]] >= 1, z$HB040)), sum(z[[v[1]]] >= 1))), i = TRUE)
  kat_blok("Region (NUTS-1), %", function(z) z$HB030, names(etk$bolge), unname(etk$bolge))
  kat_blok("Survey year, %", function(z) z$yil, 2023:2025, as.character(2023:2025))
  if (m3) {
    ekle("Health at the interview (M3 covariates), %", rep("", 5), g = TRUE)
    for (v in list(c("k_kisit", "Wife: activity limitation"), c("e_kisit", "Husband: activity limitation"), c("k_kronik", "Wife: chronic illness"), c("e_kronik", "Husband: chronic illness")))
      ekle(v[2], sutun_uygula(function(z) kucuk(f1(100 * weighted.mean(z[[v[1]]] == 1, z$HB040)), sum(z[[v[1]]] == 1))), i = TRUE)
    kat_blok("Housing tenure (M3 covariate), %", function(z) as.character(z$mulkiyet), c("sahip", "kiraci", "lojman", "kirasiz"), c("Owner", "Tenant", "Employer-provided", "Rent-free"))
  }
  disp <- as.data.table(do.call(rbind, satir))
  setnames(disp, c("Characteristic", etk$G[["M"]], etk$pay_grubu[["1"]], etk$pay_grubu[["2"]], etk$pay_grubu[["3"]], etk$G[["F"]]))
  list(disp = disp, grup = grup, gir = gir, bloklar = bloklar)
}
gizle_ortak <- function(a, b) {
  R <- nrow(a$disp)
  for (j in 2:6) {
    m <- a$disp[[j]] == "–" | b$disp[[j]][seq_len(R)] == "–"
    for (bl in intersect(names(a$bloklar), names(b$bloklar))) {
      r <- a$bloklar[[bl]]$satir
      if (sum(m[r]) == 1 && any(!m[r])) {
        aday <- which(!m[r])
        nmin <- pmin(a$bloklar[[bl]]$N[aday, j - 1], b$bloklar[[bl]]$N[aday, j - 1])
        m[r[aday[which.min(nmin)]]] <- TRUE
      }
    }
    if (any(m)) {
      set(a$disp, i = which(m), j = j, value = "–")
      set(b$disp, i = which(m), j = j, value = "–")
    }
  }
  list(a = a, b = b)
}
t1_ust <- list(degerler = c("Characteristic", etk$G[["M"]], etk$G_tablo1_D, etk$G[["F"]]), genislik = c(1, 1, 3, 1), dikey = c(1, 2, 6))
t1_not <- unname(etk$notlar[c("n", "oran", "pay", "kucuk")])
t1 <- tablo1_disp(q, m3 = TRUE)
t1d <- tablo1_disp(u[Q == 0], m3 = TRUE)
og <- gizle_ortak(t1, t1d)
t1 <- og$a
t1d <- og$b
tablo_cikar(t1$disp, "Table1", sprintf("Table 1. Characteristics of couple households in the common-support sample by earner structure, 2023–2025 (n = %s household-years).", nfmt(nrow(q))),
            ust = t1_ust, notlar = t1_not, grup_satir = t1$grup, girinti = t1$gir, ilk_gen = 2.0)
fwrite(t1$disp, "Results/table1_veri.csv")

e_satir <- c("E1", "E2", "E3a", "E3b", "E4")
isaretli <- c("E1", "E2", "E3a")
e_et <- function(k) vapply(k, function(x) sub("^(E_\\{[^}]+\\})", paste0("\\1", if (x %in% isaretli) "^{†}" else ""), etk$E_tablo[[x]]), "", USE.NAMES = FALSE)
t2_hucre <- function(m) {
  x <- E_tum[model == m & rope == 2][match(e_satir, buyukluk)]
  data.table(ga(x$tahmin, x$alt, x$ust, 1), f2(x$p_alt), f2(x$p_ic), f2(x$p_ust))
}
t2 <- cbind(data.table(Comparison = e_et(e_satir)), t2_hucre("M1"), data.table(bosluk = ""), t2_hucre("M2"))
setnames(t2, c("Comparison", "Estimate (95% CrI)", "P(Δ < −2)", "P(|Δ| ≤ 2)", "P(Δ > 2)", " ", "Estimate (95% CrI) ", "P(Δ < −2) ", "P(|Δ| ≤ 2) ", "P(Δ > 2) "))
t2_not <- c(sprintf("Percentage points; posterior median (95%% equal-tailed credible interval, CrI) over the common-support sample (n = %s household-years). P, posterior probability; ±2 points, prespecified region of practical equivalence.", nfmt(nrow(q))),
            "E_{1} = [p_{D}(0.1) + p_{D}(0.9)]/2 − p_{D}(0.5); E_{2} = p_{D}(0.9) − p_{D}(0.1); E_{3a} = p_{F} − p_{D}(0.9); E_{3b} = p_{M} − p_{D}(0.1); E_{4} = p_{F} − p_{M}. p_{D}(s), p_{M}, p_{F}: standardized probabilities with all couples set to dual-earner with wife's share s, to husband-only or to wife-only.",
            "M1 omits the couple's earnings and other household income; both models include spouses' ages and education, household composition, survey year and NUTS-2 and linkage-chain intercepts.",
            sprintf("^{†} Relies on p_{D}(0.9): only %d dual-earner household-years in Q had a wife's share of 0.85–0.95 (prespecified minimum 200), and 0.9 lies beyond the 97.5th weighted percentile of shares (%.2f).", q[G == "D" & s >= 0.85 & s <= 0.95, .N], egri_aralik[2]))
tablo_cikar(t2, "Table2", "Table 2. Prespecified comparisons of standardized food deprivation probabilities before (M1) and after (M2) adding income terms.",
            ust = list(degerler = c("Comparison", etk$model[["M1"]], " ", etk$model[["M2"]]), genislik = c(1, 4, 1, 4), dikey = c(1, 6)), notlar = t2_not, soluk = 5L, yatay = FALSE)
sure_ekle("Table 1–2", t0)

t0 <- Sys.time()
akis <- data.table(
  dugum = c("yil_2023", "yil_2024", "yil_2025", "tum", "dis_cift_yok", "cift", "dis_yas", "dis_kayit_negatif", "dis_kazanc_yok", "uygun", "dis_Q", "Q", "Q_M", "Q_D", "Q_F", "Q_zincir", "uygun_zincir"),
  n = c(h[yil == 2023, .N], h[yil == 2024, .N], h[yil == 2025, .N], nrow(h), h[dislama %in% c("1a_referans_cift_yok_es_yok", "1b_belirsiz_es_bagi"), .N], h[cift_durum == "cift", .N],
        h[dislama %in% c("2a_es_18_alti", "2b_iki_es_65_ustu"), .N], h[dislama %in% c("3_bireysel_kayit_eksik", "4_negatif_net_kazanc"), .N], h[dislama == "5_kazanc_yok", .N],
        nrow(u), u[Q == 0, .N], nrow(q), q[G == "M", .N], q[G == "D", .N], q[G == "F", .N], uniqueN(q$zincir_ana), uniqueN(u$zincir_ana)))
stopifnot(akis[dugum == "tum", n] == akis[dugum == "dis_cift_yok", n] + akis[dugum == "cift", n],
          akis[dugum == "cift", n] == sum(akis[dugum %in% c("dis_yas", "dis_kayit_negatif", "dis_kazanc_yok", "uygun"), n]),
          akis[dugum == "uygun", n] == akis[dugum == "dis_Q", n] + akis[dugum == "Q", n])
zl <- q[, .N, by = zincir_ana][, .(n = .N), keyby = .(kayit = N)]
akis <- rbind(akis, data.table(dugum = paste0("Q_zincir_", zl$kayit), n = zl$n), data.table(dugum = paste0("Q_pay_", c("M", "D", "F")), n = q[, .(p = 100 * sum(w_norm) / nrow(q)), keyby = G][match(c("M", "D", "F"), G), p]))
stopifnot(akis[dugum == "Q", n] == sum(zl$kayit * zl$n))
fwrite(akis, file.path(ddir, "figur_verileri", "fig1a_akis.csv"))
fwrite(akis, "Results/akis_sayilari.csv")
sure_ekle("figür verileri: akış", t0)

t0 <- Sys.time()
duy_tum <- rbind(E_tum[model %in% c("M2", "M3") & rope == 2][, `:=`(kod = model, grup = fifelse(model == "M2", "ana", "C"), aralik = "posterior", n = nrow(q), olay = sum(q$Y))],
                 E_capa[, `:=`(kod = model, grup = "C", aralik = "posterior", n = nrow(q), olay = sum(q$Y), soru = "Veri içindeki çapalar (sonuç sonrası)")],
                 rbindlist(duy_sonuc, fill = TRUE)[, kod := model], fill = TRUE)
ana_E <- E_tum[model == "M2" & rope == 2]
duy_tum[, ana_tahmin := ana_E$tahmin[match(buyukluk, ana_E$buyukluk)]]
duy_tum[, fark_ana := tahmin - ana_tahmin]
duy_tum[, rope_en := fifelse(is.na(p_alt), NA_character_, c("alt", "ic", "ust")[max.col(cbind(p_alt, p_ic, p_ust), ties.method = "first")])]
ana_rope <- ana_E[, .(buyukluk, ana_rope = c("alt", "ic", "ust")[max.col(cbind(p_alt, p_ic, p_ust), ties.method = "first")])]
duy_tum <- merge(duy_tum, ana_rope, by = "buyukluk")
duy_tum[, maddi := kod != "M2" & (abs(fark_ana) > 1 | (!is.na(rope_en) & rope_en != ana_rope))]
duy_tum[grepl("^C19", kod), maddi := NA]
duy_tum[, bolge_belirsiz := {
  P <- cbind(p_alt, p_ic, p_ust)
  S <- cbind(mcse_d_alt_ic, mcse_d_alt_ust, mcse_d_ic_ust)
  vapply(seq_len(.N), function(i) {
    if (anyNA(P[i, ])) return(NA)
    o <- sort(order(-P[i, ])[1:2])
    sd_fark <- S[i, match(paste(o, collapse = ""), c("12", "13", "23"))]
    abs(P[i, o[1]] - P[i, o[2]]) < 2 * sd_fark
  }, NA)
}]
duy_tum[, isaret := fcase(!(maddi %in% TRUE), "", abs(fark_ana) <= 1 & bolge_belirsiz %in% TRUE, "u", default = "m")]
for (pk in list(list(k = c("B14_sigma2", "B14b_sigma5"), ad = "σ_zincir prior'ı karşılaştırması (B14, B14b)", nesne = "ana prior", onceden = "B14 talimat; B14b sonuç sonrası (K13)"),
                list(k = c("C21_b25", "C21_b5"), ad = "katsayı prior'ı karşılaştırması (C21)", nesne = "ana prior", onceden = "sonuç sonrası (K18)"),
                list(k = c("B13_imza", "B13_ana_reis", "B13_ana_bolge"), ad = "geri dönüş kuralı 3: bağlantı kuralı (B13)", nesne = "ana bağlantı kuralı", onceden = "talimat (6.4, durum 3); B13_ana_bolge sonuç sonrası (K16)"))) {
  x <- duy_tum[kod %in% pk$k, .(fark = max(abs(fark_ana)), maddi_tum = paste(buyukluk[isaret %in% c("m", "u")], collapse = ", "), belirsiz = paste(buyukluk[isaret == "u"], collapse = ", ")), keyby = kod]
  maddi_tum <- unique(unlist(strsplit(x$maddi_tum[x$maddi_tum != ""], ", ")))
  sadece_u <- length(maddi_tum) && all(x$maddi_tum == x$belirsiz)
  prot_ekle("M2", pk$ad, "maddi değişiklik (talimat): E1–E4'te > 1 puan fark ya da en olası ROPE bölgesinin değişmesi; bölge değişimi Monte Carlo hatası içindeyse ayrıca yazılır (sonuç sonrası ek, K20)",
            paste(sprintf("%s: en büyük fark %.2f puan; önceden belirlenmiş ölçüte göre maddi: %s%s", x$kod, x$fark, fifelse(x$maddi_tum == "", "yok", x$maddi_tum),
                          fifelse(x$belirsiz == "", "", paste0(" (bölge değişimi Monte Carlo hatası içinde: ", x$belirsiz, ")"))), collapse = " | "),
            if (!length(maddi_tum)) paste(pk$nesne, "korunur; maddi değişiklik yok")
            else if (sadece_u) paste0(pk$nesne, " korunur; önceden belirlenmiş ölçüte göre maddi (", paste(maddi_tum, collapse = ", "), ", bölge değişimi) ama Monte Carlo hatası içinde; ana metinde bir cümle")
            else paste0(pk$nesne, " korunur; maddi değişiklik (", paste(maddi_tum, collapse = ", "), ") ana metinde raporlanır"),
            onceden = pk$onceden)
}
for (m in c("A1_2025", "A3_ucret", "B10_agirliksiz", "A9_tum_uygun", "A2_2023", "A2_2024")) {
  x <- duy_tum[kod == m]
  ok <- max(x$mcse_tahmin, x$mcse_alt, x$mcse_ust) < 0.1 & max(x$mcse_p_alt, x$mcse_p_ic, x$mcse_p_ust, na.rm = TRUE) < 0.01
  prot_ekle(m, "Monte Carlo hatası", "E1–E4 medyan ve aralık sınırlarında MCSE < 0,1 puan; ROPE olasılıklarında < 0,01 (Figure 3b ve tek yıllık modeller)",
            sprintf("%s çekiliş; en büyük MCSE: tahmin %.3f, sınır %.3f, olasılık %.4f", nfmt(x$cekilis[1]), max(x$mcse_tahmin), max(x$mcse_alt, x$mcse_ust), max(x$mcse_p_alt, x$mcse_p_ic, x$mcse_p_ust, na.rm = TRUE)),
            if (ok) "kabul" else "iterasyon artırılmalı", onceden = "talimat (6.3); sınırlara genişletme analistin (K14)")
}
x <- duy_tum[!(kod %in% c("M2", "M3", "A1_2025", "A3_ucret", "B10_agirliksiz", "A9_tum_uygun", "A2_2023", "A2_2024")) & !grepl("^C19|^B11", kod)]
prot_ekle(sprintf("öteki %d duyarlılık modeli (1.500 örnekleme)", uniqueN(x$kod)), "Monte Carlo hatası", "MCSE raporlanır (K14); ana metin modellerindeki 0,1 eşiği uygulanmaz",
          sprintf("en büyük MCSE: medyan %.3f, sınır %.3f, olasılık %.4f", max(x$mcse_tahmin), max(x$mcse_alt, x$mcse_ust), max(x$mcse_p_alt, x$mcse_p_ic, x$mcse_p_ust, na.rm = TRUE)),
          "raporlandı (duyarlilik_E.csv)", onceden = "analist, ilk geçişten sonra (K14)")
mcse_diger_sinir <- max(x$mcse_alt, x$mcse_ust)
setorder(duy_tum, grup, kod, buyukluk)
print(duy_tum[buyukluk != "E4", .(kod, buyukluk, tahmin = round(tahmin, 2), alt = round(alt, 2), ust = round(ust, 2), fark = round(fark_ana, 2), rope_en, maddi)])
fwrite(duy_tum, "Results/duyarlilik_E.csv")
f3b_kod <- c("M2", "A1_2025", "A3_ucret", "B10_agirliksiz", "B11_survey", "A9_tum_uygun")
fwrite(duy_tum[kod %in% f3b_kod, .(kod, buyukluk, tahmin, alt, ust, aralik, alt80, ust80)], file.path(ddir, "figur_verileri", "fig3b_duyarlilik.csv"))
orman_kod <- c("M2", "A2_2023", "A2_2024", "A1_2025", "A3_ucret", "A4_ucretsiz_aile_yok", "A5_tek_cift", "A6_tum_yaslar", "A7_TR63_yok", "A8_durum_uyumu", "A11_esit_haric", "A9_tum_uygun",
               "A10_destek3", "C15_esik5", "C16_O_izk", "C17_esdeger", "C18_fs_df3", "C18_fs_df5", "C18_fs_sabit", "C20_fs_prior05", "C20_fs_prior2", "C21_b25", "C21_b5", "M3")
sonradan <- c("B14b_sigma5", "A10_destek3", "A11_esit_haric", "B13_ana_bolge", "B15_kish", "C18_fs_sabit", "C19_capa25", "C19_capa20", "C20_fs_prior05", "C20_fs_prior2", "C21_b25", "C21_b5", ek1_modeller)
orman <- duy_tum[kod %in% orman_kod, .(kod, buyukluk, tahmin, alt, ust, aralik, alt80, ust80, sonradan = kod %in% sonradan)]
orman <- orman[order(match(kod, orman_kod))]
fwrite(orman, file.path(ddir, "figur_verileri", "figS_duyarlilik_orman.csv"))
fwrite(E_tum[model == "M2" & rope == 2], file.path(ddir, "figur_verileri", "fig2b_E.csv"))
fwrite(yil_E, file.path(ddir, "figur_verileri", "figS_yil.csv"))
sure_ekle("duyarlılık özeti ve figür verileri", t0)

t0 <- Sys.time()
grupla <- function(dt, sutun) {
  dt <- as.data.table(dt)
  ad <- setdiff(names(dt), sutun)
  degerler <- unique(dt[[sutun]])
  out <- rbindlist(lapply(degerler, function(g) rbind(setnames(data.table(g), ad[1]), dt[dt[[sutun]] == g, ad, with = FALSE], fill = TRUE)), fill = TRUE)
  for (j in names(out)) set(out, which(is.na(out[[j]])), j, "")
  grup <- which(rowSums(out[, -1, with = FALSE] != "") == 0)
  list(disp = out, grup = grup, gir = setdiff(seq_len(nrow(out)), grup))
}
ek_no <- list(degisken = 1, akis = 2, yil_G = 3, baglanti = 4, zincir = 5, eksik = 6, ortak_destek = 7, tani = 8, ppc = 9, duy_B = 10, duy_AC = 11, yazilim = 12,
              ozellik = 13, ozellik_dis = 14, E_ek = 15, katsayi = 16, koca = 17, yil = 18, zaman_T1 = 19, zaman_X1 = 20, zaman_X2 = 21)
tS <- function(k) paste0("Table S", ek_no[[k]])
ek_yaz <- function(x) {
  for (k in names(ek_no)[order(-nchar(names(ek_no)))]) x <- gsub(paste0("{", k, "}"), tS(k), x, fixed = TRUE)
  x
}
ek_cikar <- function(k, disp, metin, ...) tablo_cikar(disp, paste0("TableS", ek_no[[k]]), paste0("Table S", ek_no[[k]], ". ", metin), klasor = ek_kl, ...)
degisken_tanim <- data.table(
  degisken = c("HE090 (outcome)", "E_{wife}, E_{husband}", "s", "G", "O", "m_{t}", "asinh(E/m_{t}), asinh(O/m_{t})", "Age of wife / husband", "Education of wife / husband",
               "Children aged 0–5, 6–13, 14–17", "Other adults 18–64, ≥65", "Year, NUTS-2, NUTS-1", "Activity limitation", "Chronic illness", "Tenure",
               "Husband's status in income year (wife-only earners)", "Unpaid family worker", "Wage sample", "Earner structure matches current employment", "Linkage chain"),
  tanim = c("1 if the household cannot afford a meal with meat, chicken or fish (or vegetarian equivalent) every second day (HE090 = 2)",
            "Net labor earnings of each spouse in the income year: FG010 + FG020 + FG030 + FG040 (cash and in-kind wages, cash and in-kind self-employment income); blank = 0 for spouses with an individual record; negative values kept",
            "Wife's share of the couple's earnings, E_{wife} / (E_{wife} + E_{husband}); defined only for dual-earner couples. Modeled with a natural cubic spline f(s): interior knots at the weighted quartiles of s among dual-earner couples in Q, boundary knots 0 and 1, centered so that f(0.5) = 0",
            "Earner structure: husband-only (E_{wife} = 0, E_{husband} > 0), dual-earner (both > 0), wife-only (E_{wife} > 0, E_{husband} = 0)",
            "Other household income: HG110 − (E_{wife} + E_{husband}); includes pensions, transfers, other members' earnings, imputed rent and deductions; may be negative",
            "Weighted (HB040) median of household disposable income (HG110) across all households in survey year t",
            "Inverse hyperbolic sine of couple earnings and other income relative to m_{t}; natural splines with 4 and 3 df",
            "Age at 31 December of the income year (FK070); natural splines with 3 df",
            "Last completed level (FE030): no diploma (0–1), primary or 8-year basic (2–3), lower secondary (4), upper secondary (5–6), tertiary (7–10)",
            "Number of household members aged 0–5 (including those born in the survey year), 6–13 and 14–17",
            "Number of members other than the spouses aged 18–64 and ≥65",
            "Survey year (2023–2025); NUTS-2 (HB031, varying intercept); NUTS-1 (HB030, common-support model only)",
            "Health-related limitation in usual activities for at least 6 months (FS030 = 1 or 2), each spouse (M3)",
            "Chronic illness (FS020 = 1), each spouse (M3)",
            "Owner, tenant, employer-provided housing, rent-free (HH020; M3)",
            "Status in which the husband spent most months of the income year among retired (FI290), unemployed (FI280), other inactive (FI310 + FI300) and worked (FI260 + FI270); ties: retired, unemployed, other inactive, worked. In wife-only earner couples, “worked” means worked without own positive net earnings",
            "Main job status unpaid family worker at interview (FI120 = 5)",
            "Neither spouse has self-employment income (FG030 = FG040 = 0)",
            "Current employment at interview (FI010 = 1–4) matches the earner structure in the income year",
            "Records of the same household in different survey years linked by member signature (birth year, birth month and sex of all members) or couple key (spouses' birth year, birth month, sex and NUTS-2); varying intercept"),
  kaynak = c("HE090", "FG010, FG020, FG030, FG040; individual record indicator", "FG010–FG040", "FG010–FG040", "HG110, FG010–FG040", "HG110, HB040", "HG110, FG010–FG040", "FK070", "FE030",
             "FK070", "FK070", "survey year, HB031, HB030", "FS030", "FS020", "HH020", "FI280, FI290, FI300, FI310, FI260, FI270", "FI120", "FG030, FG040", "FI010", "FK080, FK075, FK090, HB031"))
fwrite(degisken_tanim[, lapply(.SD, duz_csv)], "Results/degisken_tanimlari.csv")
ek_cikar("degisken", setnames(copy(degisken_tanim), c("Variable", "Definition", "Source variables")), "Definitions of derived variables.", yatay = TRUE, orta = FALSE)
ak <- fread("Results/denetim/fizibilite_orneklem_akisi.csv")
ak_et <- c("1a_referans_cift_yok_es_yok" = "No co-resident spouse of the reference person", "1b_belirsiz_es_bagi" = "Ambiguous spouse link or spouse not coded as spouse", "2a_es_18_alti" = "A spouse younger than 18",
           "2b_iki_es_65_ustu" = "Both spouses aged 65 or older", "3_bireysel_kayit_eksik" = "A spouse without an individual record", "4_negatif_net_kazanc" = "Negative net labor earnings of a spouse",
           "5_kazanc_yok" = "No positive net labor earnings in the couple", "uygun" = "Eligible couple households")
ak_disp <- rbind(data.table(Step = "All household-years", `2023` = nfmt(h[yil == 2023, .N]), `2024` = nfmt(h[yil == 2024, .N]), `2025` = nfmt(h[yil == 2025, .N]), Total = nfmt(nrow(h))),
                 ak[, .(Step = ak_et[dislama], `2023` = nfmt(`2023`), `2024` = nfmt(`2024`), `2025` = nfmt(`2025`), Total = nfmt(toplam))],
                 data.table(Step = c("Outside common support", "Common-support sample (Q)"), `2023` = nfmt(c(u[yil == 2023 & Q == 0, .N], q[yil == 2023, .N])), `2024` = nfmt(c(u[yil == 2024 & Q == 0, .N], q[yil == 2024, .N])),
                            `2025` = nfmt(c(u[yil == 2025 & Q == 0, .N], q[yil == 2025, .N])), Total = nfmt(c(u[Q == 0, .N], nrow(q)))))
ek_cikar("akis", ak_disp, "Sample flow by survey year (household-years; exclusions applied sequentially).", girinti = 2:8)
fq <- fread("Results/denetim/fizibilite_yil_G.csv")
fq_q <- rbind(q[, .(n = .N, olay = sum(Y), kish_n = kish(HB040), w = sum(HB040)), keyby = .(yil = as.character(yil), G)], q[, .(n = .N, olay = sum(Y), kish_n = kish(HB040), w = sum(HB040)), keyby = G][, yil := "Pooled"], use.names = TRUE)
fq_q[, pay := 100 * w / sum(w), by = yil]
q[, zn_q := .N, by = zincir_ana]
bagli <- rbind(u[, .(Sample = "Eligible", Year = as.character(yil), G, bag = zn_uyg_ana > 1)], u[, .(Sample = "Eligible", Year = "Pooled", G, bag = zn_uyg_ana > 1)],
               q[, .(Sample = "Common support (Q)", Year = as.character(yil), G, bag = zn_q > 1)], q[, .(Sample = "Common support (Q)", Year = "Pooled", G, bag = zn_q > 1)])[, .(`Linked to another year, %` = f1(100 * mean(bag))), keyby = .(Sample, Year, G)]
fq_u <- rbind(u[, .(w = sum(HB040)), keyby = .(yil = as.character(yil), G)], u[, .(w = sum(HB040)), keyby = G][, yil := "havuz"], use.names = TRUE)
fq_u[, pay := 100 * w / sum(w), by = yil]
fq[, pay_ham := fq_u$pay[match(paste(yil, G), paste(fq_u$yil, fq_u$G))]]
stopifnot(!anyNA(fq$pay_ham), max(abs(fq$pay_ham - fq$agirlikli_pay)) < 0.01)
yg_disp <- rbind(fq[, .(Sample = "Eligible", Year = fifelse(yil == "havuz", "Pooled", yil), Group = etk$G[G], n = nfmt(n), Events = nfmt(olay), `Non-events` = nfmt(olay_yok), `Kish n` = nfmt(round(kish_n)), `Weighted share, %` = f1(pay_ham))],
                 fq_q[, .(Sample = "Common support (Q)", Year = yil, Group = etk$G[G], n = nfmt(n), Events = nfmt(olay), `Non-events` = nfmt(n - olay), `Kish n` = nfmt(round(kish_n)), `Weighted share, %` = f1(pay))])
yg_disp[, G := names(etk$G)[match(Group, etk$G)]]
yg_disp <- merge(yg_disp, bagli, by = c("Sample", "Year", "G"), sort = FALSE)
yg_disp <- yg_disp[order(match(Sample, c("Eligible", "Common support (Q)")), match(Year, c("2023", "2024", "2025", "Pooled")), match(G, c("M", "D", "F")))][, G := NULL]
yg_disp[, Blok := paste0(Sample, ", ", fifelse(Year == "Pooled", "pooled 2023–2025", Year))]
yg_g <- grupla(yg_disp[, c("Blok", setdiff(names(yg_disp), c("Blok", "Sample", "Year"))), with = FALSE], "Blok")
setnames(yg_g$disp, "Group", "Sample, year and earner structure")
ek_cikar("yil_G", yg_g$disp, "Household-years, food deprivation events, Kish effective sample size and linkage by survey year and earner structure.", yatay = TRUE,
         grup_satir = yg_g$grup, girinti = yg_g$gir,
         notlar = c("Events, household-years in which the household could not afford a meal with meat, chicken or fish every second day. Kish n = (Σw)^{2}/Σw^{2}. Weighted share within the survey year (pooled rows: within the pooled sample).",
                    "Linked: unweighted share of household-years whose linkage chain (main rule) contains another record of the same sample."))
bk <- fread("Results/denetim/baglanti_kalitesi.csv")
es <- fread("Results/denetim/baglanti_eslesme_sayilari.csv")
tur_et <- c(imza_ve_cift = "Signature and couple key", yalniz_imza = "Signature only", yalniz_cift = "Couple key only", yalniz_reis = "Reference-person key only")
bg_disp <- bk[, .(`Survey years` = paste0(y1, "–", y2), `Link type` = tur_et[tur], Links = nfmt(bag), `Same NUTS-2, %` = paste0(f1(HB031_ayni), fifelse(tur != "yalniz_imza", "^{a}", "")),
                  `Same dwelling type, %` = paste0(f1(HH010_ayni), fifelse(tur == "yalniz_reis", "^{a}", "")), `Same tenure, %` = paste0(f1(HH020_ayni), fifelse(tur == "yalniz_reis", "^{a}", "")),
                  `Same household size, %` = paste0(f1(hane_buyuklugu_ayni), fifelse(tur %in% c("imza_ve_cift", "yalniz_imza"), "^{a}", "")),
                  `Same education of both spouses, %` = fifelse(egitim_karsilastirilabilen >= 20, f1(iki_esin_egitimi_ayni), "–"))]
bg_g <- grupla(bg_disp, "Survey years")
setnames(bg_g$disp, "Link type", "Survey years and link type")
ek_cikar("baglanti", bg_g$disp, "Links between survey years by link type and agreement on variables.", yatay = TRUE,
         grup_satir = bg_g$grup, girinti = bg_g$gir,
         notlar = c(sprintf("Signature links: %s (2023–2024), %s (2023–2025) and %s (2024–2025), identical to the source documentation. Main rule: signature or couple key; the reference-person key is used only in a sensitivity analysis.", nfmt(es$imza[1]), nfmt(es$imza[2]), nfmt(es$imza[3])),
                    sprintf("Links were combined into chains with at most one household per survey year, in a priority order fixed before link quality was examined: links confirmed by both keys, then signature-only links, then couple-key-only links, with adjacent years before 2023–2025. The %s of %s links that would have placed two households of the same year in one chain were dropped.",
                            nfmt(red_ozet[kural == "ana", sum(reddedilen)]), nfmt(red_ozet[kural == "ana", sum(bag)])),
                    paste0("^{a} The variable is part of the matching key (or implied by it) and is not independent evidence. Education agreement is computed where both records have a reference couple",
                           if (any(bg_disp$`Same education of both spouses, %` == "–")) "; –, fewer than 20 links." else ".")))
zu <- fread("Results/denetim/zincir_uzunluklari.csv")
zo <- copy(oruntu)
kural_et <- c(ana = "Main rule", imza = "Signature only", ana_reis = "Main rule + reference-person key", ana_bolge = "Main rule, signature-only links within NUTS-2")
zq <- rbindlist(lapply(names(kural_tanim), function(kr) q[, .N, by = c(paste0("zincir_", kr))][, .(zincir = .N), keyby = .(kayit = N)][, `:=`(kural = kr, orneklem = "Q")]))
zu2 <- rbind(zu[orneklem == "uygun çiftler"][, orneklem := "Eligible"], zq)
z_disp <- dcast(zu2, kural + orneklem ~ kayit, value.var = "zincir", fill = 0)
setnames(z_disp, c("kural", "orneklem", "1", "2", "3"), c("Linkage rule", "Sample", "1 record", "2 records", "3 records"))
z_disp <- z_disp[order(match(`Linkage rule`, names(kural_et)), match(Sample, c("Eligible", "Q")))]
z_disp[, `Linkage rule` := kural_et[`Linkage rule`]]
for (j in c("1 record", "2 records", "3 records")) set(z_disp, j = j, value = nfmt(z_disp[[j]]))
zo2 <- dcast(zo[tur == "tümü"], kural ~ oruntu, value.var = "yuzde")
z_disp <- merge(z_disp, zo2[, .(`Linkage rule` = kural_et[kural], `Neither deprived` = f1(`00`), `One deprived` = f1(`01/10`), `Both deprived` = f1(`11`))], by = "Linkage rule", sort = FALSE)
z_disp <- z_disp[order(match(`Linkage rule`, kural_et), match(Sample, c("Eligible", "Q")))]
zo_q <- rbindlist(lapply(names(kural_tanim), function(kr) {
  z2 <- q[, .(n = .N, Ysum = sum(Y)), by = c(paste0("zincir_", kr))][n == 2L]
  z2[, .N, keyby = .(oruntu = c("00", "01/10", "11")[Ysum + 1])][, `:=`(kural = kr, yuzde = 100 * N / sum(N))]
}))
zo_q2 <- dcast(zo_q, kural ~ oruntu, value.var = "yuzde", fill = 0)
for (kr in zo_q2$kural) z_disp[`Linkage rule` == kural_et[[kr]] & Sample == "Q", `:=`(`Neither deprived` = f1(zo_q2[kural == kr, `00`]), `One deprived` = f1(zo_q2[kural == kr, `01/10`]), `Both deprived` = f1(zo_q2[kural == kr, `11`]))]
z_disp[Sample == "Q", Sample := "Common support (Q)"]
z_g <- grupla(z_disp, "Linkage rule")
setnames(z_g$disp, "Sample", "Linkage rule and sample")
ek_cikar("zincir", z_g$disp, "Linkage chains by number of household-year records and food deprivation patterns in two-record chains.", yatay = TRUE,
         ust = list(degerler = c("Linkage rule and sample", "Chains by number of records, n", "Two-record chains, %"), genislik = c(1, 3, 3), dikey = 1),
         grup_satir = z_g$grup, girinti = z_g$gir,
         notlar = "Patterns are unweighted shares of two-record chains within each sample (chains linked within Q for the Q rows).")
kk <- fread("Results/denetim/eksik_kayitsiz_es_karsilastirma.csv")
kk_et <- c(Y = "Food deprivation", HG110_oran = "Household income / year median", n_0_5 = "Children aged 0–5", n_6_13 = "Children aged 6–13", n_14_17 = "Children aged 14–17",
           hane_buyuklugu = "Household size", k_yas = "Age of wife", e_yas = "Age of husband", Ek_oran = "Wife's earnings / year median (where recorded)", Ee_oran = "Husband's earnings / year median (where recorded)")
kk_d <- kk[!is.na(smd) & !grepl("^(yil|bolge)_", degisken)]
kk_d[, et := fifelse(degisken %in% names(kk_et), kk_et[degisken], fifelse(grepl("^yil_", degisken), paste("Survey year", sub("yil_", "", degisken)), etk$bolge[sub("bolge_", "", degisken)]))]
kk_d[, tek_ondalik := degisken %in% c("k_yas", "e_yas", "hane_buyuklugu", "Y")]
kk_d[degisken == "Y", `:=`(kayitsiz_esli = 100 * kayitsiz_esli, dahil = 100 * dahil, et = "Food deprivation, %")]
eksik_disp <- kk_d[, .(Characteristic = et, `Couples with a spouse without an individual record` = fifelse(tek_ondalik, f1(kayitsiz_esli), f2(kayitsiz_esli)), `Included couples` = fifelse(tek_ondalik, f1(dahil), f2(dahil)), `Standardized difference` = f2(smd))]
ek_cikar("eksik", eksik_disp, sprintf("Couples excluded because a spouse had no individual record (n = %d household-years) compared with included couples (n = %s household-years).", nrow(kayitsiz), nfmt(nrow(u))),
         notlar = c("Weighted means; standardized difference, difference in means divided by the pooled standard deviation. Income ratios truncated at 10. Region and survey year are not shown (small cells).",
                    "No model variable had missing values among eligible couples (both spouses had individual records); complete-case analysis. Codes 98 and 99 did not occur in the variables used."))
od_s <- copy(od$sinir)
od_dis2 <- fread("Results/denetim/ortak_destek_dislanan.csv")
od_disp <- rbind(data.table(Quantity = "Bounds on the estimated probability", Value = ""),
                 od_s[, .(Quantity = paste0("P(", c(M = "husband-only earner", D_dusuk = "dual-earner, share 0.05–0.15", D_orta = "dual-earner, share 0.45–0.55", D_yuksek = "dual-earner, share 0.85–0.95", F = "wife-only earner")[k], ")"),
                          Value = paste0(formatC(alt, format = "f", digits = 4), "–", formatC(ust, format = "f", digits = 4)))],
                 data.table(Quantity = "Outside Q, n (weighted %)", Value = ""),
                 od_dis2[yil == "havuz"][order(match(G, c("tümü", "M", "D", "F"))), .(Quantity = fifelse(G == "tümü", "All eligible couples", etk$G[G]), Value = paste0(nfmt(Q_disi_n), " (", f1(Q_disi_agirlikli), ")"))])
od_grup <- which(od_disp$Value == "")
ek_cikar("ortak_destek", od_disp, "Common-support (Q) bounds on estimated category probabilities and household-years outside Q.",
         grup_satir = od_grup, girinti = setdiff(seq_len(nrow(od_disp)), od_grup),
         notlar = c("Bounds: for each category, the largest weighted 1st percentile and the smallest weighted 99th percentile of its estimated probability across the five observed comparison categories (rectangular common support).",
                    "Outside Q: unweighted n of household-years (weighted % of the group)."))
tn <- fread("Results/denetim/model_tanilari.csv")
tn_et <- c(unlist(etk$model), M2_Fdurum = "Husband's-status model (secondary)", M2_yil = "Year-deviation model (secondary)", unlist(etk$duyarlilik),
           X1_tze = "Work-intensity model (X1)", X1_tze_sabit = "Work-intensity model, fixed knots (X1)", X2_A = "Other non-working adult model (X2)", X2_Ap = "Any other adult model (X2′)")
tn <- tn[order(match(model, unique(c("M1", "M2", "M3", "M2_Fdurum", "M2_yil", orman_kod, names(etk$duyarlilik), ek1_modeller))))]
tn_disp <- tn[, .(Model = paste0(fifelse(model %in% names(tn_et), tn_et[model], model), fifelse(model %in% sonradan, "^{p}", "")), `Monitored parameters` = nfmt(parametre), `Max R-hat` = formatC(rhat_max, format = "f", digits = 3), `Min bulk ESS` = nfmt(ess_bulk_min), `Min tail ESS` = nfmt(ess_tail_min),
                  Divergences = nfmt(diverjans), `Max tree depth hits` = nfmt(agac_derinligi_siniri), `Min E-BFMI` = formatC(ebfmi_min, format = "f", digits = 2))]
mcse_ana_ok <- protokol[grepl("^Monte Carlo hatası", kontrol) & !grepl("^öteki", model) & !grepl("^X[12]_", model), all(karar == "kabul")]
ek_cikar("tani", tn_disp, "Convergence diagnostics of the Bayesian models.", yatay = TRUE,
         notlar = c(sprintf("4 chains; 1,000 warm-up and 1,500 sampling iterations each (4,500 in M1–M3, the wage-sample, unweighted and all-eligible models and the four post hoc models of Section 12; %s in the single-year models; %s in the husband's-status model; %s in the year-deviation model); target acceptance rate %s and maximum tree depth %d; within-chain parallelization with a static partition. Criteria: R-hat ≤ 1.01, bulk and tail effective sample size (ESS) ≥ 400, no divergent transitions, E-BFMI > 0.3.",
                            nfmt(iter_tek - 1000L), nfmt(iter_fd - 1000L), nfmt(iter_yil - 1000L), formals(model_kur)$adapt_delta, formals(model_kur)$max_treedepth),
                    if (mcse_ana_ok) sprintf("Monte Carlo standard errors (MCSE) of the medians and interval limits of the comparisons and standardized probabilities were below 0.1 percentage points, and those of the posterior probabilities below 0.01, in M1–M3, the secondary models, the single-year models and the wage-sample, unweighted and all-eligible models; in the other sensitivity models, MCSE of interval limits were at most %.1f points; in the post hoc models, they were %s in the work-intensity models and at most %.2f points (%.2f for comparisons relying on the share of 0.9) in the other-adult models.", mcse_diger_sinir,
                             if (max(x1_mcse$mcse_tahmin, x1_mcse$mcse_alt, x1_mcse$mcse_ust) < 0.1) "below 0.1 points" else sprintf("at most %.2f points", max(x1_mcse$mcse_tahmin, x1_mcse$mcse_alt, x1_mcse$mcse_ust)),
                             max(x2_mcse[buyukluk %in% c("E3b", "E4"), c(mcse_tahmin, mcse_alt, mcse_ust)]), max(x2_mcse$mcse_tahmin, x2_mcse$mcse_alt, x2_mcse$mcse_ust))
                    else "Monte Carlo standard errors are reported in the model protocol; at least one model did not meet the 0.1-point criterion.",
                    sprintf("Monitored: coefficients, standard deviations and NUTS-2 intercepts. Linkage-chain intercepts were checked separately in M1–M3 and the two secondary models (%s parameters each; R-hat ≤ %.3f, ESS ≥ %s), not in the sensitivity models. ^{p} Added after the main results were seen.",
                            nfmt(max(tam_tani$parametre)), max(tam_tani$rhat_max), nfmt(min(tam_tani$ess_bulk_min, tam_tani$ess_tail_min)))))
pp <- copy(ppc_M2)[kontrol != "ibbs2"]
pp <- pp[order(match(kontrol, c("G_yil", "pay", "zincir_ici_ayni_sonuc")), match(substr(grup, 1, 1), c("M", "D", "F")), grup)]
pp[, grup_et := fcase(kontrol == "G_yil", paste(etk$G[substr(grup, 1, 1)], substr(grup, 3, 6)), kontrol == "pay", fifelse(grup %in% c("M", "F"), etk$G[grup], sub("D ", "Dual-earner, share ", grup)),
                      kontrol == "zincir_ici_ayni_sonuc", "Two-record chains with the same outcome in both records", default = "Three-record chains with the same outcome in all records")]
pp_disp <- pp[, .(Group = grup_et, n = nfmt(n), `Observed, %` = f1(gozlenen), `Replicated, % (95% interval)` = ga(rep_medyan, rep_alt, rep_ust, 1), `P(rep ≥ obs)` = f2(ppp))]
ek_cikar("ppc", pp_disp, "Posterior predictive checks of the main model (M2).",
         notlar = c("Weighted prevalence (earner structure and share rows) or unweighted share of two- and three-record chains with the same outcome in all records. 400 posterior draws.",
                    "Outcomes were replicated with posterior NUTS-2 intercepts and new linkage-chain intercepts drawn from N(0, σ^{2}_{chain}); the last rows check the modeled dependence between repeated records."))
t1u <- tablo1_disp(u, m3 = TRUE)
ek_cikar("ozellik", t1u$disp, sprintf("Characteristics of all eligible couple households by earner structure (n = %s household-years).", nfmt(nrow(u))), ust = t1_ust, notlar = t1_not, grup_satir = t1u$grup, girinti = t1u$gir, ilk_gen = 2.0)
tablo_cikar(t1d$disp, paste0("TableS", ek_no$ozellik_dis), sprintf("Table S%s. Characteristics of eligible couple households outside the common-support sample (n = %s household-years).", ek_no$ozellik_dis, nfmt(u[Q == 0, .N])),
            ust = t1_ust, notlar = c(t1_not, sprintf("Cells suppressed in Table 1 are also suppressed here, and vice versa, so that suppressed values cannot be derived from %s.", tS("ozellik"))), grup_satir = t1d$grup, girinti = t1d$gir, klasor = ek_kl, ilk_gen = 2.0)
ee_blok <- list(c("M1", 2), c("M2", 2), c("M3", 2), c("M2", 1), c("M2", 3))
ee_disp <- rbindlist(lapply(ee_blok, function(b) {
  x <- E_tum[model == b[1] & rope == as.numeric(b[2])][match(e_satir, buyukluk)]
  rbind(data.table(Comparison = sprintf("%s, ROPE ±%s %s", etk$model[[b[1]]], b[2], if (b[2] == "1") "point" else "points")),
        x[, .(Comparison = e_et(buyukluk), `Estimate (95% CrI)` = ga(tahmin, alt, ust, 1), `P(Δ < −ROPE)` = f2(p_alt), `P(|Δ| ≤ ROPE)` = f2(p_ic),
                 `P(Δ > ROPE)` = f2(p_ust), `P(Δ > 0)` = f2(p_poz), `MCSE, median` = formatC(mcse_tahmin, format = "f", digits = 3), `MCSE, limits` = formatC(pmax(mcse_alt, mcse_ust), format = "f", digits = 3))], fill = TRUE)
}))
p_sira <- c(M = "p_{M}", D0.10 = "p_{D}(0.1)", D0.50 = "p_{D}(0.5)", D0.90 = "p_{D}(0.9)^{†}", F = "p_{F}")
ee_p <- rbindlist(lapply(c("M1", "M2", "M3"), function(m) {
  x <- P_tum[model == m][match(names(p_sira), senaryo)]
  rbind(data.table(Comparison = sprintf("%s, standardized probability, %%", etk$model[[m]])),
        x[, .(Comparison = unname(p_sira[senaryo]), `Estimate (95% CrI)` = ga(tahmin, alt, ust, 1), `MCSE, median` = formatC(mcse_tahmin, format = "f", digits = 3), `MCSE, limits` = formatC(mcse_sinir, format = "f", digits = 3))], fill = TRUE)
}))
ee_disp <- rbind(ee_disp, ee_p, fill = TRUE)
for (j in names(ee_disp)) set(ee_disp, which(is.na(ee_disp[[j]])), j, "")
ee_grup <- c(seq(1, length(ee_blok) * (length(e_satir) + 1), by = length(e_satir) + 1), length(ee_blok) * (length(e_satir) + 1) + seq(1, 3 * (length(p_sira) + 1), by = length(p_sira) + 1))
ek_cikar("E_ek", ee_disp, "Prespecified comparisons in all three models, with alternative regions of practical equivalence (ROPE), and standardized probabilities.", yatay = TRUE,
         grup_satir = ee_grup, girinti = setdiff(seq_len(nrow(ee_disp)), ee_grup),
         notlar = c("Percentage points; posterior median and 95% equal-tailed credible interval (CrI). M3 adds spouses' activity limitation and chronic illness and housing tenure, measured at interview.",
                    "MCSE, Monte Carlo standard error of the posterior median and of the larger of the two interval limits.",
                    sprintf("^{†} Relies on p_{D}(0.9): only %d dual-earner household-years in Q had a wife's share of 0.85–0.95 (prespecified minimum 200), and 0.9 lies beyond the 97.5th weighted percentile of shares (%.2f).", q[G == "D" & s >= 0.85 & s <= 0.95, .N], egri_aralik[2])))
kat_et <- function(nm) {
  nm <- sub("^b_", "", nm)
  sabit <- c(Intercept = "Intercept", gM = "Husband-only earner", gF = "Wife-only earner", n_0_5 = "Children aged 0–5", n_6_13 = "Children aged 6–13", n_14_17 = "Children aged 14–17",
             n_diger_18_64 = "Other adults aged 18–64", n_diger_65 = "Other adults aged ≥65", yil_f2024 = "Survey year 2024", yil_f2025 = "Survey year 2025",
             k_kisit = "Wife: activity limitation", e_kisit = "Husband: activity limitation", k_kronik = "Wife: chronic illness", e_kronik = "Husband: chronic illness",
             mulkiyetkiraci = "Tenure: tenant", mulkiyetlojman = "Tenure: employer-provided", mulkiyetkirasiz = "Tenure: rent-free", sd_ibbs2__Intercept = "SD, NUTS-2 intercept", sd_zincir__Intercept = "SD, linkage-chain intercept")
  out <- ifelse(nm %in% names(sabit), sabit[nm], nm)
  out <- ifelse(grepl("^fs[0-9]", nm), paste("Share spline, basis", sub("fs", "", nm)), out)
  out <- ifelse(grepl("^gE[0-9]", nm), paste("Couple's earnings spline, basis", sub("gE", "", nm)), out)
  out <- ifelse(grepl("^hO[0-9]", nm), paste("Other income spline, basis", sub("hO", "", nm)), out)
  out <- ifelse(grepl("^ky[0-9]", nm), paste("Wife's age spline, basis", sub("ky", "", nm)), out)
  out <- ifelse(grepl("^ey[0-9]", nm), paste("Husband's age spline, basis", sub("ey", "", nm)), out)
  ilk_kucuk <- function(x) paste0(tolower(substr(x, 1, 1)), substring(x, 2))
  out <- ifelse(grepl("^k_egitim_f", nm), paste("Wife's education:", ilk_kucuk(etk$egitim[sub("k_egitim_f", "", nm)])), out)
  out <- ifelse(grepl("^e_egitim_f", nm), paste("Husband's education:", ilk_kucuk(etk$egitim[sub("e_egitim_f", "", nm)])), out)
  unname(out)
}
katsayi_ozet <- function(fit, m) {
  dm <- as_draws_matrix(fit, variable = c("^b_", "^sd_"), regex = TRUE)
  data.table(terim = colnames(dm), model = m, med = apply(dm, 2, median), alt = apply(dm, 2, quantile, 0.025), ust = apply(dm, 2, quantile, 0.975))
}
kt <- rbind(katsayi_ozet(fit_M1, "M1"), katsayi_ozet(fit_M2, "M2"), katsayi_ozet(fit_M3, "M3"))
fwrite(kt, "Results/katsayilar_M1_M3.csv")
kt[, hucre := ga(med, alt, ust, 2)]
kt_disp <- dcast(kt, terim ~ model, value.var = "hucre", fill = "")
kt_disp <- kt_disp[order(match(terim, unique(kt[model == "M3", terim])))]
kt_disp[, terim := kat_et(terim)]
setnames(kt_disp, c("Term", etk$model[["M1"]], etk$model[["M2"]], etk$model[["M3"]]))
ek_cikar("katsayi", kt_disp, "Posterior summaries of all coefficients and variance components (logit scale).",
         notlar = c("Posterior median (95% CrI). Reference categories: dual-earner couple with an equal split (share spline centered at 0.5), no diploma, survey year 2023, owner-occupier.",
                    sprintf("Coefficients are conditional on the NUTS-2 and linkage-chain intercepts; with a chain SD near %.1f they are larger in magnitude than population-averaged coefficients. Spline coefficients are not interpretable individually; standardized comparisons are in Table 2. Employer-provided housing: %d household-years in Q.", sz_ozet$medyan, q[mulkiyet == "lojman", .N])))
kd_disp <- fd_sonuc[, .(`Husband's status` = etk$koca_durumu[kategori], n = paste0(nfmt(n), fifelse(n >= 20 & n <= 50, "^{a}", "")), Events = nfmt(olay),
                        `Crude prevalence, %` = fifelse(n < 20, "–", f1(ham_yayginlik)),
                        `p_{F,k}` = fifelse(n < 20, "–", ga(pF_tahmin, pF_alt, pF_ust, 1)), `p_{D}(0.9)` = fifelse(n < 20, "–", ga(pD09_tahmin, pD09_alt, pD09_ust, 1)),
                        `Estimate (95% CrI)` = fifelse(n < 20, "–", ga(tahmin, alt, ust, 1)), `P(Δ < −2)` = fifelse(n < 20, "–", f2(p_alt)), `P(|Δ| ≤ 2)` = fifelse(n < 20, "–", f2(p_ic)), `P(Δ > 2)` = fifelse(n < 20, "–", f2(p_ust)),
                        `p_{F,k} − p_{D}(0.75)` = fifelse(n < 20, "–", ga(E075_tahmin, E075_alt, E075_ust, 1)), `p_{F,k} − p_{M}` = fifelse(n < 20, "–", ga(EM_tahmin, EM_alt, EM_ust, 1)))]
diger_n <- q[G == "F" & e_durum_gy == "diger_faal_olmayan", .N]
diger_engel_yuzde <- round(100 * q[G == "F" & e_durum_gy == "diger_faal_olmayan" & e_FI010 == 8, .N] / diger_n)
ek_cikar("koca", kd_disp, "Wife-only earner couples by the husband's status in the income year: crude and standardized food deprivation.", yatay = TRUE,
         ust = list(degerler = c("Husband's status", "n", "Events", "Crude prevalence, %", "Standardized probability, % (95% CrI)", "E_{3a,k} = p_{F,k} − p_{D}(0.9)^{†}", "Comparisons not using the share of 0.9^{p} (95% CrI)"),
                    genislik = c(1, 1, 1, 1, 2, 4, 2), dikey = 1:4),
         notlar = c("Status in which the husband spent most months of the income year. Standardized probabilities use the wife-only earner couples in each status category (Q_{k}) with their own covariates; differences in percentage points. Each column compares the same couples under two scenarios; categories are not compared with one another.",
                    "^{†} E_{3a,k} = p_{F,k} − p_{D}(0.9); relies on p_{D}(0.9), supported by few dual-earner household-years with a wife's share of 0.85–0.95. ^{p} Added after the main results were seen: comparisons with a share of 0.75 (within the observed range) and with the husband-only earner scenario.",
                    sprintf("Crude prevalence weighted. Other inactive: at the interview, most husbands (%d%%) reported disability or a long-standing health problem as their main status.",
                            diger_engel_yuzde)))
yy_uzun <- rbind(yil_d[order(match(kose, c("M", "F")), match(olcek, c("delta_k + d_k,t (logit)", "d_k,t (logit)"))),
                       .(blok = "Logit scale", Quantity = paste0(etk$G[kose], ": ", fifelse(olcek == "d_k,t (logit)", "year deviation d_{k,t}", "δ_{k} + d_{k,t}")), Year = yil, h = ga(tahmin, alt, ust, 2))],
                 yil_olas[model == "M2_yil" & senaryo %in% c("M", "D0.10", "D0.50", "D0.90", "F")][order(match(senaryo, c("M", "D0.10", "D0.50", "D0.90", "F"))),
                          .(blok = "Standardized probability, %", Quantity = c(M = "p_{M}", D0.10 = "p_{D}(0.1)", D0.50 = "p_{D}(0.5)", D0.90 = "p_{D}(0.9)^{†}", F = "p_{F}")[senaryo], Year = yil, h = ga(tahmin, alt, ust, 1))],
                 yil_E[buyukluk %in% c("E3a", "E3b", "E4")][order(match(buyukluk, c("E3a", "E3b", "E4")))][,
                       .(blok = "Comparison, percentage points", Quantity = e_et(buyukluk), Year = yil, h = ga(tahmin, alt, ust, 1))])
yy_disp <- dcast(yy_uzun, blok + Quantity ~ Year, value.var = "h", fun.aggregate = function(v) v[1], fill = "")
yy_disp <- yy_disp[order(match(blok, unique(yy_uzun$blok)), match(Quantity, unique(yy_uzun$Quantity)))]
yy_disp <- rbindlist(lapply(unique(yy_disp$blok), function(b) rbind(data.table(Quantity = b), yy_disp[blok == b, !"blok"], fill = TRUE)))
for (j in names(yy_disp)) set(yy_disp, which(is.na(yy_disp[[j]])), j, "")
yy_grup <- which(yy_disp$Quantity %in% unique(yy_uzun$blok))
ek_cikar("yil", yy_disp, "Variation of the single-earner differences across survey years (M2 with year-specific deviations).",
         grup_satir = yy_grup, girinti = setdiff(seq_len(nrow(yy_disp)), yy_grup),
         notlar = c("Posterior median (95% CrI). δ_{k,t} = δ_{k} + d_{k,t}, k = husband-only or wife-only; d_{k,t} ~ N(0, 0.5^{2}) with Σ_{t} d_{k,t} = 0; the share curve f(s) is common to all years. Probabilities and comparisons are standardized within each survey year.",
                    sprintf("Years are survey years; differences between years in percentage points also reflect differences in baseline probabilities. ^{†} Relies on p_{D}(0.9) (%d dual-earner household-years in Q with a wife's share of 0.85–0.95).", q[G == "D" & s >= 0.85 & s <= 0.95, .N]),
                    sprintf("Single-year models (%s), in which the share curve and all other terms are year-specific, give a different pattern for E_{3b}: 2023 %s, 2024 %s, 2025 %s.", tS("duy_AC"),
                            f1(duy_tum[kod == "A2_2023" & buyukluk == "E3b", tahmin]), f1(duy_tum[kod == "A2_2024" & buyukluk == "E3b", tahmin]), f1(duy_tum[kod == "A1_2025" & buyukluk == "E3b", tahmin]))))
s17_grup <- c(A2_2023 = "Single survey years", A2_2024 = "Single survey years", A1_2025 = "Single survey years",
              A3_ucret = "Sample restrictions", A4_ucretsiz_aile_yok = "Sample restrictions", A5_tek_cift = "Sample restrictions", A6_tum_yaslar = "Sample restrictions", A7_TR63_yok = "Sample restrictions",
              A8_durum_uyumu = "Sample restrictions", A11_esit_haric = "Sample restrictions", A9_tum_uygun = "Target population and common support", A10_destek3 = "Target population and common support",
              C15_esik5 = "Definitions", C16_O_izk = "Definitions", C17_esdeger = "Definitions", C18_fs_df3 = "Share curve", C18_fs_df5 = "Share curve", C18_fs_sabit = "Share curve",
              C20_fs_prior05 = "Share curve", C20_fs_prior2 = "Share curve", C21_b25 = "Priors on all coefficients", C21_b5 = "Priors on all coefficients", M3 = "Extended conditioning",
              C19_capa25 = "Alternative anchors (different quantities)", C19_capa20 = "Alternative anchors (different quantities)")
duy_disp_kur <- function(gr) {
  x <- duy_tum[grup %in% gr & buyukluk %in% e_satir]
  x[, hucre := paste0(ga(tahmin, alt, ust, 1), fifelse(isaret == "m", "^{m}", fifelse(isaret == "u", "^{u}", "")))]
  w <- dcast(x, kod + n ~ buyukluk, value.var = "hucre")
  w <- w[order(match(kod, unique(c(orman_kod, names(etk$duyarlilik)))))]
  isr <- fifelse(w$kod %in% sonradan & grepl("^C19", w$kod), "^{p,c}", fifelse(w$kod %in% sonradan, "^{p}", ""))
  w[, .(kod, Analysis = paste0(etk$duyarlilik[kod], isr), `Question addressed` = etk$duyarlilik_soru[kod], n = nfmt(n), `E_{1}^{†}` = E1, `E_{2}^{†}` = E2, `E_{3a}^{†}` = E3a, `E_{3b}` = E3b, `E_{4}` = E4)]
}
duy_not_kur <- function(tab, ilk) {
  hucre <- unlist(tab)
  isaret <- c(if (any(grepl("\\^\\{m\\}", hucre))) "^{m} Differs materially from the main model (absolute difference > 1 point or a different most probable ROPE region). For E_{3a}, flags without a difference > 1 point arise because P(|Δ| ≤ 2) and P(Δ > 2) are nearly equal in the main model.",
              if (any(grepl("\\^\\{u\\}", hucre))) "^{u} Only the most probable ROPE region differs, and the difference between the two leading probabilities is less than twice its Monte Carlo standard error (added after the main results were seen).",
              if (any(grepl("−0\\.0[,)]|-0\\.0[,)]", hucre))) "−0.0, an interval limit below zero that rounds to zero.",
              if (any(grepl("\\^\\{p", hucre))) "^{p} Added after the main results were seen.")
  c(ilk, paste(isaret, collapse = " "),
    if (any(grepl("\\^\\{p,c\\}", hucre))) "^{c} Alternative anchors: 0.25/0.75 or 0.2/0.8 replace 0.1/0.9 in E_{1}, E_{2}, E_{3a} and E_{3b}, so these are different quantities and are not compared with the main model; E_{4} is unchanged by definition. A share of 0.8 lies just beyond the central 95% of observed shares.",
    paste0(duy_hanc, if (any(grepl("\\^\\{p,c\\}", hucre))) ", except in the alternative-anchor rows." else "."))
}
duy_hanc <- sprintf("^{†} Relies on p_{D}(0.9) (%d dual-earner household-years in Q with a wife's share of 0.85–0.95)", q[G == "D" & s >= 0.85 & s <= 0.95, .N])
s16 <- duy_disp_kur(c("ana", "B"))[, kod := NULL]
ek_cikar("duy_B", s16, "Sensitivity to the estimation approach.", yatay = TRUE,
         notlar = duy_not_kur(s16, "Percentage points; posterior median (95% CrI), except the survey-weighted model: estimate (95% confidence interval, normal approximation with the standard error from 1,000 linkage-chain bootstrap replicate weights). The survey-weighted model uses the available design information; it is not a full design-based analysis."))
s17_ham <- duy_disp_kur(c("ana", "A", "C"))
s17_ana <- s17_ham[kod == "M2"][, kod := NULL]
s17_g <- grupla(s17_ham[kod != "M2"][, Blok := s17_grup[kod]][, c("Blok", setdiff(names(s17_ham), "kod")), with = FALSE], "Blok")
s17 <- rbind(s17_ana, s17_g$disp)
ek_cikar("duy_AC", s17, "Sensitivity to the sample, period and definitions.", yatay = TRUE,
         grup_satir = s17_g$grup + 1L, girinti = s17_g$gir + 1L,
         notlar = duy_not_kur(s17, "Percentage points; posterior median (95% CrI). Sample restrictions change the target population; the all-ages analysis uses its own common support. Single-year models have no linkage-chain intercept. The equivalized-income analysis uses equivalized household disposable income relative to its person-weighted median in each survey year."))
sure_ekle("ek tablolar", t0)

t0 <- Sys.time()
ek1_isaret <- "^{p} Added after the main results were seen; the expected directions were stated in the addendum of 1 November 2026 before the models were fitted."
t19_gruplar <- list(M = q[G == "M"], D1 = q[G == "D" & s < 0.40], D2 = q[G == "D" & s >= 0.40 & s <= 0.60], D3 = q[G == "D" & s > 0.60], F = q[G == "F"], Dc = q[G == "D" & s >= 0.05 & s <= 0.15])
t19_hucre <- function(x, p) {
  w <- x$HB040
  tz <- x[[paste0(p, "tze")]]
  saat <- x[[paste0(p, "FI150")]]
  cal <- x[[paste0(p, "FI010")]] %in% 1:4 & !is.na(saat) & saat > 0
  n_cal <- sum(cal)
  saat_med <- if (n_cal > 0) medq(saat[cal], w[cal], 0) else ""
  saat_40 <- if (n_cal > 0) f1(100 * sum(w[cal] * (saat[cal] >= 40)) / sum(w[cal])) else ""
  c(medq(x[[paste0(p, "FI260")]], w, 0), medq(x[[paste0(p, "FI270")]], w, 0), medq(tz, w, 1), f1(100 * sum(w * (tz >= 10)) / sum(w)), f1(100 * sum(w * (tz == 0)) / sum(w)),
    kucuk(saat_med, n_cal), kucuk(saat_40, n_cal), nfmt(n_cal))
}
t19_et <- c("Full-time months, median (Q_{1}–Q_{3})", "Part-time months, median (Q_{1}–Q_{3})", "Full-time-equivalent months, median (Q_{1}–Q_{3})", "Full-time-equivalent months ≥ 10, %",
            "Full-time-equivalent months = 0, %", "Weekly hours at interview, median (Q_{1}–Q_{3})^{b}", "Weekly hours ≥ 40 at interview, %^{b}", "Working at interview, n^{b}")
t19_mat <- function(p) do.call(cbind, lapply(t19_gruplar, t19_hucre, p = p))
t19_dusuk <- q[G == "D" & s < 0.20]
t19_alt <- t19_dusuk[, .(n = .N, ham = 100 * sum(HB040 * Y) / sum(HB040)), keyby = .(tze_grup = fifelse(k_tze <= 6, "le6", "gt6"))]
t19_alt_hucre <- function(g) {
  x <- t19_alt[tze_grup == g]
  if (!nrow(x)) return("–")
  kucuk(paste0(f1(x$ham), " (", nfmt(x$n), ")"), x$n)
}
t19_bos <- rep("", length(t19_gruplar))
t19_disp <- rbind(data.table(t(c("Household-years, n", vapply(t19_gruplar, function(x) nfmt(nrow(x)), "")))),
                  data.table(t(c("Wife", t19_bos))), data.table(cbind(t19_et, t19_mat("k_"))),
                  data.table(t(c("Husband", t19_bos))), data.table(cbind(t19_et, t19_mat("e_"))),
                  data.table(t(c("Dual-earner couples with a wife's share below 0.20", t19_bos))),
                  data.table(t(c("Wife's full-time-equivalent months ≤ 6: food deprivation, % (n)", "", t19_alt_hucre("le6"), "", "", "", ""))),
                  data.table(t(c("Wife's full-time-equivalent months > 6: food deprivation, % (n)", "", t19_alt_hucre("gt6"), "", "", "", ""))), use.names = FALSE)
setnames(t19_disp, c("Characteristic^{p}", "Husband-only earner", "<0.40", "0.40–0.60", ">0.60", "Wife-only earner", "Dual-earner, share 0.05–0.15"))
t19_grup <- which(t19_disp[[1]] %in% c("Wife", "Husband", "Dual-earner couples with a wife's share below 0.20"))
t19_tutarsiz <- list(M_kadin_tze_pozitif = q[G == "M" & k_tze > 0, .N], D_kadin_tze_sifir = q[G == "D" & k_tze == 0, .N], D_koca_tze_sifir = q[G == "D" & e_tze == 0, .N], F_koca_tze_pozitif = q[G == "F" & e_tze > 0, .N])
ek_cikar("zaman_T1", t19_disp, "Work intensity of the spouses in the income year by earner structure and wife's share in the common-support sample.", yatay = TRUE,
         ust = list(degerler = c("Characteristic^{p}", "Husband-only earner", "Dual-earner, by wife's share", "Wife-only earner", "Dual-earner, share 0.05–0.15"), genislik = c(1, 1, 3, 1, 1), dikey = c(1, 2, 6, 7)),
         grup_satir = t19_grup, girinti = setdiff(seq_len(nrow(t19_disp)), c(1L, t19_grup)), ilk_gen = 2.4,
         notlar = c("n unweighted; medians, quartiles and percentages weighted with the cross-sectional household weights. Full-time-equivalent months = full-time months + 0.5 × part-time months in the income year (FI260, FI270); the weight of 0.5 is an assumption of this study.",
                    "^{b} Main job, among spouses working at the interview (FI010 = 1–4); measured at the interview, not in the income year. –, fewer than 20 household-years; ^{a}, 20–50.",
                    sprintf("Months recorded without own earnings, and earnings without recorded months: the wife has full-time-equivalent months > 0 in %s husband-only earner couples (mostly unpaid family work); the wife has none in %s and the husband none in %s dual-earner couples; the husband has months > 0 in %s wife-only earner couples.",
                            nfmt(t19_tutarsiz$M_kadin_tze_pozitif), nfmt(t19_tutarsiz$D_kadin_tze_sifir), nfmt(t19_tutarsiz$D_koca_tze_sifir), nfmt(t19_tutarsiz$F_koca_tze_pozitif)),
                    "The two rows on couples with a share below 0.20 are shown in the <0.40 column; crude weighted prevalence of food deprivation (unweighted n).",
                    ek1_isaret))

t20_satir <- function(et, x, m2 = "") data.table(Quantity = et, `Estimate (95% CrI)` = ga(x$tahmin, x$alt, x$ust, 1), `P(Δ < −2)` = f2(x$p_alt), `P(|Δ| ≤ 2)` = f2(x$p_ic), `P(Δ > 2)` = f2(x$p_ust),
                                                  `P(Δ > 0)` = f2(x$p_poz), `M2, estimate (95% CrI)` = m2)
t20_m2 <- E_tum[model == "M2" & rope == 2]
t20_disp <- rbind(data.table(Quantity = sprintf("Dual-earner couples in Q (n = %s)", nfmt(nrow(qD)))),
                  t20_satir("T2: wife's full-time-equivalent months, 12 vs. 6", x1_T[buyukluk == "T2"]),
                  t20_satir("T2′: husband's full-time-equivalent months, 12 vs. 6", x1_T[buyukluk == "T2p"]),
                  t20_satir("T2 − T2′", x1_T[buyukluk == "T2_eksi_T2p"]),
                  data.table(Quantity = sprintf("Dual-earner couples in Q (n = %s); fixed interior knots at 4 and 8 months", nfmt(nrow(qD)))),
                  t20_satir("T2", x1s_T[buyukluk == "T2"]), t20_satir("T2′", x1s_T[buyukluk == "T2p"]), t20_satir("T2 − T2′", x1s_T[buyukluk == "T2_eksi_T2p"]),
                  data.table(Quantity = sprintf("All couples in Q (n = %s); wife's FTE months 0 in the husband-only scenario", nfmt(nrow(q)))),
                  rbindlist(lapply(c("E1", "E2", "E3a", "E3b", "E4"), function(k) t20_satir(e_et(k), E_X1[buyukluk == k], ga(t20_m2[buyukluk == k, tahmin], t20_m2[buyukluk == k, alt], t20_m2[buyukluk == k, ust], 1)))),
                  data.table(Quantity = "All couples in Q; FTE months at observed values in all scenarios"),
                  rbindlist(lapply(c("E1", "E2", "E3a", "E3b", "E4"), function(k) t20_satir(e_et(k), E_X1g[buyukluk == k], ga(t20_m2[buyukluk == k, tahmin], t20_m2[buyukluk == k, alt], t20_m2[buyukluk == k, ust], 1)))), fill = TRUE)
for (j in names(t20_disp)) set(t20_disp, which(is.na(t20_disp[[j]])), j, "")
setnames(t20_disp, "Quantity", "Quantity^{p}")
t20_grup <- which(t20_disp[[2]] == "")
tn_x <- tani_tum[model %in% ek1_modeller]
ek_cikar("zaman_X1", t20_disp, "Work intensity of the spouses and food deprivation: standardized differences from the work-intensity model (X1), in percentage points.", yatay = TRUE,
         ust = list(degerler = c("Quantity^{p}", "Work-intensity model (X1)", "M2, estimate (95% CrI)"), genislik = c(1, 5, 1), dikey = c(1, 7)),
         grup_satir = t20_grup, girinti = setdiff(seq_len(nrow(t20_disp)), t20_grup),
         notlar = c(sprintf("X1 = M2 + natural cubic splines (3 df) of the wife's and the husband's full-time-equivalent (FTE) months, boundary knots 0 and 12; interior knots at the weighted tertiles of values between 0 and 12 (wife %s; husband %s), because FTE months are heaped at 0 and 12.",
                            paste(formatC(tz_k$knots, format = "f", digits = 1), collapse = " and "), paste(formatC(tz_e$knots, format = "f", digits = 1), collapse = " and ")),
                    "T2 and T2′: standardized over dual-earner couples with their observed share, incomes and covariates, setting one spouse's FTE months to 12 and 6 and keeping the other spouse's observed. T2 − T2′ from the same draws.",
                    sprintf("E_{1}–E_{4} in X1, as specified in the addendum: in the husband-only scenario the wife's FTE months are set to 0; in the dual-earner and wife-only scenarios they keep their observed values; the husband's FTE months are observed in all scenarios. The dual-earner scenarios are thus applied to %s husband-only household-years whose wife mostly has 0 FTE months, a combination observed in %s dual-earner couples, and the husband-only category and the wife's FTE months are only weakly separated. The second block keeps both spouses' FTE months at observed values in all scenarios. ^{†} Relies on p_{D}(0.9).",
                            nfmt(x1_eslesme$M_hane), nfmt(x1_eslesme$D_kadin_tze_sifir)),
                    sprintf("X1: max R-hat %.3f; min bulk and tail ESS %s and %s; %s divergent transitions; min E-BFMI %.2f; fixed-knot version: max R-hat %.3f, min ESS %s, %s divergent transitions. MCSE of medians and interval limits %s.", tn_x[model == "X1_tze", rhat_max], nfmt(tn_x[model == "X1_tze", ess_bulk_min]), nfmt(tn_x[model == "X1_tze", ess_tail_min]),
                            nfmt(tn_x[model == "X1_tze", diverjans]), tn_x[model == "X1_tze", ebfmi_min], tn_x[model == "X1_tze_sabit", rhat_max], nfmt(tn_x[model == "X1_tze_sabit", min(ess_bulk_min, ess_tail_min)]), nfmt(tn_x[model == "X1_tze_sabit", diverjans]),
                            if (max(x1_mcse$mcse_tahmin, x1_mcse$mcse_alt, x1_mcse$mcse_ust) < 0.1) "< 0.1 points" else sprintf("up to %.2f points", max(x1_mcse$mcse_tahmin, x1_mcse$mcse_alt, x1_mcse$mcse_ust))),
                    ek1_isaret))

t21_hucre <- function(av, a, g) {
  x <- x2_hucre[degisken == av & deger == a & G == g]
  paste0(nfmt(x$n), " (", nfmt(x$olay), ")")
}
t21_E <- function(av, k) {
  e0 <- x2_E[degisken == av & deger == 0 & buyukluk == k]
  e1 <- x2_E[degisken == av & deger == 1 & buyukluk == k]
  fk <- x2_fark[degisken == av & buyukluk == k]
  cbind(c(ga(e0$tahmin, e0$alt, e0$ust, 1), f2(e0$p_alt), f2(e0$p_ic), f2(e0$p_ust), ""), c(ga(e1$tahmin, e1$alt, e1$ust, 1), f2(e1$p_alt), f2(e1$p_ic), f2(e1$p_ust), ""),
        c(ga(fk$tahmin, fk$alt, fk$ust, 1), "", "", "", f2(fk$p_poz)))
}
t21_et_E <- c("Estimate (95% CrI)", "P(Δ < −2)", "P(|Δ| ≤ 2)", "P(Δ > 2)", "P(difference > 0)")
t21_blok <- function(k) cbind(t21_et_E, t21_E("yet_A", k), t21_E("yet_Ap", k))
t21_say <- t(vapply(c("M", "D", "F"), function(g) c(etk$G[[g]], t21_hucre("yet_A", 0, g), t21_hucre("yet_A", 1, g), "", t21_hucre("yet_Ap", 0, g), t21_hucre("yet_Ap", 1, g), ""), character(7)))
t21_etk <- function(av) ga(x2_etk[degisken == av, tahmin], x2_etk[degisken == av, alt], x2_etk[degisken == av, ust], 2)
t21_disp <- as.data.table(rbind(c("Household-years (events)", rep("", 6)), t21_say,
                                c(e_et("E3b"), rep("", 6)), t21_blok("E3b"),
                                c(e_et("E4"), rep("", 6)), t21_blok("E4"),
                                c("Interaction with the husband-only earner category, logit scale (95% CrI)", "", "", t21_etk("yet_A"), "", "", t21_etk("yet_Ap"))))
setnames(t21_disp, c("Quantity^{p}", "No", "Yes", "Yes − no", "No ", "Yes ", "Yes − no "))
t21_grup <- which(t21_disp[[2]] == "" & t21_disp[[3]] == "" & t21_disp[[4]] == "")
ek_cikar("zaman_X2", t21_disp, "Other adults in the household and the single-earner comparisons: E_{3b} and E_{4} by the presence of another adult (X2 models), in percentage points.", yatay = TRUE,
         ust = list(degerler = c("Quantity^{p}", "Other adult not working at the interview (A)", "Any other adult (A′)"), genislik = c(1, 3, 3), dikey = 1L),
         grup_satir = t21_grup, girinti = setdiff(seq_len(nrow(t21_disp)), t21_grup),
         notlar = c(sprintf("A = 1 if a household member other than the reference couple, aged 18 or older, completed the individual questionnaire and was not working at the interview (FI010 not 1–4); %s members aged 18 or older without an individual questionnaire (%s households) were not counted as not working. A′ = 1 if any other member aged 18 or older lived in the household.", nfmt(x2_kayitsiz$uye), nfmt(x2_kayitsiz$hane)),
                    "X2 = M2 + A + A × (husband-only, wife-only and share-spline terms); X2′ uses A′. Comparisons standardized over the households in each group (A = 0, A = 1) with their own covariates; the difference is computed from the same draws.",
                    "Prespecified criterion for an interpretation in favor of the time channel: |E_{3b}| smaller when A = 1 and a 95% interval of the difference that excludes zero.",
                    sprintf("Monte Carlo standard errors of the medians and interval limits of the reported quantities are at most %.2f points (%.2f including the comparisons that rely on p_{D}(0.9)), slightly above the 0.1-point criterion used for the main models.",
                            max(x2_mcse[buyukluk %in% c("E3b", "E4"), c(mcse_tahmin, mcse_alt, mcse_ust)]), max(x2_mcse$mcse_tahmin, x2_mcse$mcse_alt, x2_mcse$mcse_ust)),
                    sprintf("X2: max R-hat %.3f, min ESS %s, %s divergent transitions, min E-BFMI %.2f; X2′: max R-hat %.3f, min ESS %s, %s divergent transitions, min E-BFMI %.2f.",
                            tn_x[model == "X2_A", rhat_max], nfmt(tn_x[model == "X2_A", min(ess_bulk_min, ess_tail_min)]), nfmt(tn_x[model == "X2_A", diverjans]), tn_x[model == "X2_A", ebfmi_min],
                            tn_x[model == "X2_Ap", rhat_max], nfmt(tn_x[model == "X2_Ap", min(ess_bulk_min, ess_tail_min)]), nfmt(tn_x[model == "X2_Ap", diverjans]), tn_x[model == "X2_Ap", ebfmi_min]),
                    ek1_isaret))
t19_kutu <- rbindlist(lapply(names(t19_gruplar), function(g) {
  x <- t19_gruplar[[g]]
  data.table(grup = g, n = nrow(x), p05 = wq(x$k_tze, x$HB040, 0.05), p10 = wq(x$k_tze, x$HB040, 0.10), p25 = wq(x$k_tze, x$HB040, 0.25), p50 = wq(x$k_tze, x$HB040, 0.50),
             p75 = wq(x$k_tze, x$HB040, 0.75), p90 = wq(x$k_tze, x$HB040, 0.90), p95 = wq(x$k_tze, x$HB040, 0.95), ortalama = sum(x$HB040 * x$k_tze) / sum(x$HB040),
             sifir = 100 * sum(x$HB040 * (x$k_tze == 0)) / sum(x$HB040), oniki = 100 * sum(x$HB040 * (x$k_tze == 12)) / sum(x$HB040))
}))
fwrite(t19_kutu, file.path(ddir, "figur_verileri", "figS6a_kadin_tze.csv"))
zaman_kanali <- list(T1 = list(tablo = t19_disp, kadin_tze_dagilimi = t19_kutu, pay_020_alti = t19_alt, tutarsizliklar = t19_tutarsiz),
                     X1 = list(dugumler = list(kadin = tz_k, koca = tz_e), T2 = x1_T, egriler = x1_egri, E_X1 = E_X1, E_M2 = t20_m2, tanilar = tn_x[model %in% c("X1_tze", "X1_tze_sabit")],
                               E_X1_gozlenen = E_X1g, senaryo_eslesme = x1_eslesme, sabit_dugum = list(dugumler = tz_s, T2 = x1s_T)),
                     X2 = list(hucreler = x2_hucre, kesinligi_dusuk = x2_dusuk, kayitsiz_18_ustu = x2_kayitsiz, E = x2_E, fark = x2_fark, etkilesim_logit = x2_etk, olcut = x2_olcut, tanilar = tn_x[grepl("^X2", model)]))
sure_ekle("Ek 1 tabloları", t0)

t0 <- Sys.time()
tani_ana <- tani_tum[!(model %in% ek1_modeller)]
prot_ekle("bütün Bayesçi modeller", "geri dönüş kuralı 1", "divergence ya da R-hat > 1,01 varsa adapt_delta 0,95 ve 0,99; ESS < 400 ise iterasyon artırılır",
          sprintf("%d model; divergence toplamı %d; R-hat en büyük %.4f; ESS en küçük %d", nrow(tani_ana), sum(tani_ana$diverjans), max(tani_ana$rhat_max), min(tani_ana$ess_bulk_min, tani_ana$ess_tail_min)),
          if (sum(tani_tum$diverjans) == 0 && max(tani_tum$rhat_max) <= 1.01) "gerekmedi" else "uygulandı (model satırlarına bakın)")
sayilar <- list(
  olusturma = format(Sys.time(), "%Y-%m-%d %H:%M"),
  dogrulama = list(kontrol = length(dogr), tuttu = sum(rbindlist(dogr)$durum == "Tuttu")),
  akis = setNames(as.list(akis$n), akis$dugum),
  m_t = setNames(as.list(m_t$m_t), m_t$yil),
  es_baglari = bag_ozet,
  fizibilite = list(yil_G = fread("Results/denetim/fizibilite_yil_G.csv"), capa = f2_c, pay_yuzdelik = f2_q, koca_durumu = say_maske(f4, "n"), bayraklar = say_maske(f4_ucretsiz), reis_kadin = reis_kadin),
  baglanti = list(eslesme = eslesme_sayi, kalite = bag_kalite_ozet, zincir_uzunluk = zincir_uzunluk, oruntu = oruntu_yayin, reddedilen = red_ozet),
  ortak_destek = list(sinirlar = od$sinir, dislanan = od_dis, Q_kurallari = fiz_q, pay_yuzdelik_Q = pay_q, dugum_s = dugum_s, egri_aralik = egri_aralik, tum_yaslar_Q = sum(od6$Q), tum_yaslar_uygun = nrow(ut)),
  oncel_ongoru = oo_ozet,
  sigma_zincir = sigma_ek,
  sigma_zincir_M2 = sz_ozet,
  zaman_kanali = zaman_kanali,
  ortak_destek_tani = od_tani,
  ortak_destek_ic_dis_yayginlik = say_maske(od_yay, "n"),
  a10_dislanan_agirlikli_yuzde = a10_dis,
  esit_kazanc = esit_kazanc,
  koca_diger_faal_olmayan_engel_yuzde = diger_engel_yuzde,
  c19_olcekli_genislik = c19_olcek,
  tani_tum_parametreler = tam_tani,
  E = E_tum,
  olasiliklar = P_tum,
  egri = egri,
  egri_genlik = egri_genlik_ozet,
  koca_durumu = fd_sonuc,
  yil = list(logit = yil_d, E = yil_E, olasiliklar = yil_olas),
  duyarlilik = duy_tum,
  tanilar = tani_tum,
  protokol = protokol,
  ppc = rbind(ppc_M2, ppc_ek),
  model_sureleri = model_sureleri,
  adim_sureleri = rbindlist(sureler))
write_json(sayilar, "Results/sayilar.json", digits = NA, auto_unbox = TRUE, pretty = TRUE, dataframe = "rows", na = "null")
analiz_pk <- c(brms = "Bayesian multilevel logistic models (Stan interface, formula, priors, posterior draws)", cmdstanr = "CmdStan backend for brms",
               rstan = "Required by brms to build the fitted-model object", posterior = "Posterior draws, convergence diagnostics (R-hat, ESS) and Monte Carlo standard errors",
               survey = "Survey-weighted sensitivity model and linkage-chain bootstrap replicate weights", nnet = "Weighted multinomial model for the common support",
               statmod = "Gauss–Hermite quadrature for marginalizing over linkage-chain intercepts", splines = "Natural cubic spline bases (base R)")
yardimci_pk <- c(data.table = "Data management", arrow = "Parquet storage", readxl = "Reading the source workbook", flextable = "Word tables", officer = "Word documents",
                 openxlsx = "Excel tables", future = "Parallel computation", furrr = "Parallel map", jsonlite = "JSON output")
atif <- function(p) {
  ct <- citation(if (p == "splines") "base" else p)
  if (p == "statmod") ct <- citation("statmod", auto = TRUE)
  paste(format(ct, style = "text"), collapse = "\n\n")
}
satirlar <- c("ANALİZDE DOĞRUDAN ROL OYNAYAN PAKETLER", "")
for (p in names(analiz_pk)) satirlar <- c(satirlar, sprintf("## %s %s — %s", p, if (p == "splines") paste("(R", getRversion(), ")") else as.character(packageVersion(p)), analiz_pk[[p]]), atif(p), "")
satirlar <- c(satirlar, sprintf("## CmdStan %s — Stan sampler (No-U-Turn Hamiltonian Monte Carlo) used through cmdstanr", cmdstan_version()),
              "Carpenter B, Gelman A, Hoffman MD, Lee D, Goodrich B, Betancourt M, Brubaker M, Guo J, Li P, Riddell A (2017). “Stan: A Probabilistic Programming Language.” _Journal of Statistical Software_, *76*(1), 1-32. doi:10.18637/jss.v076.i01",
              "Stan Development Team. Stan Modeling Language Users Guide and Reference Manual, version 2.40. https://mc-stan.org", "",
              sprintf("## R %s", getRversion()), atif("splines"), "", "YARDIMCI PAKETLER", "")
for (p in names(yardimci_pk)) satirlar <- c(satirlar, sprintf("## %s %s — %s", p, as.character(packageVersion(p)), yardimci_pk[[p]]), atif(p), "")
satirlar <- c(satirlar, "PYTHON (figürler)", "",
              "## Python — figure scripts", "Van Rossum, G., & Drake, F. L. (2009). Python 3 Reference Manual. CreateSpace.", "",
              "## matplotlib — figures", "Hunter, J. D. (2007). Matplotlib: A 2D graphics environment. Computing in Science & Engineering, 9(3), 90–95. https://doi.org/10.1109/MCSE.2007.55", "",
              "## NumPy — arrays", "Harris, C. R., Millman, K. J., van der Walt, S. J., et al. (2020). Array programming with NumPy. Nature, 585, 357–362. https://doi.org/10.1038/s41586-020-2649-2", "",
              "## pandas — reading figure data", "McKinney, W. (2010). Data structures for statistical computing in Python. Proceedings of the 9th Python in Science Conference, 56–61. https://doi.org/10.25080/Majora-92bf1922-00a",
              "The pandas development team. pandas-dev/pandas: Pandas. Zenodo. https://doi.org/10.5281/zenodo.3509134", "",
              "## openpyxl — real subscripts and superscripts in tablolar_tumu.xlsx (Codes/xlsx_simge.py); auxiliary; no recommended citation",
              "## fonttools, Pillow — font embedding in PDF and RGB TIFF output; auxiliary; no recommended citation", "",
              "NOT (statmod): yukarıdaki künye citation(\"statmod\", auto = TRUE) ile paket açıklamasından üretildi; gauss.quad'ın belgesi Golub ve Welsch (1969) algoritmasına gönderme yapar.",
              "NOT (survey): citation(\"survey\") birden çok kaynak basar; svyglm için Lumley T (2004). Analysis of complex survey samples. Journal of Statistical Software, 9(8), 1-19. doi:10.18637/jss.v009.i08 yeterlidir.")
writeLines(satirlar, "Results/paket_atiflari.txt")
writeLines(c(capture.output(sessionInfo()), "", paste("CmdStan", cmdstan_version(), cmdstan_path())), "Results/sessionInfo.txt")
py_ortam <- system2(py, "Codes/python_ortam.py", stdout = TRUE, stderr = TRUE)
writeLines(py_ortam, "Results/python_ortam.txt")
py_surum <- function(p) sub(paste0("^", p, " "), "", grep(paste0("^", p, " "), py_ortam, value = TRUE))
yazilim <- rbind(data.table(Software = "R", Version = as.character(getRversion()), Role = "Statistical computing environment"),
                 data.table(Software = names(analiz_pk), Version = vapply(names(analiz_pk), function(p) if (p == "splines") as.character(getRversion()) else packageDescription(p)$Version, ""), Role = unname(analiz_pk)),
                 data.table(Software = "CmdStan", Version = as.character(cmdstan_version()), Role = "Stan sampler (No-U-Turn Hamiltonian Monte Carlo)"),
                 data.table(Software = names(yardimci_pk), Version = vapply(names(yardimci_pk), function(p) packageDescription(p)$Version, ""), Role = paste(unname(yardimci_pk), "(auxiliary)")),
                 data.table(Software = c("Python", "matplotlib", "NumPy", "pandas", "openpyxl", "fonttools", "Pillow"),
                            Version = c(sub("^Python ([^ ]+).*$", "\\1", py_ortam[1]), py_surum("matplotlib"), py_surum("numpy"), py_surum("pandas"), py_surum("openpyxl"), py_surum("fonttools"), py_surum("pillow")),
                            Role = c("Figures", "Figures", "Arrays (figures)", "Reading figure data", "Excel subscripts (auxiliary)", "Font embedding in PDF (auxiliary)", "TIFF output (auxiliary)")))
ek_cikar("yazilim", yazilim, "Software, versions and roles in the analysis.", orta = FALSE)
strobe <- c("# STROBE (kesitsel çalışmalar) notları",
  "",
  "Her madde için bu çalışmanın çıktılarında nerede karşılandığı. Makale metni yazarlarca yazılacaktır.",
  "",
  "Maddeler 1–3 (başlık, özet, giriş), 18 (ana sonuçların özeti), 20 (yorum) ve 22 (finansman) makale metninde yazarlarca yazılır; burada yer almaz.",
  "",
  "- 4 Tasarım: TÜİK GYKA 2023–2025 kesit mikro verileri, hane-yılı birimli havuzlanmış kesitsel analiz; rotasyonlu panel nedeniyle tekrar eden haneler bağlantı zincirleriyle modellendi (Rapor Bölüm 4).",
  "- 5 Ortam: alan uygulaması 2023 ve 2024'te Mart–Temmuz, 2025'te Şubat–Haziran; gelirler önceki takvim yılına ait (tarif Bölüm 2.1).",
  sprintf("- 6 Katılımcılar: reis ve FK240 ile karşılıklı-tekil bağlı eşi olan, iki eşi de 18+ ve en az biri 18–64 yaşında, iki eşin de bireysel kaydı olan, net kazançları negatif olmayan ve toplamı pozitif çiftler: %s hane-yılı; ortak destek örneklemi %s (Table S2, Figure 1a).", format(nrow(u), big.mark = ".", decimal.mark = ","), format(nrow(q), big.mark = ".", decimal.mark = ",")),
  "- 7 Değişkenler: sonuç HE090 (tek maddelik gıda yoksunluğu); maruziyet kazanan yapısı ve kadının payı; kovaryatlar ve türetilmiş değişkenler Table S1, `Results/degisken_tanimlari.csv`.",
  "- 8 Veri kaynakları ve ölçüm: tarif ve inceleme raporu; HE090 hane anketinden, yanıtlayan kişi veride yok.",
  "- 9 Yanlılık: ortak destek (Table S7, Figure S1), bağlantı kuralları ve ağırlık duyarlılıkları ({duy_B} ve {duy_AC}), eksik veri (Table S6).",
  sprintf("- 10 Örneklem büyüklüğü: önceden belirlenmiş fizibilite kuralları (köşe ≥ 200 hane, ≥ 50 olay ve olay olmayan; çapa ≥ 200 hane); 0,85–0,95 çapasında %d hane, kural sağlanmadı (Rapor Bölüm 5).", q[G == "D" & s >= 0.85 & s <= 0.95, .N]),
  "- 11 Nicel değişkenler: gelirler yıl medyanına oran ve asinh dönüşümüyle; spline düğümleri `Results/spline_dugumleri.json`.",
  "- 12a İstatistik yöntemler: ağırlıklı Bayesçi lojistik model (brms/Stan), İBBS-2 ve bağlantı zinciri düzeyleri, Gauss–Hermite marjinalleştirmeli standartlaştırma, ROPE ±2 puan (Rapor Bölüm 9).",
  "- 12b Alt gruplar ve etkileşimler: yalnız kadının kazandığı çiftlerde kocanın gelir yılındaki durumu ({koca}, Figure 3a); her durum kendi çiftleri üzerinden standartlaştırıldı, durumlar arasında karşıtlık hesaplanmadı. Yıla özgü sapmalar ({yil}, Figure S4).",
  paste0("- 12c Eksik veri: model değişkenlerinde uygun örneklemde eksik yok; tam vaka. Kayıtsız eşli ", nrow(kayitsiz), " çift dışlandı ve karşılaştırıldı (Table S6)."),
  "- 12d Örnekleme stratejisi: HB040 ağırlıkları olabilirlikte (pseudo-posterior); tabaka ve PSU yayımlanmıyor; survey modeli zincir kümeli bootstrap ile ({duy_B}).",
  "- 12e Duyarlılık analizleri: örneklem, dönem, tahmin yaklaşımı ve tanım varyantları; sonuç sonrası eklenenler işaretli ({duy_B} ve {duy_AC}, Figure 3b ve S5).",
  "- 13 Katılımcı akışı: Figure 1a ve Table S2. Anketin görüşme tamamlama oranı (görüşülen / ziyaret edilen hane) 2023'te %89,6, 2024'te %94,6, 2025'te %94,0 (inceleme raporu Tablo 1 notu).",
  "- 14 Tanımlayıcı veriler: Table 1 (Q), {ozellik} ve {ozellik_dis} (bütün uygun ve Q dışı).",
  "- 15 Sonuç verileri: Table S3 (yıl ve kazanan yapısına göre olay sayıları).",
  "- 16 Ana sonuçlar: ham (ayarlanmamış) tahminler Table 1'deki ağırlıklı yaygınlıklardır. Ayarlanmış tahminler Table 2 ve Figure 2'de: M1 (gelir terimlerinden önce; ham değildir) ve M2.",
  "- 17 Diğer analizler: Figure 3; {duy_B}, {duy_AC}, {E_ek}, {katsayi}, {koca} ve {yil}; Figure S4–S5.",
  "- 19 Sınırlılıklar: tek maddelik sonuç; gelir yılı ile görüşme anının farklı olması; eşlerin gelir yılı boyunca birlikte yaşadığının doğrulanamaması; tabaka ve PSU bilgisinin olmaması; bağlantının resmî anahtara dayanmaması; ortak desteğin örneklemin yarısını dışlaması; 0,9 çapasının verinin dışında kalması ve E1, E2, E3a ile E3a,k'nın pay spline'ının dış değerine ve prior'ına bağlı olması (C20, C21); zincir içi aynı sonucun model tarafından eksik üretilmesi; sonuç sonrası eklenen analizler (tablolarda ^p); kocanın durumunda dört kategoriden yalnız birinde aralığın sıfırı dışlaması (çoklu karşılaştırma) (Rapor Bölüm 12).",
  paste("- 21 Genellenebilirlik: ana tahminler ortak destek örneklemine (Q) aittir; Q, uygun örneklemden daha yaşlı, daha az küçük çocuklu ve doğu bölgelerinden az haneli bir nüfustur ({ozellik} ve {ozellik_dis}, Rapor Aşama 0c ve Bölüm 12). Bütün uygun hanelerle (A9) E3b ve E4 en çok", sub(".", ",", f1(max(abs(duy_tum[kod == "A9_tum_uygun" & buyukluk %in% c("E3b", "E4"), fark_ana]))), fixed = TRUE), "puan değişiyor; E2 ve E3a maddi ölçüte göre değişiyor ({duy_AC}), aralıkları sıfırı kapsıyor."))
if (!yalniz_ek1) writeLines(ek_yaz(strobe), "Results/strobe_akis.md")
xl_dosya <- if (yalniz_ek1) "Results/tablolar_ek1.xlsx" else "Results/tablolar_tumu.xlsx"
sayfa_ad <- names(wb)
sayfa_anahtar <- vapply(sayfa_ad, function(a) if (grepl("^Table[0-9]+$", a)) as.numeric(sub("Table", "", a)) else 2 + as.numeric(sub("^TableS([0-9]+).*$", "\\1", a)) + if (grepl("b$", a)) 0.5 else 0, 0)
worksheetOrder(wb) <- order(sayfa_anahtar)
saveWorkbook(wb, xl_dosya, overwrite = TRUE)
cat(system2(py, c("Codes/xlsx_simge.py", shQuote(xl_dosya)), stdout = TRUE, stderr = TRUE), sep = "\n")
fwrite(rbindlist(dogr), "Results/dogrulama_kontrolleri.csv")
fwrite(protokol, "Results/model_protokolu.csv")
sure_ekle("sayilar.json ve teslim dosyaları", t0)
fwrite(rbindlist(sureler), "Results/log/analiz_sureleri.csv")
cat("analiz.R bitti:", format(Sys.time()), "; toplam", round(as.numeric(difftime(Sys.time(), baslangic, units = "mins")), 1), "dk\n")
plan(sequential)
sink()
