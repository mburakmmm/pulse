# Pulse — Sürümlü Uygulama Planı

> Bu dosya `AGENTS.md` uygulama sözleşmesinin yürütülebilir iş listesidir.
> Kaynak dosyanın yerine geçmez; çelişki halinde `AGENTS.md` geçerlidir.
>
> Başlangıç tarihi: 2026-11-07  
> Genel durum: Deneysel geliştirme  
> Son tamamlanan sürüm: `v0.1.0` — yerel faz kapısı 2026-11-12'de geçti  
> Aktif sürüm: `v0.2.0` — bounded cumulative metrics core

## 1. Takip kuralları

### Durum işaretleri

- `[ ]` Başlanmadı.
- `[~]` Devam ediyor. Bu işaret kullanıldığında aynı satıra kısa durum ve engel yazılır.
- `[x]` Kanıtla tamamlandı.
- `[-]` Kapsam dışı veya ertelendi. Gerekçe ve hedef sürüm zorunludur.
- `[!]` Engel var. Engel, denenen komut ve gereken karar yazılmadan bırakılmaz.

### Bir işin tamamlanma şartı

Bir madde yalnızca kaynak dosyası oluşturulduğu için `[x]` yapılamaz. İlgili olduğu ölçüde aşağıdakilerin tümü sağlanmalıdır:

1. Açık ve tipli kamu sözleşmesi belgelenmiş olmalı.
2. Sabitlenmiş NOX derleyicisiyle derlenmeli ve type-check geçmeli.
3. Başarı, hata ve sınır davranışı testleri geçmeli.
4. Gizlilik ve kaynak sınırları uygulanmış olmalı.
5. Eşzamanlılık, iptal, flush ve shutdown davranışı test edilmiş olmalı.
6. Protokol/exporter iddiası bağımsız araç veya gerçek servisle doğrulanmalı.
7. QBE/LLVM ve platform sonucu doğru biçimde `PASS`, `FAIL`, `SKIPPED` veya `UNSUPPORTED` yazılmalı.
8. Dokümantasyon, örnek, standart matrisi ve changelog güncellenmiş olmalı.
9. Bilinen eksik veya placeholder gizlenmemeli.

### Sürüm kapısı

- Bir sürümün bütün zorunlu maddeleri ve çıkış kapısı tamamlanmadan sonraki sürümün üretim koduna geçilmez.
- Sonraki faz için araştırma/spike yapılabilir; fakat deneysel sonuç kamu API'si veya destek iddiası sayılmaz.
- Her sürüm sonunda bu dosyadaki kanıt kaydı doldurulur.
- Yeni bulunan her NOX kusuru veya capability sınırı, workaround uygulanmadan önce `docs/nox-limitations.md` kaydına eklenir; workaround upstream kaydı kapatmaz.
- `v1.0.0` öncesi API'ler kararsızdır. Yine de her kırıcı değişiklik `CHANGELOG.md` içinde açıkça belirtilir.
- Yayınlanmış tag veya artefakt değiştirilmez; düzeltme yeni patch sürümü olur.
- Kırmızı CI, zayıflatılmış test, sahte benchmark veya çalıştırılmamış testi `PASS` saymak sürüm engelidir.

## 2. Başlangıç fotoğrafı

### Doğrulananlar

- [x] Depodaki 1.031 satırlık `AGENTS.md` bütünüyle okundu ve ana sözleşme olarak kabul edildi.
- [x] Depo envanteri çıkarıldı: başlangıçta yalnızca `AGENTS.md` bulunuyordu.
- [x] Çalışma dizininin henüz bir Git deposu olmadığı doğrulandı.
- [x] Sistem derleyicisi değiştirilmeden bırakıldı (`noxc 2.1.52`); yayınlanmış `2.1.64` resmî arşivi izole geçici dizinde denetlendi.
- [x] Yerel platform kaydedildi: macOS ARM64.
- [x] Upstream NOX deposu ve güncel `main` adayı incelendi.
- [x] Yayınlanmış upstream SHA kaydedildi: `be3458c332c8234baa8f3f8ac2ae9601db24321e` (`v2.1.64`).
- [x] Upstream kaynakta `nox.time.instant_now()`, `Instant.elapsed_ms()`, `nox.time.now_ms()` ve `nox.http.request(...)` yüzeyleri görüldü.

### Henüz tamamlanmayan denetimler

- [x] Upstream SHA `be3458c332c8234baa8f3f8ac2ae9601db24321e`, Pulse baseline kaynağı olarak seçildi; exact-tag changelog incelendi ve QBE/LLVM smoke/Phase 1 testleri geçti.
- [x] İzole `noxc 2.1.64` ikilisi `noxc version --build-info` ile exact source commit'e eşlendi; archive ve binary SHA-256 kaydedildi.
- [x] Aynı 10 smoke dosyası QBE ve LLVM için check/test/build/run adımlarıyla geçti.
- [x] `spawn`, kanal, cancellation, atomik, açık thread, `TaskLocal` fiber izolasyonu ve QBE/LLVM transfer farkları runtime/compile matrisiyle doğrulandı.
- [x] `str`, `nox.bytes` ve loopback HTTP POST/response NUL/high-byte ikili veriyi iki backend'de koruyor; gerçek OTLP protobuf conformance Faz 7'de ayrı kapı.
- [x] TLS reddi, redirect, response header, gzip ve HTTP durum/hata yüzeyleri iki backend'de doğrulandı; trusted-chain/hostname matrisi ayrı açık iş.
- [x] OpenTelemetry, OTLP, W3C Trace Context, W3C Baggage ve Prometheus text sürümleri `docs/standards-matrix.md` içinde sabitlendi; OpenMetrics ertelendi.

### Kaynaklar

- NOX upstream: <https://github.com/mburakmmm/nox-lang>
- İncelenen yayın commit'i: <https://github.com/mburakmmm/nox-lang/commit/be3458c332c8234baa8f3f8ac2ae9601db24321e>
- OpenTelemetry specifications: <https://github.com/open-telemetry/opentelemetry-specification>
- OTLP protocol: <https://github.com/open-telemetry/opentelemetry-proto>
- W3C Trace Context: <https://www.w3.org/TR/trace-context/>
- W3C Baggage: <https://www.w3.org/TR/baggage/>

## 3. Değişmez mimari kararlar

- [x] Kamu API'si tipli NOX olacak; Python davranışları varsayılmayacak.
- [x] `pulse/core` hiçbir framework veya exporter sağlayıcısına bağımlı olmayacak.
- [x] API ile SDK/uygulama katmanı ayrılacak; güvenli no-op sağlayıcılar bulunacak.
- [x] Temel context modeli açıkça taşınan, değişmez `TelemetryContext` olacak.
- [x] Kanıtlanmış task-local desteği olmadan global `current_span` yapılmayacak.
- [x] Süre ölçümü monotonik saatle, OTLP olay zamanı duvar saatiyle yapılacak.
- [x] OTLP desteği ancak gerçek protobuf ve gerçek Collector uyumluluğuyla ilan edilecek.
- [x] Prometheus exporter OTLP'nin bir görünümü değil, bağımsız birinci sınıf reader/exporter olacak.
- [x] Obsidian loglamanın sahibi olmaya devam edecek; Pulse yalnızca küçük ve opsiyonel correlation snapshot'ı verecek.
- [x] Kuyruk, cardinality, attribute, payload, retry ve shutdown süreleri her zaman sonlu olacak.
- [x] Hassas veri enqueue edilmeden önce elenecek veya redakte edilecek.
- [x] QBE cooperative ve LLVM multi-worker farkları ayrı ayrı test edilmeden thread-safe iddiası yapılmayacak.
- [x] NOX private ABI'si ve `__nox_*` sembolleri kullanılmayacak.

## 4. Sürüm haritası

| Sürüm | AGENTS fazı | Sonuç | Üst seviye kapı |
|---|---:|---|---|
| `v0.0.1` | 0 | Depo, compiler ve standart temeli | QBE + LLVM smoke |
| `v0.1.0` | 1 | Ortak veri modeli ve no-op API | Deterministik primitive testleri |
| `v0.2.0` | 2 | Metrics core | Matematik, cardinality, concurrency |
| `v0.3.0` | 3 | Prometheus MVP | Dış parser + gerçek scrape |
| `v0.4.0` | 4 | Tracing core | Span lifecycle ve hierarchy |
| `v0.5.0` | 5 | W3C propagation | Resmî fixture + isolation |
| `v0.6.0` | 6 | Sampling ve processors | Bounded queue + doğru shutdown |
| `v0.7.0` | 7 | OTLP mapping/protobuf | Bağımsız decoder |
| `v0.8.0` | 8 | OTLP/HTTP traces + metrics | Gerçek Collector |
| `v0.9.0` | 9 | Gelişmiş metrics | Reader/temporality bağımsızlığı |
| `v0.10.0` | 10 | Obsidian bridge | Opsiyonellik + döngüsüzlük |
| `v0.11.0` | 11 | Ekosistem adapter'ları | Gerçek multi-hop trace |
| `v0.12.0` | 12 | Güvenilirlik ve performans | Stress, leak, ölçülmüş bütçeler |
| `v0.13.0` | 13 | Release candidate | Tam conformance ve platform CI |
| `v1.0.0` | Final | Stabil kamu sözleşmesi | Tüm iddialar kanıtlı, P0/P1 yok |

Milestone'lar:

- `v0.3.0`: **MVP A** — Prometheus tarzı gerçek metrics.
- `v0.6.0`: **MVP B** — tracing, propagation, sampling ve bounded processing.
- `v0.10.0`: **OpenTelemetry beta** — gerçek OTLP traces/metrics ve Obsidian correlation.
- `v0.13.0`: **Stable candidate**.

## 5. Sürümlü iş listesi

### `v0.0.1` — Faz 0: depo, derleyici ve standart denetimi

Amaç: Hiçbir kamu API'si tasarlamadan önce gerçek NOX yeteneklerini ve protokol sürümlerini kanıtlamak.

Bağımlılık: Yok.  
Durum: Yerel faz kapısı geçti; uzak platform CI kanıtları sürüm öncesi izleniyor.

#### Depo ve paket temeli

- [x] Git deposunu güvenli biçimde `main` branch'iyle başlat. Remote henüz yapılandırılmadı.
- [x] Gerçek NOX paket kurallarına göre `nox.json` üret; varsayılan scaffold geçici dizinde incelendi.
- [x] `nox.lock` üretim ve tekrar üretilebilirlik davranışını doğrula: boş dependency listesi lock üretmiyor; downstream probe exact SHA'yı doğruluyor.
- [x] Profesyonel capability matrisi, quick start, mimari, doğrulama ve roadmap içeren `README.md`; `CHANGELOG.md` ve `.gitignore` oluştur.
- [!] `LICENSE` oluştur; lisans sahibi ve yeniden dağıtım kararı bekleniyor, varsayım yapılmadı.
- [x] Önerilen dizinleri yalnızca ihtiyaç oldukça oluştur; boş mimari klasörleri özellik kanıtı sayma.
- [x] `CONTRIBUTING.md`, `SECURITY.md`, `SUPPORT.md`, `CODE_OF_CONDUCT.md`, CODEOWNERS, PR/issue şablonları ve Dependabot yapılandırmasını ekle.
- [x] Kamu `api` ile SDK/internal katmanının kök modül yerleşimini ADR-0001 ile kararlaştır.
- [x] Framework adapter'larının leaf package olmasını ve `api/core` ters bağımlılıklarını `scripts/check-import-boundaries.sh` CI kapısıyla güvenceye al.

#### NOX capability audit

- [x] Pulse baseline'ı yayınlanmış NOX `2.1.64` ve kaynak SHA `be3458c332c8234baa8f3f8ac2ae9601db24321e` olarak yükseltildi; sistem kurulumu değişmedi.
- [x] Derleyici binary/release/SHA eşleşmesini kaydet: build-info exact commit'i doğruladı, yerel binary SHA-256 ayrıca kaydedildi.
- [x] `noxc check`, `build`, `run`, `test`, `fmt` komutlarını minimal örneklerle doğrula.
- [x] Aynı smoke paketini `--backend qbe` ve `--backend llvm` ile derle/çalıştır: backend başına 10 test geçti.
- [x] Paket import ve `__init__.nox` davranışını derlenen spike ile doğrula; root-module kararı ADR-0001'e işlendi.
- [x] Class, structural `protocol`, generic function/class, optional, generic enum ve exhaustive `match` sözdizimi doğrulandı; formatter generic tipleri koruyor.
- [x] `int` signed 64-bit wrap/minimum literal ve float Inf/NaN davranışı doğrulandı; NaN self-inequality QBE/LLVM parity regresyonu geçiyor.
- [x] `str` ikili taşıma, gömülü NUL, high byte, byte length, UTF-8 ve `nox.bytes` dönüşümleri doğrulandı; `char_from_byte(0)` artık tek NUL bayt üretiyor.
- [x] `dict` insertion order davranışı test edildi; canonical çıktılarda anahtarların açıkça sıralanması seçildi.
- [x] `nox.time.now_ns()` ve `monotonic_ns()` imza/nonnegative davranışını QBE/LLVM'de doğrula; hedefe göre gerçek çözünürlük sınırını kaydet.
- [x] `nox.crypto.secure_random_hex(n_bytes)` 16/8 byte uzunluk, all-zero reddi ve sıfır/negatif boyutta `CryptoError` davranışını QBE/LLVM'de doğrula.
- [x] `nox.http.request(...)` POST binary body, response binary, header, non-2xx, gzip, timeout ve unsupported-method davranışını QBE/LLVM loopback testiyle doğrula; GET body'nin sessizce atılması `NOX-HTTP-003` olarak kaydedildi.
- [~] Redirect/header ve self-signed TLS reddi iki backend'de doğrulandı; system-trusted başarı ve izole hostname-mismatch matrisi açık.
- [x] `nox.json.as_int`/`number_text` exact int64, `JsonWriter.write_int` fidelity ve quote/newline/NUL escaping davranışı doğrulandı.
- [x] `nox.fs` atomic replace, append/open_append, streaming binary read ve embedded-NUL davranışını QBE/LLVM'de doğrula; path'lerin sandbox/validation olmadan OS'ye iletildiğini kaydet.
- [x] `nox.os.getenv` missing-variable `OsError` davranışını iki backend'de doğrula.
- [x] `spawn`, `await`, `Task[T]`, bounded channel ve cancellation-at-await davranışını iki backend'de doğrula.
- [x] `TaskLocal[T]` fiber izolasyonu, clear, spawn/thread non-inheritance ve backend transfer semantiği doğrulandı; un-cleared değer sızıntısı upstream kayıtlı, explicit context kalıcı baseline.
- [x] `nox.thread.start`, retained join, scalar/atomic/`ThreadChannel` portable yolları ve LLVM-class/TaskLocal ile QBE compile-fail transfer farkları doğrulandı.
- [x] `AtomicInt`/`AtomicBool`, CAS, thread-handle paylaşımı ve tüm join'lerden sonra `free()` sırası iki backend'de doğrulandı.
- [x] Protobuf, gzip, UDP ve gRPC public yetenek matrisini çıkar: public protobuf wire codec, byte bridges, UDP ve gerçek h2c/TLS gRPC client mevcut; protokol conformance iddiaları kendi fazlarında gated.
- [x] Public NNI ile private runtime ABI sınırını mimari belgede kaydet; `__nox_*` ve doğrudan private `noxrt.o` bağını CI'da yasakla. Gelecek public NNI allowlist'i ayrı ADR gerektirir.
- [x] Pulse ile ilgili tüm bulunan NOX kusuru/design limit/capability gap için merkezi `docs/nox-limitations.md`, pazartesi triage sırası ve yeniden doğrulama kapıları oluştur.

#### Standart ve mimari belgeleri

- [x] `docs/compatibility.md`: exact build identity, backend/API smoke, kapatılan limitasyonlar ve kalan fallback matrisi güncellendi; uzak platform/protokol kanıtları ayrı açık işler.
- [x] `docs/standards-matrix.md`: exact OTel `v1.62.0`, OTLP proto `v1.11.1`, semantic conventions `v1.45.0`, W3C ve Prometheus sürümlerini seç.
- [ ] Pinned OTLP `.proto` dosyalarının vendored/generated kopyasını ve checksum manifestini üret.
- [x] `docs/architecture.md`: API/SDK/exporter/adapter katmanları ve dependency direction belgelendi.
- [x] ADR-0001: root-module yerleşimi, açık context ve task-local ekleme koşulları.
- [x] ADR-0003 tarihsel fallback kararı olarak korundu; enum desteği geldikten sonra storage şekli ADR-0006 ile supersede edildi.
- [x] ADR-0002: explicit ownership, join-before-free, synchronous baseline ve QBE cooperative fallback'i.
- [x] ADR-0006: NOX 2.1.64 generic enum/match ile typed telemetry value ve public `nox.protobuf` kullanım kararı; NNI gerekmiyor.
- [x] ADR-0005: count + owned-byte çift kapısı, drop-newest, cardinality/payload/retry/shutdown varsayılanları ve checked memory-budget hesabı.
- [x] `docs/security.md`: default-deny veri sınıfları, redaction sınırı ve threat model başlangıcı.

#### Test ve CI temeli

- [x] ADR-0004: deterministik test clock, sequence ID generator, scripted transport, bounded in-memory sink ve suite sınıflandırması.
- [ ] `tests/unit`, `golden`, `integration`, `conformance`, `concurrency`, `security`, `fuzz`, `benchmarks` koşum biçimini doğrula.
- [x] QBE ve LLVM smoke job'larını checksum-verified NOX release kurulumu ile workflow'a ekle.
- [x] macOS ARM64, Linux x64 ve Linux ARM64 workflow matrisini ekle; remote sonuç bekleniyor.
- [~] Windows x64 core workflow hedefi resmî zip/checksum kurulumu ve iki-backend suite ile eklendi; destek iddiası remote sonuç görülene kadar `PENDING`.
- [x] Downstream dependency alias/package smoke testi ve iki backend'de çalışan `examples/hello_metrics.nox` derleme/çıktı kapısı eklendi.
- [x] CI step summary ve platform belgesinde `SKIPPED`, `UNSUPPORTED` ve `PENDING` durumları başarıdan ayrıldı; OTLP/Prometheus interop çalıştırılmış gibi gösterilmiyor.
- [~] İlk GitHub yayını, repository metadata ve dört-platform remote CI kanıtı hazırlanıyor; remote sonuç henüz kaydedilmedi.

#### Çıkış kapısı

- [x] Sabitlenmiş SHA ile gerçek smoke programı QBE ve LLVM altında geçiyor (10/10).
- [x] Faz 1'de kullanılacak public stdlib yetenekleri için derlenen smoke testi var.
- [x] Eksik yetenekler ve fallback'ler `docs/compatibility.md` içinde açık.
- [x] Standart sürümleri ve protobuf schema kaynağı sabit; vendored schema/checksum Faz 7 teslimi olarak açık.
- [x] Minimal CI tanımı mevcut; yerelde iki backend yeşil, çalıştırılmayan uzak platformlar açıkça `pending/unsupported` işaretli.

### `v0.1.0` — Faz 1: ortak telemetry primitives

Amaç: Metrics ve tracing tarafından ortak kullanılan güvenli, değişmez ve sınırlı veri modelini kurmak.

Bağımlılık: `v0.0.1`.

- [x] `TelemetryError`, export/flush/shutdown sonuç tipleri ve hata sınıflandırması.
- [x] `AttributeValue`: bool, int, float, str ve izin verilen homojen array tipleri.
- [x] Attribute key/value/array/count/owned-byte limitleri; drop/reject politikası.
- [x] NaN/Inf ve geçersiz array davranışı.
- [x] Deterministik attribute sıralaması ve defensive array snapshot.
- [x] Hassas anahtar sınıflandırması ve record-boundary öncesi drop; adapter allowlist'leri ilgili adapter fazlarında ayrıca uygulanacak.
- [x] `Resource` ve deterministik merge: explicit > environment > safe defaults.
- [x] `InstrumentationScope`: name, version, schema URL, attributes.
- [x] Clock arayüzü: wall time ve monotonic duration ayrımı; hedefe özgü ns çözünürlük belgesi.
- [x] ID byte/text ayrımı; 16-byte trace, 8-byte span, lowercase hex, all-zero reddi.
- [x] Production secure ID generator ve yalnız testte deterministic generator.
- [x] Merkezi, doğrulanan ve sonlu limits/config tipleri: attribute, event/link/span, histogram boundary, metric cardinality/memory, queue/batch/payload/retry/shutdown.
- [x] Minimal API arayüzleri ile SDK implementation ayrımı: base contracts, no-op sağlayıcılar ve dürüst disabled SDK hazır; recording provider kendi fazında.
- [x] No-op Meter/Tracer provider: importta ağ, worker veya listener yok; kayıt yapmıyor ve parent context'i koruyor.
- [x] Disabled SDK lifecycle ve idempotent initialization/shutdown/flush.
- [x] Typed `PulseConfig` başlangıcı, bounded runtime limits ve redacted config summary.
- [x] Unit/property/golden/security testleri: iki-backend unit, seeded property, default-privacy suite ve canonical attribute golden fixture geçti.
- [x] `docs/api.md`, `docs/telemetry-data-model.md`, changelog güncellemesi.

Çıkış kapısı:

- [x] Integer fidelity, limits, mutation isolation, safe defaults, ID ve clock testleri iki backend'de geçiyor.
- [x] Disabled mode import/record/flush/shutdown yolunda ağ, worker veya listener üretmiyor.
- [x] Kamu API'sinde doğrulanmamış `Any` benzeri kaçış yok.

### `v0.2.0` — Faz 2: metrics core

Amaç: Gerçek ölçümlere dayanan, bounded-cardinality cumulative metrics motoru.

Bağımlılık: `v0.1.0`.

- [~] `MeterProvider`, `Meter`, instrument registry ve scope bağlama: single-owner recording yol tamam; lifecycle/reader/concurrent-safe provider açık.
- [x] Counter: public recording bağlantısı, cumulative bounded series, exact int64 total, overflow ve defensive snapshot iki backend'de geçti.
- [x] UpDownCounter: public recording bağlantısı, signed delta, bounded series ve overflow/underflow davranışı geçti.
- [x] Explicit-boundary Histogram: public recording bağlantısı, finite/strict boundaries, bounded series ve pre-aggregation geçti.
- [x] Exact-boundary kuralı lower bucket inclusive; count/sum/min/max/bucket tutarlılığı iki backend'de geçti.
- [x] Empty histogram min/max'ı açıkça omit ediyor; negatif finite ölçümler kabul, NaN/Inf reddediliyor.
- [x] Instrument name/unit/description doğrulaması: pinned OTel name ABNF, ASCII/63-byte unit ve configurable bounded opaque description.
- [x] Duplicate instrument/conflicting metadata politikası: identical descriptor reuse + first-seen casing; farklı kind/unit/description functional conflict ve diagnostic.
- [x] Attribute series canonical key: sıralı, type-tagged, length-delimited binary kimlik; scalar/array/NUL çakışma testleri geçti.
- [x] Allocation öncesi cardinality limiti: Counter/UpDown/Histogram instrument+provider series/byte kapıları aggregation allocation öncesinde.
- [x] Deterministik `otel.metric.overflow=true` series ve diagnostic counter: üç synchronous instrument storage'ında ölçüm drop/double-count yok.
- [x] Observation saklamak yerine bounded pre-aggregation: scalar ve explicit Histogram her series için yalnız aggregate state tutuyor.
- [ ] Cumulative reader snapshot ve tutarlı collection timestamps.
- [ ] In-memory metric exporter ve immutable deterministic snapshot.
- [ ] Console metric exporter; structured, sanitized, recursion-safe.
- [ ] 10 worker × 1.000 increment acceptance testi.
- [x] 100.000 benzersiz untrusted label / 1.000 metric-point hard-bound testi QBE ve LLVM'de geçti; toplam tam 100.000.
- [ ] QBE semantic ve LLVM real multi-worker testleri.
- [ ] API, limit, temporality ve thread-safety durum belgeleri.

Çıkış kapısı:

- [ ] Metrics matematiği ve histogram invariants property testleri geçiyor.
- [ ] Cardinality hiçbir yolda sınırsız allocation yapmıyor.
- [ ] Aynı counter series için LLVM multi-worker sonucu tam doğru.

### `v0.3.0` — Faz 3: Prometheus MVP

Amaç: Deterministik ve standart uyumlu pull/scrape metrics çıktısı.

Bağımlılık: `v0.2.0`.

- [ ] Desteklenen Prometheus text exposition sürümünü sabitle.
- [ ] `render_metrics()` saf snapshot renderer.
- [ ] Metric/label adları, label values ve HELP text escaping.
- [ ] Counter naming ve unit politikası.
- [ ] Histogram `_bucket`, `_sum`, `_count`, cumulative `le`, `+Inf`.
- [ ] `+Inf == total count` ve OTLP'ye hazırlık invariants.
- [ ] Resource attribute allowlist/target-info politikası.
- [ ] Stable deterministic output ve golden fixtures.
- [ ] Concurrent record sırasında internally consistent scrape snapshot.
- [ ] Render sırasında ağ I/O ve recursive telemetry olmadığını test et.
- [ ] Opsiyonel HTTP handler: loopback default veya explicit bind zorunluluğu.
- [ ] Scrape timeout ve inbound resource sınırları.
- [ ] Dış Prometheus/OpenMetrics parser doğrulaması.
- [ ] Gerçek endpoint scrape integration testi.
- [ ] `examples/hello_metrics.nox` derlenen örneği.
- [ ] Exporter support/security/docs/changelog güncellemesi.

Çıkış kapısı:

- [ ] Dış parser tüm golden çıktıları kabul ediyor.
- [ ] Gerçek scrape doğru metric type ve histogram değerlerini görüyor.
- [ ] Dinamik label saldırısı cardinality limitini aşmıyor.

### `v0.4.0` — Faz 4: tracing core

Amaç: Deterministik parent-child ilişkili ve doğru lifecycle'a sahip span modeli.

Bağımlılık: `v0.1.0`; metrics yalnız diagnostics için opsiyonel.

- [ ] `TracerProvider`, `Tracer`, `Span`, `SpanContext`, `TraceFlags`.
- [ ] `SpanKind`: INTERNAL, SERVER, CLIENT, PRODUCER, CONSUMER.
- [ ] Status semantiği ve pinned OTel uyumu.
- [ ] Span start/end wall timestamp ve monotonic nonnegative duration.
- [ ] Recording/non-recording span ayrımı.
- [ ] Explicit parent `TelemetryContext`; mutable global context yok.
- [ ] `end()` idempotent; en fazla bir export snapshot.
- [ ] End sonrası mutation exported snapshot'ı değiştirmiyor.
- [ ] Clock anomaly deterministik davranışı.
- [ ] Bounded attributes/events/links ve dropped counts.
- [ ] Event/link attribute defensive copy.
- [ ] Exception event privacy sanitizer; raw args/stack default yok.
- [ ] Resource ve scope doğru bağlanıyor.
- [ ] In-memory trace exporter ve simple deterministic assertions.
- [ ] Console trace exporter; sanitized ve recursion-safe.
- [ ] Early return/error/cancellation cleanup testleri.
- [ ] Parent ended olsa da context propagation geçerliliği.
- [ ] `examples/hello_traces.nox` derlenen örneği.

Çıkış kapısı:

- [ ] Hierarchy/lifecycle/double-end/clock tests iki backend'de geçiyor.
- [ ] Ended span hiçbir yoldan ikinci kez export edilmiyor.
- [ ] Default trace verisinde yasaklı hassas alan yok.

### `v0.5.0` — Faz 5: W3C context propagation

Amaç: Güvenilmeyen taşıyıcılarda standart uyumlu, bounded ve açık context propagation.

Bağımlılık: `v0.4.0`.

- [ ] Case-insensitive carrier interface; caller header spelling korunumu.
- [ ] `traceparent` strict parser ve lowercase formatter.
- [ ] Version, separator, length, hex, flags ve all-zero kontrolleri.
- [ ] Unknown version davranışı pinned W3C spec'e uygun.
- [ ] Remote/local context ve sampled flag korunumu.
- [ ] Inject overwrite politikası açık ve default-safe.
- [ ] Bounded, ordered ve validated `tracestate`.
- [ ] Baggage parse/format, percent encode/decode ve duplicate policy.
- [ ] Baggage key/value/entry/header limits.
- [ ] Trust boundary için baggage disable/sanitize politikası.
- [ ] Malformed/oversized headers fuzz ve security testleri.
- [ ] Resmî W3C fixtures ve parse(format(x)) property testi.
- [ ] İki eşzamanlı istekte context cross-contamination testi.
- [ ] İki NOX process arasında inject/extract testi (mümkünse).
- [ ] Task-local kolaylığı yalnız Faz 0 kanıtı ve tüm isolation testleri varsa eklenir.
- [ ] `examples/http_instrumentation.nox` explicit-context örneği.

Çıkış kapısı:

- [ ] W3C fixture/fuzz/property testleri geçiyor.
- [ ] İki concurrent request farklı trace ID'lerle tamamen izole.
- [ ] Baggage metrics label veya unrelated destination'a sızmıyor.

### `v0.6.0` — Faz 6: sampling ve span processors

Amaç: Deterministik sampling ve bounded, truthful flush/shutdown pipeline.

Bağımlılık: `v0.4.0`, `v0.5.0`.

- [ ] `DROP`, `RECORD_ONLY`, `RECORD_AND_SAMPLE` sözleşmesi.
- [ ] AlwaysOn ve AlwaysOff.
- [ ] TraceIdRatioBased: `[0,1]`, deterministic stable trace-ID mapping.
- [ ] ParentBased: local/remote sampled kararları.
- [ ] Non-recording span'ın geçerli propagation context'i.
- [ ] Simple processor exporter timeout ve safe diagnostics.
- [ ] Bounded batch queue ve açık ownership transferi.
- [ ] Queue capacity, max batch, scheduled delay, export/shutdown timeout.
- [ ] Default overflow politikası ve visible dropped count.
- [ ] Request hot path'te nonblocking veya strictly bounded enqueue.
- [ ] Export sırasında application lock tutulmadığı testi.
- [ ] Force-flush barrier: çağrıdan önce kabul edilen kayıtları kapsar.
- [ ] Shutdown: yeni kaydı reddet, deadline içinde drain/drop, worker join.
- [ ] Flush/shutdown idempotency.
- [ ] QBE cooperative/sync fallback; sahte paralellik yok.
- [ ] Retryable/permanent/partial error modelinin processor yüzeyi.
- [ ] Slow exporter, overflow, concurrent flush/record, shutdown race testleri.
- [ ] Worker cancellation ve freed-state erişimi stress testi.
- [ ] Diagnostics recursion testi.

Çıkış kapısı:

- [ ] Sampling 0%, 100% ve parent-based acceptance senaryoları geçiyor.
- [ ] Exporter outage request handling'i deadlock etmiyor ve bellek bounded.
- [ ] Shutdown sonrasında worker/shared-state erişimi yok; repeated shutdown güvenli.

### `v0.7.0` — Faz 7: OTLP model, mapping ve protobuf

Amaç: Resmî schema'ya göre gerçek OTLP protobuf bytes üretmek.

Bağımlılık: `v0.2.0`, `v0.4.0`, sabitlenmiş standards matrix.

- [ ] Pinned OTLP `.proto` schema kaynak ve checksum kaydı.
- [ ] Protobuf yaklaşımını capability audit'e göre uygula; custom lookalike schema yok.
- [ ] Wire types, field numbers, nested messages ve enums.
- [ ] `AnyValue` integer fidelity, arrays ve bytes.
- [ ] Trace/span ID raw bytes; text encoding yalnız boundary'de.
- [ ] ResourceSpans/ScopeSpans/Span mapping.
- [ ] Span events, links, status, flags, dropped counts ve timestamps.
- [ ] ResourceMetrics/ScopeMetrics/Metric/data-point mapping.
- [ ] Counter, UpDownCounter, Histogram ve cumulative temporality.
- [ ] Millisecond clock değerlerini ns'e çevirirken precision-limit belgesi.
- [ ] Unsupported signal/encoding config-time rejection.
- [ ] Resmî tooling ile bağımsız üretilmiş canonical fixtures.
- [ ] Bağımsız protobuf decoder ile wire conformance.
- [ ] Malformed/oversized payload ve integer/ID precision testleri.
- [ ] JSON mapping uygulanmayacaksa açıkça `unsupported`; protobuf iddiasından bağımsız.

Çıkış kapısı:

- [ ] Bağımsız decoder bütün trace ve metric golden bytes'ı doğru okuyor.
- [ ] 64-bit integer, timestamp ve ID kaybı yok.
- [ ] Fixture'lar pinned schema'dan izlenebilir biçimde üretilmiş.

### `v0.8.0` — Faz 8: OTLP/HTTP exporters

Amaç: Traces ve metrics'i gerçek Collector'a güvenli ve bounded HTTP üzerinden göndermek.

Bağımlılık: `v0.6.0`, `v0.7.0`.

- [ ] Transport abstraction ve injected fake transport.
- [ ] Base endpoint ile signal-specific endpoint precedence.
- [ ] `/v1/traces` ve `/v1/metrics` routing.
- [ ] `application/x-protobuf` real bytes.
- [ ] Header/auth config; diagnostics'te credential redaction.
- [ ] TLS verification default-on; insecure fallback yok.
- [ ] Per-request timeout, max payload ve batch constraints.
- [ ] Success, timeout, invalid response, redirect politikası.
- [ ] HTTP 429/seçilmiş 5xx retryable; auth/config/media errors permanent.
- [ ] Bounded exponential backoff, bounded jitter, attempts ve elapsed-time budget.
- [ ] Güvenli `Retry-After` desteği.
- [ ] Partial success decode ve truthful result.
- [ ] Exporter kendi HTTP çağrısını instrument etmiyor.
- [ ] Compression yalnız gerçek round-trip desteği varsa.
- [ ] Endpoint validation/SSRF threat model.
- [ ] Pinned OpenTelemetry Collector ile real traces integration.
- [ ] Pinned Collector ile real metrics integration.
- [ ] Controllable server ile rejection/retry/timeout/partial tests.
- [ ] Captured payload'da secret/body olmadığını doğrula.
- [ ] `examples/otlp_collector.nox` derlenen örneği.

Çıkış kapısı:

- [ ] Gerçek Collector iki sinyali kabul ediyor ve alanlar doğru.
- [ ] 60 saniyelik outage senaryosu bounded ve deadlock-free.
- [ ] Partial rejection tam başarı sayılmıyor.

### `v0.9.0` — Faz 9: gelişmiş metrics

Amaç: Views, bağımsız readers ve doğru delta temporality.

Bağımlılık: `v0.2.0`, `v0.8.0`.

- [ ] Name/scope selector'lü views.
- [ ] Aggregation override, attribute allowlist ve histogram boundaries.
- [ ] Invalid/overlapping views ve duplicate export-name politikası.
- [ ] Views measurement başlamadan deterministik resolve ediliyor.
- [ ] SDK internal metrics kullanıcı metrics'inden ayrılıyor.
- [ ] Reader başına bağımsız cumulative state.
- [ ] Reader başına bağımsız delta checkpoints.
- [ ] Başarısız export sonraki delta semantiğini bozmuyor.
- [ ] Snapshot güvenceye alınmadan reset yok.
- [ ] Restart/start timestamp ve counter reset semantiği.
- [ ] Prometheus ile OTLP reader state bağımsızlığı.
- [ ] ObservableGauge yalnız callback lifecycle iki backend'de güvenliyse.
- [ ] ObservableCounter/UpDownCounter spec gerekliyse ve güvenliyse.
- [ ] Exemplars yalnız gerçek sampled context, bounded reservoir ve privacy policy ile.
- [ ] Uygulanmayan advanced feature'ları açıkça `unsupported` işaretle.

Çıkış kapısı:

- [ ] İki reader birbirinin ölçümünü çalmıyor/resetlemiyor.
- [ ] Failed delta export sonrası doğru değer tekrar sunuluyor.
- [ ] Opsiyonel observable/exemplar özelliklerinin lifecycle/privacy testleri var veya dürüstçe ertelenmiş.

### `v0.10.0` — Faz 10: Obsidian correlation bridge

Amaç: Logging ownership'ını bozmadan küçük, immutable trace correlation snapshot'ı.

Bağımlılık: `v0.4.0`, `v0.5.0`.

- [ ] Neutral bridge contract: trace_id, span_id, trace_flags, opsiyonel request ID.
- [ ] Baggage veya tüm span attributes bridge'den geçmiyor.
- [ ] Obsidian bağımlılığı core'a girmiyor; circular import testi.
- [ ] Pulse absent/disabled iken Obsidian aynı biçimde çalışıyor.
- [ ] Ended/non-recording span snapshot davranışı.
- [ ] Mismatched adapter version hatası güvenli ve actionable.
- [ ] Double logging ve exporter/log recursion testleri.
- [ ] Feather SQL span içi log correlation acceptance testi; bind values yok.
- [ ] `examples/obsidian_correlation.nox` derlenen örneği.
- [ ] Ownership ADR ve version compatibility belgesi.

Çıkış kapısı:

- [ ] Tek trace boyunca loglarda doğru trace/span ID var.
- [ ] Disabled/absent Pulse hiçbir log kaybına veya crash'e yol açmıyor.
- [ ] Dependency graph döngüsüz.

### `v0.11.0` — Faz 11: ekosistem adapter'ları

Amaç: Core'u kirletmeden gerçek NOX framework akışlarında instrumentation.

Bağımlılık: İlgili framework sürümleri ayrıca pinlenecek.

#### Aether / Nyx

- [ ] Inbound W3C extract ve SERVER span.
- [ ] Low-cardinality route-template naming; raw URL/user ID yok.
- [ ] Pinned semantic-convention HTTP attributes.
- [ ] Success/error/cancel/timeout boyunca guaranteed end.
- [ ] Request count, duration ve active request metrics doğruluğu.

#### Nova

- [ ] CLIENT span ve trace headers inject.
- [ ] Authorization/Cookie ve user header overwrite güvenliği.
- [ ] Pulse OTLP endpoint recursion exclusion.
- [ ] Transport error ile HTTP status ayrımı.
- [ ] Retry boyunca doğru parentage ve duplicate span politikası.

#### Feather / Atlas

- [ ] CLIENT DB span ve low-cardinality operation.
- [ ] Raw SQL bind, credential, DSN ve result row capture yok.
- [ ] Pool/query duration metrics ve label-cardinality sınırı.

#### Quartz ve diğerleri

- [ ] Deterministic clock/ID/in-memory exporter assertion helpers.
- [ ] Quartz runtime dependency değil.
- [ ] Chronos/Rune/Aura ihtiyaçları ayrı privacy/capability değerlendirmesiyle opt-in.
- [ ] Mobile/WASM desteği kanıt olmadan ilan edilmiyor.

#### Entegrasyon kapısı

- [ ] Aether → Nyx → Feather/Atlas → Nova multi-hop trace testi.
- [ ] Trace ID korunuyor, her hop yeni doğru child span ID alıyor.
- [ ] Metrics doğru ve low-cardinality.
- [ ] Varsayılan payload/log/span içinde credentials, bodies, email, SQL params yok.

### `v0.12.0` — Faz 12: reliability, security ve performance

Amaç: Üretim adayının sınırlarını ölçmek ve hata altında güvenilirliğini kanıtlamak.

Bağımlılık: Önceki bütün zorunlu fazlar.

- [ ] Threat-model suite: malicious headers, baggage, labels, redirects, TLS, UTF-8, retry storms.
- [ ] Queue/payload/attribute/event/link/cardinality toplam memory-budget hesabı.
- [ ] Repeated startup/shutdown ve worker leak torture.
- [ ] Slow exporter + fast producer stress.
- [ ] Flush during recording ve shutdown during export stress.
- [ ] Same-span double-end race.
- [ ] Provider reconfiguration quiescence veya safe rejection.
- [ ] Diagnostics recursion ve self-observability isolation.
- [ ] Fuzz: W3C, baggage, protobuf decoder varsa, Prometheus escaping, config/env.
- [ ] Property tests: histogram count, counter monotonicity, accepted-record terminal states.
- [ ] `counter.add()` one/many-series benchmark.
- [ ] Histogram record benchmark.
- [ ] Span sampling on/off benchmark.
- [ ] Propagation parse/inject benchmark.
- [ ] Export throughput ve p50/p95/p99 hot-path latency.
- [ ] Peak heap at configured limits.
- [ ] CPU under exporter outage.
- [ ] Drop/loss counts under overload.
- [ ] Flush/shutdown completion measurements.
- [ ] Her ölçümde backend, OS, CPU, compiler SHA, warmup, sample count.
- [ ] Tasarım bütçeleri ile ölçülmüş sonuçları ayır; uydurma sayı yok.
- [ ] `docs/performance.md` ve security review güncellemesi.

Çıkış kapısı:

- [ ] Tekrarlı stress koşularında leak/deadlock/use-after-free belirtisi yok.
- [ ] Kaynak sınırları ölçülmüş ve belgelenmiş.
- [ ] P0/P1 security veya correctness açığı yok.

### `v0.13.0` — Faz 13: release candidate

Amaç: Destek iddialarını dondurmak ve platformlar arası yayın kanıtını tamamlamak.

Bağımlılık: Tüm zorunlu fazlar.

- [ ] Kamu API freeze proposal ve compatibility review.
- [ ] `README.md` desteklenen/unsupported feature tablosu.
- [ ] `docs/api.md`, architecture, compatibility, standards, exporter support final audit.
- [ ] Feature-to-test matrix eksiksiz.
- [ ] Migration ve upgrade belgeleri.
- [ ] `CHANGELOG.md`: Added/Changed/Fixed/Removed/Security.
- [ ] Lisans ve üçüncü taraf notices/dependency audit.
- [ ] Lockfile tekrar üretilebilirlik testi.
- [ ] Tüm örnekler compile ve execute.
- [ ] Package artifact install/import smoke.
- [ ] QBE full deterministic behavior suite.
- [ ] LLVM full suite ve ayrı real multi-worker job.
- [ ] Linux x64, Linux ARM64, macOS ARM64, Windows x64 destek matrisi.
- [ ] Collector ve Prometheus conformance job'ları.
- [ ] Security/privacy regression suite.
- [ ] Release artefakt checksum/SBOM/signing politikası.
- [ ] Registry submission ile gerçek registry availability ayrımı.
- [ ] Release rollback değil forward-fix prosedürü.

Çıkış kapısı:

- [ ] İlan edilen her özellik behavioral test ve belgeye bağlı.
- [ ] CI yeşil; skip/unsupported doğru ve gerekçeli.
- [ ] P0/P1 defect yok; bilinen limitler release notes'ta.
- [ ] Tag ve release aday artefaktı immutable süreçle üretilebiliyor.

### `v1.0.0` — stabil sürüm

- [ ] `v0.13.0` sahada belirlenen gözlem süresini kritik hata olmadan tamamladı.
- [ ] Stabil API listesi ve semver garantisi onaylandı.
- [ ] Supported NOX compiler aralığı ve tam test SHA'sı yayınlandı.
- [ ] Supported platform/backend/exporter/encoding/temporality matrisi yayınlandı.
- [ ] AGENTS kabul senaryoları A–O'nun tümü kanıtlandı veya kapsam dışı olanlar iddiadan çıkarıldı.
- [ ] Final security, privacy, interoperability ve release review tamamlandı.
- [ ] `v1.0.0` tag/release yalnız bütün kapılar yeşilken üretildi.

## 6. Her değişiklikte yinelenen kontrol listesi

Bu liste her PR/commit için uygulanır:

- [ ] İlgili faz, dosyalar ve başarı ölçütü çalışma başında belirtildi.
- [ ] Bilinmeyen NOX sözdizimi/API için minimal compiling spike yapıldı.
- [ ] Type/ownership/lifecycle tasarımı implementasyondan önce yazıldı.
- [ ] En küçük vertical slice: API → core → memory test → failure path → integration.
- [ ] Targeted tests hemen çalıştırıldı.
- [ ] Full suite ve iki backend sonucu kaydedildi.
- [ ] Protokol iddiası internal round-trip dışında bağımsız kanıtlandı.
- [ ] Yeni attribute/header/payload/diagnostic privacy açısından incelendi.
- [ ] Queue/cardinality/attribute/batch/retry/shutdown sınırları incelendi.
- [ ] Kamu API veya davranış değişikliği docs/changelog'a işlendi.
- [ ] Failing test zayıflatılmadı; blocker açıkça raporlandı.

## 7. Kabul senaryoları izleme matrisi

| Kimlik | Senaryo | İlk hedef sürüm | Durum |
|---|---|---:|---|
| A | 10 × 1.000 exact counter | `v0.2.0` | `[ ]` |
| B | Histogram boundary ve Prometheus/OTLP uyumu | `v0.8.0` | `[ ]` |
| C | 100.000 label altında 1.000-series bound | `v0.2.0` | `[x] QBE + LLVM` |
| D | Aether→Nova distributed trace | `v0.11.0` | `[ ]` |
| E | Obsidian SQL span correlation, bind yok | `v0.10.0` | `[ ]` |
| F | 0/100/parent sampling | `v0.6.0` | `[ ]` |
| G | 60 sn exporter outage bounded | `v0.8.0` | `[ ]` |
| H | Truthful flush ve safe shutdown | `v0.6.0` | `[ ]` |
| I | Independent OTLP decode + Collector | `v0.8.0` | `[ ]` |
| J | QBE/LLVM deterministic parity | `v0.13.0` | `[ ]` |
| K | Default privacy yasaklı değerler yok | Her sürüm | `[x] v0.1.0; her sürüm yeniden koşar` |
| L | Disabled mode side-effect free | `v0.1.0` | `[x]` |
| M | Malformed baggage bounded/safe | `v0.5.0` | `[ ]` |
| N | Partial OTLP success truthful | `v0.8.0` | `[ ]` |
| O | Resource/scope fidelity round-trip | `v0.7.0` | `[ ]` |

## 8. Bilinçli olarak ertelenen/kapsam dışı işler

- `[-]` OTLP/gRPC initial release için ertelendi: NOX transport artık mevcut, ancak gerçek Collector conformance ve connection/deadline lifecycle testleri olmadan destek ilan edilmeyecek.
- `[-]` Full OTLP logs pipeline: Obsidian sahiplik ADR'si olan ayrı bir gelecek sürüm konusu.
- `[-]` File exporter: path traversal/symlink/permissions/size politikasıyla ayrı sürüm önerisi.
- `[-]` OpenMetrics: Prometheus text MVP'sinden sonra, pinned parser ve fixture ile değerlendirilecek.
- `[-]` Automatic universal task context: gerçek TaskLocal/spawn/thread kanıtı yoksa eklenmeyecek.
- `[-]` Automatic monkey-patching: kapsam dışı.
- `[-]` APM SaaS, Collector, storage/query UI, alerting ve billing: kapsam dışı.
- `[-]` Request/response bodies, raw SQL values, credentials, PII/health data default capture: yasak.
- `[-]` NOX compiler/stdlib değişikliği: ayrı upstream proposal ve review olmadan yapılmayacak.

## 9. Risk kaydı

| Risk | Etki | Azaltma / karar kapısı | Durum |
|---|---|---|---|
| NOX API'leri plan metninden farklı olabilir | Compile/runtime hatası | 2.1.64 exact build-info pin + compiling smoke | Azaltıldı / upgrade başına audit |
| Formatter regresyonu generic veya binary kaynak semantiğini bozabilir | Kamu API kaynakları bozulur | check→fmt→check capability fixtures | Kapatıldı / regresyon kapısı aktif |
| Pass-only class formatter gövdeyi siliyor (`NOX-FMT-004`) | Format sonrası geçersiz kaynak | Pulse sınıfları gerçek metot gövdesi kullanır; fixture upstream kusuru yeniden üretir | Açık / contained |
| Optional float class state codegen olmuyor (`NOX-CODEGEN-001`) | Histogram empty min/max temsili build'i durdurur | `has_min_max` + concrete floats; fixture check-pass/build-fail'i yeniden üretir | Açık / contained |
| Typed enum/match regress edebilir | `AttributeValue` exhaustiveness bozulur | ADR-0006 + iki-backend smoke | Kapatıldı / regresyon kapısı aktif |
| `str` protobuf binary fidelity bozulabilir | OTLP bozulur | NUL/high-byte, byte bridge, protobuf ve HTTP round-trip kapıları | Azaltıldı / Collector açık |
| Task-local miras yok ve backend transferleri farklı | Context leakage | Explicit immutable context temel API | Tasarım limiti |
| QBE background worker desteklemez | Batch semantiği farklı | ADR-0002 cooperative/sync fallback; processor testleri Faz 6'da | Karar verildi / uygulama açık |
| NaN karşılaştırma regresyonu | Geçersiz metric/span değeri kaçabilir | QBE/LLVM parity gate + Faz 1 finite validator | Kapatıldı / regresyon kapısı aktif |
| Clock çözünürlüğü hedefe göre değişir | Sahte precision riski | `now_ns`/`monotonic_ns` + hedef çözünürlük disclosure | Tasarım limiti |
| Module globals worker-local olabilir | Metrics kaybı/race | Ownership/atomics/channel audit ve real LLVM test | Açık |
| Şema derleyici yok; field numaraları elle eşlenir | Wire-format hata riski | Public wire codec + pinned schema + independent fixtures/decoder | Faz 7 açık |
| HTTP/TLS ayrıntıları eksik olabilir | Exporter hataları | Binary/header/redirect/timeout/self-signed rejection geçti; trusted-chain/hostname matrisi açık | Azaltıldı |
| HTTP method/body validasyonu regress edebilir | Yanlış request config veri kaybeder | İki-backend loopback regression | Kapatıldı / kapı aktif |
| Cardinality/queue kopyaları gizli bellek büyütür | OOM | Allocation-before-limit yasağı ve total memory budget | Açık |
| Adapter dependency cycle | Core taşınabilirliği bozulur | Leaf packages + import graph CI | Açık |

## 10. Sürüm kanıt kaydı şablonu

Her sürüm kapanışında aşağıdaki kayıt kopyalanıp doldurulur:

```text
Sürüm / faz:
Durum ve tarih:
Dosyalar:
NOX sürümü ve tam SHA:
Platform / CPU:
Kamu API değişiklikleri:
Standart/spec/schema sürümleri:
Çalıştırılan kesin komutlar:
QBE sonucu (test sayısı / fail / skip):
LLVM sonucu (test sayısı / fail / skip):
Collector/Prometheus conformance:
Concurrency/security sonuçları:
Ölçülen kaynak/performance sonuçları:
Bilinen sınırlamalar:
Ertelenen maddeler:
Changelog/release etkisi:
Commit/tag:
```

## 11. Kanıt günlüğü

### `v0.0.1` / Faz 0

- Durum ve tarih: yerel kapı geçti, 2026-11-11.
- NOX: daha sonra doğrulanıp baseline yapılan `2.1.64`, `be3458c332c8234baa8f3f8ac2ae9601db24321e`.
- Platform: macOS ARM64; QBE ve LLVM smoke 10/10, capability auditleri geçti.
- Kalanlar: uzak CI platform kanıtı, Windows kararı, trusted TLS matrisi, lisans kararı.
- Commit/tag: henüz yok; bu kayıt yayın iddiası değildir.

### `v0.1.0` / Faz 1

- Durum ve tarih: ortak telemetry primitives yerel kapısı geçti, 2026-11-12.
- Dosyalar: `api/`, `core/`, `sdk/`, Phase 1 unit/property/security/golden testleri ve ilgili belgeler.
- NOX: izole resmî `noxc 2.1.64`, `be3458c332c8234baa8f3f8ac2ae9601db24321e`; sistem `2.1.52` değiştirilmedi.
- Platform: macOS ARM64.
- Kamu API: explicit context, metrics/tracing base contracts, no-op providers; recording SDK veya exporter iddiası yok.
- Kesin kapılar: `NOXC=<isolated-2.1.64> bash scripts/run-phase1-tests.sh llvm` ve aynı komut `qbe`.
- QBE: 12 modül type-check; 3 unit dosyası, 1 security, 1 seeded property ve 1 golden fixture geçti; fail/skip yok.
- LLVM: aynı sonuç; fail/skip yok.
- Security/resources: record-boundary sensitive drop, defensive copy, finite değer, count/byte/cardinality/queue/deadline config sınırları geçti.
- Collector/Prometheus/concurrency/performance: bu fazın kapsamı değil; ilgili sonraki fazlarda açık.
- Bilinen sınırlamalar: `NOX-FMT-004`, explicit context ve QBE cooperative tasarım sınırları devam ediyor.
- Changelog/manifest: güncellendi; manifest `0.1.0`.
- Commit/tag: henüz yok; bu kayıt yayın iddiası değildir.

### `v0.2.0` / Faz 2 ilerleme kaydı

- Durum ve tarih: aktif, kapanmadı; 2026-11-13.
- Eklenenler: instrument descriptor/duplicate registry, type-tagged canonical series key, provider-wide series+estimated-byte budget, hard per-instrument point cap, OTel overflow point, üç bounded synchronous storage ve single-owner recording provider.
- Kesin kapılar: `NOXC=<isolated-2.1.64> bash scripts/run-phase2-tests.sh llvm` ve aynı komut `qbe`.
- QBE/LLVM: instrument, Counter, UpDown arithmetic, Histogram, series identity, cardinality ve 100.000-label stress kapıları geçti.
- Stress sonucu: 100.000 benzersiz set, 1.000 point hard sınırı, toplam 100.000; ölçüm drop/double-count yok.
- Phase 1 regresyonu: iki backend'de 11 unit dosyası + security + property + golden geçti.
- Açık: cumulative reader, provider lifecycle ve real LLVM multi-worker correctness; mevcut recording provider single-owner.
- Sistem derleyicisi: değiştirilmedi; izole resmî `2.1.64` kullanıldı.
