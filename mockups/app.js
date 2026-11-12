const screens = [...document.querySelectorAll('.screen')];
const navItems = [...document.querySelectorAll('.nav-item')];

function go(id) {
  screens.forEach((screen) => screen.classList.toggle('active', screen.id === id));
  navItems.forEach((item) => item.classList.toggle('active', item.dataset.screen === id));
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

document.querySelectorAll('[data-go]').forEach((element) => {
  element.addEventListener('click', () => go(element.dataset.go));
});

navItems.forEach((item) => {
  item.addEventListener('click', () => go(item.dataset.screen));
});

document.querySelectorAll('.day-tabs').forEach((tabs) => {
  [...tabs.querySelectorAll('.day-tab')].forEach((tab) => {
    tab.addEventListener('click', () => {
      tabs.querySelectorAll('.day-tab').forEach((item) => item.classList.remove('active'));
      tab.classList.add('active');
    });
  });
});

function revealPrices(category) {
  const prices = [...category.querySelectorAll('.price')];
  prices.forEach((price, index) => {
    if (price.dataset.loaded === '1') {
      return;
    }
    const missing = price.dataset.missing === 'true';
    const value = price.dataset.price || String(30 + Math.round(Math.random() * 420));
    price.textContent = '';
    price.className = 'price loading';
    window.setTimeout(() => {
      if (missing) {
        price.textContent = '—';
        price.className = 'price missing';
      } else {
        price.textContent = `${value} ₽`;
        price.className = 'price found';
      }
      price.dataset.loaded = '1';
    }, 650 + index * 230);
  });
}

document.querySelectorAll('.shopping-head').forEach((head) => {
  head.addEventListener('click', () => {
    const category = head.closest('.shopping-category');
    category.classList.toggle('open');
    if (category.classList.contains('open')) {
      revealPrices(category);
    }
  });
});

document.querySelectorAll('[data-refresh-prices]').forEach((button) => {
  button.addEventListener('click', () => {
    document.querySelectorAll('.shopping-category.open').forEach((category) => {
      category.querySelectorAll('.price').forEach((price) => {
        price.dataset.loaded = '0';
      });
      revealPrices(category);
    });
  });
});

document.querySelectorAll('.segmented').forEach((group) => {
  [...group.querySelectorAll('button')].forEach((button) => {
    button.addEventListener('click', () => {
      group.querySelectorAll('button').forEach((item) => item.classList.remove('active'));
      button.classList.add('active');
    });
  });
});

document.querySelectorAll('.chips').forEach((group) => {
  [...group.querySelectorAll('.chip')].forEach((chip) => {
    chip.addEventListener('click', () => {
      group.querySelectorAll('.chip').forEach((item) => item.classList.remove('active'));
      chip.classList.add('active');
    });
  });
});

const params = new URLSearchParams(window.location.search);
const theme = params.get('theme') || 'warm';
document.body.className = `theme-${theme}`;
document.querySelectorAll('.theme-switch a').forEach((link) => {
  link.classList.toggle('active', link.dataset.theme === theme);
});

const initialScreen = params.get('screen');
if (initialScreen) {
  go(initialScreen);
}
