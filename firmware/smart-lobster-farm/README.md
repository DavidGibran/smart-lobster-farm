# Smart Lobster Farming Firmware

Firmware ESP32 untuk membaca prototype sensor kualitas air, menampilkan kondisi
lokal, menjalankan alarm non-blocking, dan mempertahankan pengiriman data ke
Firebase pada schema yang sudah ada.

## Pin mapping

| Komponen | Pin ESP32 | Fungsi |
| --- | --- | --- |
| Potentiometer pH | GPIO34 | ADC1, simulasi pH 6-9 |
| Potentiometer TDS | GPIO35 | ADC1, simulasi 200-600 ppm |
| DS18B20 | GPIO4 | Sensor suhu OneWire; data memakai pull-up 4.7 kOhm |
| SSD1306 SDA | GPIO21 | I2C data |
| SSD1306 SCL | GPIO22 | I2C clock |
| LED | GPIO18 | Indikator status sistem, seri dengan resistor 220 Ohm |
| Buzzer | GPIO19 | Alarm lokal 2 kHz |

Seluruh ground terhubung bersama. Pada `diagram.json`, merah digunakan untuk
VCC, hitam untuk ground, dan hijau untuk signal/GPIO.

## Display dan alarm lokal

SSD1306 I2C 128x64 menampilkan pH, TDS, suhu, status setiap sensor, dan status
sistem. Nilai yang gagal dibaca ditampilkan sebagai `ERR`, bukan angka palsu.
Status sistem selalu mengambil severity terburuk dengan urutan
`WARNING > CAUTION > NORMAL`.

- `NORMAL`: LED dan buzzer mati.
- `CAUTION`: LED menyala 500 ms lalu mati 1500 ms. Buzzer berbunyi 100 ms
  setiap 25 detik.
- `WARNING`: LED berganti 250 ms nyala/250 ms mati. Buzzer berbunyi dua kali
  (200 ms nyala, 200 ms mati, 200 ms nyala), lalu jeda hingga siklus 5 detik.

Semua pola memakai `millis()` tanpa `delay()`. WARNING aktif segera, sedangkan
perubahan menuju CAUTION atau NORMAL perlu dua pembacaan berturut-turut untuk
mengurangi status chatter di sekitar batas.

## Threshold

Threshold berada terpusat di `include/water_status.h` dan disamakan dengan
logic aplikasi mobile existing:

| Sensor | NORMAL | CAUTION | WARNING |
| --- | --- | --- | --- |
| pH | 7.0-8.0 | 6.5 hingga <7.0, atau >8.0 hingga 9.0 | <6.5, >9.0, atau invalid |
| TDS | 320-400 ppm | Di luar 320-400 ppm | Pembacaan invalid |
| Suhu | 26-29 C | >29 hingga 32 C | <26, >32, disconnected, atau invalid |

Rentang TDS 320-400 ppm adalah **reference range baseline proyek**, bukan
optimum biologis universal. Semua threshold ini merupakan operational
monitoring threshold prototype dan harus ditinjau kembali setelah kalibrasi
sensor lapangan.

## Interval dan Firebase

- Sensor dibaca setiap 10 detik.
- `latest` dikirim setiap 30 detik.
- `history_raw` diagregasi setiap 5 menit.
- `history_hourly` tetap dibentuk dari agregat lima-menit existing.

Path, schema, dan payload Firebase tidak diubah. Jika satu sensor invalid,
reading tersebut tidak dimasukkan ke agregasi dan tidak dikirim ke Firebase.

## Menjalankan PlatformIO

Dari root monorepo:

```powershell
pio run --project-dir .\firmware\smart-lobster-farm
```

Atau masuk ke folder firmware:

```powershell
cd .\firmware\smart-lobster-farm
pio run
```

## Menjalankan Wokwi

1. Build firmware dengan `pio run`.
2. Buka folder `firmware/smart-lobster-farm` di VS Code.
3. Jalankan perintah **Wokwi: Start Simulator** dari Command Palette.
4. Ubah kedua potentiometer dan atribut suhu DS18B20 untuk menguji transisi
   NORMAL, CAUTION, WARNING, serta kombinasi status.

`wokwi.toml` menunjuk ke firmware dan ELF hasil build pada environment
`esp32dev`.
