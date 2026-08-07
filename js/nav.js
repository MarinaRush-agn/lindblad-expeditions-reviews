const btn = document.querySelector('.nav-toggle');
const nav = document.querySelector('.site-nav');
btn?.addEventListener('click', () => {
  const open = btn.getAttribute('aria-expanded') === 'true';
  btn.setAttribute('aria-expanded', String(!open));
  nav.classList.toggle('is-open');
});

// Mouse users expect this dropdown to open on hover, not just on click —
// use the real [open] attribute so native <details> behaviour stays correct
// for keyboard/touch. Gated on (hover: hover) so touch taps aren't affected.
const navDropdown = document.querySelector('.nav-dropdown');
const navDetails = navDropdown?.querySelector('details');
if (navDropdown && navDetails && window.matchMedia('(hover: hover)').matches) {
  navDropdown.addEventListener('mouseenter', () => navDetails.setAttribute('open', ''));
  navDropdown.addEventListener('mouseleave', () => navDetails.removeAttribute('open'));
}
