USE cuzdanim_db;

INSERT IGNORE INTO users (id, name, email, password)
VALUES (1, 'Demo Kullanıcı', 'demo@cuzdanim.app', 'demo123');

INSERT INTO budgets (user_id, category, amount, month)
VALUES
  (1, 'Market', 4500.00, '2026-06-01'),
  (1, 'Ulaşım', 1800.00, '2026-06-01'),
  (1, 'Sosyal', 2500.00, '2026-06-01')
ON DUPLICATE KEY UPDATE amount = VALUES(amount);

INSERT INTO transactions (user_id, amount, type, category, description, date)
VALUES
  (1, 42000.00, 'income', 'Maaş', 'Haziran maaşı', '2026-06-01'),
  (1, 3500.00, 'income', 'Ek Gelir', 'Freelance proje', '2026-06-06'),
  (1, 900.00, 'income', 'Diğer', 'Ürün iadesi', '2026-06-14'),
  (1, 6800.00, 'expense', 'Fatura', 'Kira ve apartman gideri', '2026-06-02'),
  (1, 1250.00, 'expense', 'Fatura', 'Elektrik ve su faturası', '2026-06-05'),
  (1, 1450.00, 'expense', 'Yemek', 'Market alışverişi', '2026-06-04'),
  (1, 780.00, 'expense', 'Yemek', 'Dışarıda yemek', '2026-06-09'),
  (1, 620.00, 'expense', 'Ulaşım', 'Toplu taşıma ve taksi', '2026-06-08'),
  (1, 980.00, 'expense', 'Sağlık', 'Eczane alışverişi', '2026-06-10'),
  (1, 2400.00, 'expense', 'Alışveriş', 'Kıyafet alışverişi', '2026-06-12'),
  (1, 450.00, 'expense', 'Eğitim', 'Kitap alışverişi', '2026-06-16'),
  (1, 320.00, 'expense', 'Diğer', 'Kafe ve küçük harcamalar', '2026-06-18'),
  (1, 42000.00, 'income', 'Maaş', 'Mayıs maaşı', '2026-05-01'),
  (1, 1200.00, 'income', 'Diğer', 'İade ödemesi', '2026-05-18'),
  (1, 2800.00, 'income', 'Ek Gelir', 'Danışmanlık ödemesi', '2026-05-24'),
  (1, 6700.00, 'expense', 'Fatura', 'Kira ve faturalar', '2026-05-03'),
  (1, 1880.00, 'expense', 'Yemek', 'Restoran ve market', '2026-05-09'),
  (1, 750.00, 'expense', 'Eğitim', 'Online kurs', '2026-05-14'),
  (1, 910.00, 'expense', 'Ulaşım', 'Aylık ulaşım', '2026-05-20'),
  (1, 1650.00, 'expense', 'Alışveriş', 'Ev tekstili', '2026-05-22'),
  (1, 640.00, 'expense', 'Sağlık', 'Doktor kontrolü', '2026-05-27'),
  (1, 380.00, 'expense', 'Diğer', 'Abonelik yenileme', '2026-05-29'),
  (1, 42000.00, 'income', 'Maaş', 'Nisan maaşı', '2026-04-01'),
  (1, 3000.00, 'income', 'Burs', 'Eğitim bursu', '2026-04-05'),
  (1, 6600.00, 'expense', 'Fatura', 'Kira ve elektrik', '2026-04-02'),
  (1, 1320.00, 'expense', 'Yemek', 'Market alışverişi', '2026-04-07'),
  (1, 2100.00, 'expense', 'Alışveriş', 'Ev ihtiyaçları', '2026-04-16'),
  (1, 540.00, 'expense', 'Diğer', 'Küçük harcamalar', '2026-04-22'),
  (1, 870.00, 'expense', 'Ulaşım', 'Yakıt ve otopark', '2026-04-24'),
  (1, 490.00, 'expense', 'Sağlık', 'Vitamin ve ilaç', '2026-04-26'),
  (1, 42000.00, 'income', 'Maaş', 'Mart maaşı', '2026-03-01'),
  (1, 1800.00, 'income', 'Ek Gelir', 'Hafta sonu işi', '2026-03-11'),
  (1, 6400.00, 'expense', 'Fatura', 'Kira ve doğalgaz', '2026-03-02'),
  (1, 1560.00, 'expense', 'Yemek', 'Market alışverişi', '2026-03-06'),
  (1, 720.00, 'expense', 'Ulaşım', 'Aylık ulaşım kartı', '2026-03-10'),
  (1, 2300.00, 'expense', 'Alışveriş', 'Telefon aksesuarları', '2026-03-17'),
  (1, 600.00, 'expense', 'Eğitim', 'Atölye katılımı', '2026-03-21'),
  (1, 410.00, 'expense', 'Diğer', 'Kargo ve küçük ödemeler', '2026-03-25'),
  (1, 42000.00, 'income', 'Maaş', 'Şubat maaşı', '2026-02-01'),
  (1, 2500.00, 'income', 'Burs', 'Dönem bursu', '2026-02-04'),
  (1, 6300.00, 'expense', 'Fatura', 'Kira ve internet', '2026-02-02'),
  (1, 1480.00, 'expense', 'Yemek', 'Market alışverişi', '2026-02-07'),
  (1, 690.00, 'expense', 'Ulaşım', 'Taksi ve metro', '2026-02-12'),
  (1, 1150.00, 'expense', 'Sağlık', 'Diş muayenesi', '2026-02-15'),
  (1, 1750.00, 'expense', 'Alışveriş', 'Kışlık ihtiyaçlar', '2026-02-19'),
  (1, 520.00, 'expense', 'Diğer', 'Hediye ve küçük harcamalar', '2026-02-23'),
  (1, 40000.00, 'income', 'Maaş', 'Ocak maaşı', '2026-01-01'),
  (1, 1600.00, 'income', 'Ek Gelir', 'Ek ders ödemesi', '2026-01-13'),
  (1, 6200.00, 'expense', 'Fatura', 'Kira ve faturalar', '2026-01-03'),
  (1, 1390.00, 'expense', 'Yemek', 'Market alışverişi', '2026-01-08'),
  (1, 760.00, 'expense', 'Ulaşım', 'Aylık ulaşım', '2026-01-12'),
  (1, 980.00, 'expense', 'Eğitim', 'Kitap ve defter', '2026-01-18'),
  (1, 2100.00, 'expense', 'Alışveriş', 'Ev düzenleme ürünleri', '2026-01-21'),
  (1, 350.00, 'expense', 'Diğer', 'Küçük harcamalar', '2026-01-26');
