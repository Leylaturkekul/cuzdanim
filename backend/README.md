# Cüzdanım API

Flutter uygulamasının kullanıcı, işlem ve bütçe verilerini yöneten REST servisi.

## Kurulum

1. Proje kökündeki `db/schema.sql` dosyasını MySQL üzerinde çalıştır.
2. İstersen `db/seed_demo.sql` ile demo verilerini ekle.
3. `.env.example` içindeki değerleri çalışma ortamına tanımla.
4. `npm start` komutuyla servisi başlat.

Varsayılan adres `http://127.0.0.1:3000` olur. Android emülatöründeki Flutter uygulaması bu servise otomatik olarak `10.0.2.2` üzerinden bağlanır.

Demo hesabı: `demo@cuzdanim.app` / `demo123`
