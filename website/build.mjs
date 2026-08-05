import { mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { gatekeeperHelp, languageCodes, languageNames, locales, processorCompatibility, quarantineCommand, siteUrl } from './src/locales.mjs';

const root = dirname(fileURLToPath(import.meta.url));
const year = new Date().getFullYear();
const h = (value) => String(value).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
const themeLabels = { ru: 'Сменить тему примера', en: 'Change preview theme', es: 'Cambiar tema de la vista previa', de: 'Vorschauthema ändern', fr: 'Changer le thème de l’aperçu', it: 'Cambia tema dell’anteprima', pt: 'Alterar tema da prévia', zh: '切换预览主题', ja: 'プレビューのテーマを変更', ko: '미리보기 테마 변경', tr: 'Önizleme temasını değiştir', uk: 'Змінити тему прикладу' };
const repositoryUrl = 'https://github.com/Dosash/Translator-for-macOS';
const releaseUrl = `${repositoryUrl}/releases/latest`;
const downloadUrl = `${repositoryUrl}/releases/latest/download/Translator.dmg`;
const releaseVersion = '1.3';
const siteAssetVersion = '2026-08-05-1';
const githubIcon = (className = '') => `<svg class="${className}" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 .7a11.5 11.5 0 0 0-3.64 22.4c.58.1.79-.25.79-.56v-2.23c-3.22.7-3.9-1.37-3.9-1.37-.52-1.34-1.28-1.7-1.28-1.7-1.05-.72.08-.7.08-.7 1.16.08 1.77 1.19 1.77 1.19 1.03 1.77 2.7 1.26 3.36.96.1-.75.4-1.26.73-1.55-2.57-.3-5.28-1.29-5.28-5.69 0-1.26.45-2.29 1.19-3.1-.12-.3-.52-1.47.11-3.06 0 0 .97-.31 3.16 1.18a10.98 10.98 0 0 1 5.76 0c2.19-1.49 3.16-1.18 3.16-1.18.63 1.59.23 2.76.11 3.06.74.81 1.19 1.84 1.19 3.1 0 4.42-2.71 5.39-5.29 5.68.42.36.79 1.06.79 2.14v3.18c0 .31.21.67.8.56A11.5 11.5 0 0 0 12 .7Z"/></svg>`;
const withVersion = (value) => value.replaceAll('{version}', releaseVersion);
const interfaceIcons = {
  speaker: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 10v4h3l4 3V7l-4 3H5Z"/><path d="M15.5 9.2a4 4 0 0 1 0 5.6"/><path d="M18 6.8a7.4 7.4 0 0 1 0 10.4"/></svg>',
  close: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="m8 8 8 8M16 8l-8 8"/></svg>',
  copy: '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="8" y="8" width="9" height="9" rx="2"/><path d="M14 8V7a2 2 0 0 0-2-2H7a2 2 0 0 0-2 2v5a2 2 0 0 0 2 2h1"/></svg>',
  lock: '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="5" y="10" width="14" height="10" rx="3"/><path d="M8.5 10V7.5a3.5 3.5 0 0 1 7 0V10"/><path d="M12 14v2"/></svg>',
};

function alternateLinks() {
  return [
    ...languageCodes.map((code) => `    <link rel="alternate" hreflang="${code}" href="${siteUrl}/${code}/" />`),
    `    <link rel="alternate" hreflang="x-default" href="${siteUrl}/" />`,
  ].join('\n');
}

function languageOptions(current) {
  return languageCodes.map((code) => `<option value="${code}"${code === current ? ' selected' : ''}>${languageNames[code]}</option>`).join('');
}

function structuredData(code, t) {
  return JSON.stringify({
    '@context': 'https://schema.org',
    '@type': 'SoftwareApplication',
    name: 'Слово',
    alternateName: 'Slovo',
    url: `${siteUrl}/${code}/`,
    description: t.description,
    applicationCategory: 'UtilitiesApplication',
    operatingSystem: 'macOS 15 or later',
    processorRequirements: 'Universal binary: Apple Silicon (arm64), M1 or newer, and Intel Macs (x86_64).',
    inLanguage: code,
    image: `${siteUrl}/assets/app-icon.png`,
    downloadUrl,
    softwareVersion: releaseVersion,
    offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
    license: 'https://opensource.org/license/mit',
  }).replaceAll('<', '\\u003c');
}

function page(code, t) {
  const appTitle = code === 'ru' || code === 'uk' ? 'Слово' : 'Slovo';
  const compatibility = processorCompatibility[code].map(withVersion);
  const gatekeeper = gatekeeperHelp[code];
  const ogAlternates = languageCodes.filter((item) => item !== code).map((item) => `    <meta property="og:locale:alternate" content="${locales[item].locale}" />`).join('\n');
  return `<!doctype html>
<html lang="${code}">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#eef4f8" />
    <meta name="robots" content="index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1" />
    <meta name="description" content="${h(t.description)}" />
    <meta name="application-name" content="${appTitle}" />
    <link rel="canonical" href="${siteUrl}/${code}/" />
${alternateLinks()}
    <meta property="og:title" content="${h(t.title)}" />
    <meta property="og:description" content="${h(t.description)}" />
    <meta property="og:type" content="website" />
    <meta property="og:url" content="${siteUrl}/${code}/" />
    <meta property="og:image" content="${siteUrl}/assets/app-icon.png" />
    <meta property="og:image:width" content="512" />
    <meta property="og:image:height" content="512" />
    <meta property="og:locale" content="${t.locale}" />
${ogAlternates}
    <meta name="twitter:card" content="summary" />
    <meta name="twitter:title" content="${h(t.title)}" />
    <meta name="twitter:description" content="${h(t.description)}" />
    <meta name="twitter:image" content="${siteUrl}/assets/app-icon.png" />
    <title>${h(t.title)}</title>
    <link rel="icon" href="../assets/app-icon.png" />
    <link rel="apple-touch-icon" href="../assets/app-icon.png" />
    <link rel="stylesheet" href="../styles.css?v=${siteAssetVersion}" />
    <script type="application/ld+json">${structuredData(code, t)}</script>
    <script src="../script.js?v=${siteAssetVersion}" defer></script>
  </head>
  <body data-language="${code}">
    <a class="skip-link" href="#main">${h(t.skip)}</a>

    <header class="site-header" data-header>
      <div class="shell header-inner">
        <a class="brand" href="#top" aria-label="${h(t.home)}"><img src="../assets/app-icon.png" width="36" height="36" alt="" /><span>Слово</span></a>
        <button class="menu-button" type="button" aria-label="${h(t.openMenu)}" aria-expanded="false" data-menu-button><span></span><span></span></button>
        <nav class="nav" aria-label="${h(t.nav[0])}" data-nav>
          <a href="#features">${h(t.nav[0])}</a><a href="#privacy">${h(t.nav[1])}</a><a href="#how-it-works">${h(t.nav[2])}</a>
          <label class="language-select"><span class="sr-only">${h(t.chooseLanguage)}</span><select data-language-select aria-label="${h(t.chooseLanguage)}">${languageOptions(code)}</select></label>
          <a class="nav-download" href="#download">${h(t.nav[3])}</a>
        </nav>
      </div>
    </header>

    <main id="main">
      <section class="hero shell" id="top">
        <div class="hero-copy reveal">
          <div class="eyebrow"><span></span> ${h(t.eyebrow)}</div>
          <h1>${h(t.hero[0])}<br /><em>${h(t.hero[1])}</em></h1>
          <p class="hero-lead">${h(t.hero[2])}</p>
          <div class="hero-actions">
            <a class="button button-primary" href="#download"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M16.7 12.9c0-2.6 2.1-3.9 2.2-4-1.2-1.8-3.1-2-3.8-2-1.6-.2-3.2 1-4 1-.9 0-2.3-1-3.7-1-1.9 0-3.6 1.1-4.6 2.8-2 3.4-.5 8.5 1.4 11.3.9 1.4 2 2.9 3.5 2.8 1.4-.1 2-1 3.7-1s2.2 1 3.7 1c1.5 0 2.5-1.4 3.4-2.8 1.1-1.6 1.5-3.2 1.5-3.3-.1 0-3.3-1.3-3.3-4.8ZM14 5.2c.8-1 1.4-2.4 1.2-3.8-1.2.1-2.7.8-3.6 1.8-.8.9-1.5 2.3-1.3 3.7 1.4.1 2.8-.7 3.7-1.7Z"/></svg>${h(t.hero[3])}</a>
            <a class="text-link" href="#how-it-works">${h(t.hero[4])} <span>↓</span></a>
          </div>
          <p class="hero-note">${h(t.hero[5])}</p>
        </div>

        <div class="hero-visual reveal" data-delay="1" aria-label="${h(t.app[0])}">
          <div class="orb orb-one"></div><div class="orb orb-two"></div>
          <div class="mac-window">
            <div class="window-topbar"><div class="traffic"><i></i><i></i><i></i></div><span>${appTitle}</span><button class="theme-button" type="button" aria-label="${h(themeLabels[code])}" aria-pressed="false" data-theme-button><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3v2m0 14v2M3 12h2m14 0h2M5.64 5.64l1.42 1.42m9.88 9.88 1.42 1.42m0-12.72-1.42 1.42M7.06 16.94l-1.42 1.42M16 12a4 4 0 1 1-8 0 4 4 0 0 1 8 0Z"/></svg></button></div>
            <div class="translator-card">
              <div class="app-heading"><div class="mini-brand"><img src="../assets/app-icon.png" width="40" height="40" alt="" /><div><strong>${appTitle}</strong><small>${h(t.app[0])}</small></div></div><span class="privacy-pill"><i></i>${h(t.app[1])}</span></div>
              <div class="language-row"><button type="button">${h(t.app[2])} <span>⌄</span></button><span class="swap" aria-hidden="true">⇄</span><button type="button">${h(t.app[3])} <span>⌄</span></button></div>
              <div class="translation-box source-box"><span>${h(t.app[8])}</span><small>${t.app[8].length} / 5000</small></div>
              <div class="translate-row"><button type="button">${h(t.app[4])}</button><span class="mock-icon mock-speaker">${interfaceIcons.speaker}</span><span class="mock-icon mock-clear">${interfaceIcons.close}</span></div>
              <div class="translation-box result-box"><span>${h(t.app[9])}</span><div class="result-actions"><span class="mock-icon mock-speaker">${interfaceIcons.speaker}</span><span class="mock-icon mock-copy">${interfaceIcons.copy}</span></div></div>
              <div class="app-footer"><span>⌨ ${h(t.app[5])}</span><kbd>⌃⌥T</kbd></div>
            </div>
          </div>
          <div class="hotkey-card"><div class="hotkey-icon">⌘</div><div><small>${h(t.app[6])}</small><strong>⌃ + ⌥ + T</strong></div><span>${h(t.app[7])}</span></div>
        </div>
      </section>

      <section class="trust-strip" aria-label="${h(t.featuresHead[0])}"><div class="shell trust-grid">${t.stats.map(([number, label]) => `<div><strong>${h(number)}</strong><span>${h(label)}</span></div>`).join('')}</div></section>

      <section class="section shell" id="features">
        <div class="section-heading reveal"><div class="eyebrow"><span></span> ${h(t.featuresHead[0])}</div><h2>${h(t.featuresHead[1])}</h2><p>${h(t.featuresHead[2])}</p></div>
        <div class="feature-grid">
          <article class="feature-card feature-wide reveal"><div class="feature-copy"><div class="feature-icon lilac">⌨</div><h3>${h(t.features[0][0])}</h3><p>${h(t.features[0][1])}</p></div><div class="selection-demo"><div class="browser-bar"><i></i><i></i><i></i><span>article.example</span></div><p>${h(t.demoQuote[0])}</p><div class="selection-popover">${h(t.demoQuote[1])}</div></div></article>
          <article class="feature-card reveal" data-delay="1"><div class="feature-icon blue">◉</div><h3>${h(t.features[1][0])}</h3><p>${h(t.features[1][1])}</p><div class="engine-toggle"><div class="active"><span>◉</span><div><strong>${h(t.engine[0])}</strong><small>${h(t.engine[1])}</small></div><i>✓</i></div><div><span>◎</span><div><strong>${h(t.engine[2])}</strong><small>${h(t.engine[3])}</small></div></div></div></article>
          <article class="feature-card reveal" data-delay="2"><div class="feature-icon coral">◷</div><h3>${h(t.features[2][0])}</h3><p>${h(t.features[2][1])}</p><div class="history-list">${t.history.map(([source, target, time]) => `<div><span><b>${h(source)}</b><small>${h(target)}</small></span><time>${h(time)}</time></div>`).join('')}</div></article>
        </div>
      </section>

      <section class="section privacy-section" id="privacy"><div class="shell privacy-layout">
        <div class="privacy-visual reveal"><div class="shield-rings"><div class="shield">${interfaceIcons.lock}<span>✓</span></div></div><span class="privacy-label label-local">${h(t.privacy[7])}</span><span class="privacy-label label-control">${h(t.privacy[8])}</span><span class="privacy-label label-private">${h(t.privacy[9])}</span></div>
        <div class="privacy-copy reveal" data-delay="1"><div class="eyebrow"><span></span> ${h(t.privacy[0])}</div><h2>${h(t.privacy[1])}<br /><em>${h(t.privacy[2])}</em></h2><p>${h(t.privacy[3])}</p><ul>${t.privacy.slice(4, 7).map((item) => `<li><span>✓</span>${h(item)}</li>`).join('')}</ul></div>
      </div></section>

      <section class="section shell how" id="how-it-works"><div class="section-heading centered reveal"><div class="eyebrow"><span></span> ${h(t.how[0])}</div><h2>${h(t.how[1])}</h2></div><ol class="steps">${t.steps.map(([title, text], index) => `<li class="reveal"${index ? ` data-delay="${index}"` : ''}><span class="step-number">0${index + 1}</span><div class="step-icon">${['↓', 'A', '⌃⌥T'][index]}</div><h3>${h(title)}</h3><p>${h(text)}</p></li>`).join('')}</ol><div class="gatekeeper reveal"><div class="gatekeeper-intro"><span class="gatekeeper-mark" aria-hidden="true">${interfaceIcons.lock}</span><div><div class="eyebrow"><span></span> ${h(gatekeeper[0])}</div><h3>${h(gatekeeper[1])}</h3><p>${h(gatekeeper[2])}</p></div></div><div class="gatekeeper-methods"><div class="gatekeeper-method"><strong>${h(gatekeeper[3])}</strong><ol>${gatekeeper[4].map((item) => `<li>${h(item)}</li>`).join('')}</ol></div><div class="gatekeeper-method"><strong>${h(gatekeeper[5])}</strong><p>${h(gatekeeper[6])}</p><code>${h(quarantineCommand)}</code></div></div></div></section>

      <section class="section github-section" id="open-source"><div class="shell github-card reveal"><div class="github-mark">${githubIcon()}</div><div class="github-copy"><div class="eyebrow"><span></span> ${h(t.github[0])}</div><h2>${h(t.github[1])}</h2><p>${h(t.github[2])}</p><div class="github-actions"><a class="button github-primary" href="${repositoryUrl}" target="_blank" rel="noreferrer">${githubIcon('button-github-icon')}${h(t.github[3])}</a><a class="github-release-link" href="${releaseUrl}" target="_blank" rel="noreferrer">${h(withVersion(t.github[4]))} ↗</a></div><small>${h(t.github[5])}</small></div></div></section>

      <section class="section shell download-section" id="download"><div class="download-card reveal"><div class="download-glow glow-left"></div><div class="download-glow glow-right"></div><img src="../assets/app-icon.png" width="96" height="96" alt="${appTitle}" /><h2>${h(t.cta[0])}<br />${h(t.cta[1])}</h2><p>${h(t.cta[2])}</p><div class="compatibility" aria-label="${h(compatibility[0])}"><strong class="compatibility-title">${h(compatibility[0])}</strong><div class="compatibility-grid"><div class="compatibility-item compatibility-supported"><span class="compatibility-status">✓ ${h(compatibility[1])}</span><strong>${h(compatibility[2])}</strong><small>${h(compatibility[3])}</small></div><div class="compatibility-item compatibility-supported"><span class="compatibility-status">✓ ${h(compatibility[4])}</span><strong>${h(compatibility[5])}</strong><small>${h(compatibility[6])}</small></div></div><p class="compatibility-note">${h(compatibility[7])}</p></div><a class="button button-light" href="${downloadUrl}"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M16.7 12.9c0-2.6 2.1-3.9 2.2-4-1.2-1.8-3.1-2-3.8-2-1.6-.2-3.2 1-4 1-.9 0-2.3-1-3.7-1-1.9 0-3.6 1.1-4.6 2.8-2 3.4-.5 8.5 1.4 11.3.9 1.4 2 2.9 3.5 2.8 1.4-.1 2-1 3.7-1s2.2 1 3.7 1c1.5 0 2.5-1.4 3.4-2.8 1.1-1.6 1.5-3.2 1.5-3.3-.1 0-3.3-1.3-3.3-4.8ZM14 5.2c.8-1 1.4-2.4 1.2-3.8-1.2.1-2.7.8-3.6 1.8-.8.9-1.5 2.3-1.3 3.7 1.4.1 2.8-.7 3.7-1.7Z"/></svg>${h(withVersion(t.cta[3]))}</a><small class="download-meta">${h(t.cta[4])}</small></div></section>
    </main>

    <footer class="footer"><div class="shell footer-inner"><a class="brand" href="#top"><img src="../assets/app-icon.png" width="32" height="32" alt="" /><span>Слово</span></a><p>${h(t.tagline)}</p><div class="footer-links"><a class="footer-github" href="${repositoryUrl}" target="_blank" rel="noreferrer">${githubIcon('footer-github-icon')}GitHub</a><a href="#privacy">${h(t.privacyLink)}</a></div><span class="copyright">© ${year} Слово · useslovo.ru</span></div></footer>
  </body>
</html>
`;
}

function rootPage() {
  const links = languageCodes.map((code) => `<a href="./${code}/" lang="${code}">${languageNames[code]}</a>`).join('');
  return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" /><meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="robots" content="index, follow" /><meta name="description" content="Slovo — a fast, private translator for macOS, available in 12 languages." />
    <link rel="canonical" href="${siteUrl}/" />
${alternateLinks()}
    <title>Slovo — translator for macOS</title><link rel="icon" href="assets/app-icon.png" />
    <style>body{margin:0;min-height:100vh;display:grid;place-items:center;background:#f4f7f9;color:#162026;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}.card{width:min(620px,calc(100% - 40px));text-align:center}.card img{width:84px;border-radius:20px}.card h1{font:500 58px/1.05 Iowan Old Style,Baskerville,serif;margin:24px 0 12px}.card p{color:#66737a}.languages{margin-top:30px;display:flex;flex-wrap:wrap;justify-content:center;gap:9px}.languages a{padding:10px 14px;border:1px solid rgba(20,37,45,.12);border-radius:999px;color:inherit;text-decoration:none;background:#fff}.languages a:hover{border-color:#24a87a;color:#157f5c}</style>
    <script>!function(){var s=${JSON.stringify(languageCodes)},p='';try{p=localStorage.getItem('slovo-language')||''}catch(e){}var l=(p||navigator.languages&&navigator.languages[0]||navigator.language||'en').toLowerCase().split('-')[0];location.replace('./'+(s.includes(l)?l:'en')+'/'+location.hash)}();</script>
  </head>
  <body><main class="card"><img src="assets/app-icon.png" alt="Slovo" /><h1>Slovo</h1><p>Choose your language · Выберите язык</p><nav class="languages" aria-label="Languages">${links}</nav></main></body>
</html>`;
}

function sitemap() {
  const today = new Date().toISOString().slice(0, 10);
  const urls = [`${siteUrl}/`, ...languageCodes.map((code) => `${siteUrl}/${code}/`)];
  return `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls.map((url) => `  <url><loc>${url}</loc><lastmod>${today}</lastmod><changefreq>monthly</changefreq><priority>${url === `${siteUrl}/` ? '1.0' : '0.9'}</priority></url>`).join('\n')}\n</urlset>\n`;
}

for (const code of languageCodes) {
  const output = join(root, code);
  await rm(output, { recursive: true, force: true });
  await mkdir(output, { recursive: true });
  await writeFile(join(output, 'index.html'), page(code, locales[code]));
}

await writeFile(join(root, 'index.html'), rootPage());
await writeFile(join(root, 'sitemap.xml'), sitemap());
await writeFile(join(root, 'robots.txt'), `User-agent: *\nAllow: /\n\nSitemap: ${siteUrl}/sitemap.xml\n`);

const sourceScript = await readFile(join(root, 'script.js'), 'utf8');
if (!sourceScript.includes('data-language-select')) throw new Error('script.js must support language selection');

console.log(`Generated ${languageCodes.length} localized pages for ${siteUrl}`);
