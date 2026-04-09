# CHANGELOG v0.1.2

Bu dosya, v0.1.2 ve sonrasi icin degisiklik kayitlarinin aktif kaynagidir.

## Logging Rules
- Timestamp formati: `YYYY-MM-DD HH:mm:ss +/-TZ`
- Satir formati: `Cause -> Change -> Result`

## Entries

## 2026-04-09 01:13:19 +03:00
Cause -> Destroy ekraninda Destroy Next butonuna hizli cift tiklandiginda ayni slot icin ikinci use denemesi tetiklenebiliyor ve beklenmeyen "you must be level 90 to use this item" hatasi gorulebiliyordu -> Change -> destroy_ui.lua icinde Destroy Next butonuna kisa sureli tek-atim click lock eklendi, ilk tik sonrasi gecici disable uygulandi ve tetikleme yalnizca LeftButtonUp ile sinirlandi -> Result -> Hızlı cift tikta ikinci makro tetigi engellendi; itemin yanlislikla use edilmeye calisilmasi onlendi ve Destroy akisi daha guvenli hale geldi

## 2026-04-09 01:16:29 +03:00
Cause -> Destroy pipeline sadece Disenchant ve Milling ile sinirliydi; Jewelcrafting icin Prospecting destegi isteniyordu -> Change -> destroy_scan.lua icinde Prospecting (spellID: 31252) ve MetalAndStone subclass tabanli aday tespiti eklendi, ready kontrolu 5 adet min-quantity ile genisletildi; destroy_ui.lua bilgi satiri Prospecting gorunurlugu ile guncellendi -> Result -> Destroy ekrani artik Disenchant/Milling yaninda JC Prospecting adaylarini da tespit edip guvenli tek-adim akista sunuyor

## 2026-04-09 01:24:17 +03:00
Cause -> Destroy ekranindaki spell durum metni tek satirda uzun kaldigi icin okunurluk zayifladi -> Change -> destroy_ui.lua icinde spell bilgi formati minor UI duzenlemesiyle kisaltilip alt alta 3 satira alindi (DE/Mill/Prospect) ve sadece Yes/No durum gosterimi korundu -> Result -> Destroy basligina dokunmadan spell durum alani daha kompakt ve hizli okunur hale geldi

## 2026-04-10 00:24:10 +03:00
Cause -> Inbox mail detail penceresinde body metni gorunmuyordu (detail body child genisligi 1px kalabiliyordu) -> Change -> ui.lua icinde detail body layout senkronizasyonu eklendi (child width/height sync + size change hooklari) ve detail body text icin guvenli acik renk fallback tanimlandi -> Result -> Fixed: Inbox satirina tiklandiginda acilan kucuk pencerede mail yazisi gorunur ve okunur hale geldi

## 2026-04-10 00:27:12 +03:00
Cause -> Destroy ekranindaki DE/Mill/Prospect bilgi metinleri kullanisiz ve gereksiz gorunuyordu -> Change -> destroy_ui.lua icinde sadece UI bilgi metni kaldirildi (top info text bos birakildi), destroy scan/spell/macro akisi degistirilmedi -> Result -> Destroy panel daha sade hale geldi; calisma prensibi korunarak yalnizca gorsel yazi temizlendi
