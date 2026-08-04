const header = document.querySelector('[data-header]');
const menuButton = document.querySelector('[data-menu-button]');
const nav = document.querySelector('[data-nav]');
const themeButton = document.querySelector('[data-theme-button]');
const appWindow = document.querySelector('.mac-window');
const languageSelect = document.querySelector('[data-language-select]');

const updateHeader = () => header?.classList.toggle('scrolled', window.scrollY > 12);
updateHeader();
window.addEventListener('scroll', updateHeader, { passive: true });

menuButton?.addEventListener('click', () => {
  const isOpen = nav.classList.toggle('open');
  menuButton.setAttribute('aria-expanded', String(isOpen));
});

nav?.addEventListener('click', (event) => {
  if (event.target.closest('a')) {
    nav.classList.remove('open');
    menuButton?.setAttribute('aria-expanded', 'false');
  }
});

themeButton?.addEventListener('click', () => {
  const isDark = appWindow?.classList.toggle('dark') ?? false;
  themeButton.setAttribute('aria-pressed', String(isDark));
});

languageSelect?.addEventListener('change', () => {
  const language = languageSelect.value;
  try {
    localStorage.setItem('slovo-language', language);
  } catch {
    // Language switching still works when storage is unavailable.
  }
  window.location.href = `../${language}/${window.location.hash}`;
});

const year = document.querySelector('[data-year]');
if (year) year.textContent = String(new Date().getFullYear());

if ('IntersectionObserver' in window) {
  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.12 });
  document.querySelectorAll('.reveal').forEach((element) => observer.observe(element));
} else {
  document.querySelectorAll('.reveal').forEach((element) => element.classList.add('visible'));
}
