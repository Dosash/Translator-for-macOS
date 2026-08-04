# Сайт «Слово»

Статический мультиязычный лендинг приложения, готовый для GitHub Pages. Каждая из 12 локализаций получает собственный HTML и URL для индексации.

## Генерация страниц

```bash
node build.mjs
```

Тексты находятся в `src/locales.mjs`. Генератор создаёт каталоги `/ru/`, `/en/`, `/es/`, `/de/`, `/fr/`, `/it/`, `/pt/`, `/zh/`, `/ja/`, `/ko/`, `/tr/`, `/uk/`, а также `sitemap.xml` и `robots.txt`.

## Локальный запуск

```bash
cd website
python3 -m http.server 4173
```

Откройте <http://localhost:4173>.

## Публикация позже

Ссылки на публичный репозиторий, последний GitHub Release и `Translator.dmg` уже настроены. Перед публикацией добавьте файл `CNAME` со значением `useslovo.ru` и выберите папку сайта как источник GitHub Pages. После публикации отправьте `https://useslovo.ru/sitemap.xml` в панели Google Search Console и Яндекс Вебмастер.
