# Cüzdanım

Gelir, gider ve aylık bütçe takibini kolaylaştıran; Android, iOS, web ve masaüstünde çalışabilen Flutter uygulaması.

## Tamamlanan özellikler

- E-posta ile kayıt ve giriş
- Sunucu olmadan kullanılabilen hızlı demo modu
- Çevrimdışı veri saklama ve bağlantı gelince otomatik eşitleme
- Aylık gelir, gider ve kalan para özeti
- Kategori bazlı harcama grafiği
- İşlem ekleme, düzenleme, arama, filtreleme ve kaydırarak silme
- Kategori bazlı aylık bütçe oluşturma ve limit uyarısı
- Ay seçimi ve son 18 aya kolay erişim
- Açık, koyu ve cihaz teması
- İşlem dökümünü CSV biçiminde kopyalama
- Telefon, tablet ve web için uyumlu arayüz

## Hızlı çalıştırma

Flutter uygulaması:

```bash
flutter pub get
flutter run
```

Uygulama açıldığında **Demo ile hemen başla** seçeneği hiçbir ek kurulum olmadan çalışır.

## Sunucu bağlantısı

Kalıcı kullanıcı hesabı ve cihazlar arası veri için önce MySQL şemasını kur:

```bash
mysql -u root < db/schema.sql
mysql -u root < db/seed_demo.sql
```

Ardından backend klasöründe servisi başlat:

```bash
cd backend
npm install
npm start
```

Varsayılan API adresi masaüstü, iOS ve web için `http://127.0.0.1:3000`; Android emülatörü için otomatik olarak `http://10.0.2.2:3000` olur.

Demo sunucu hesabı: `demo@cuzdanim.app` / `demo123`

## Doğrulama

```bash
flutter analyze
flutter test
flutter build web --release
```
