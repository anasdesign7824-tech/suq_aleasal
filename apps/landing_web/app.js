const header = document.querySelector('[data-header]');
const year = document.querySelector('[data-year]');
const form = document.querySelector('[data-notify-form]');
const status = document.querySelector('[data-form-status]');

if (year) year.textContent = new Date().getFullYear();

const onScroll = () => {
  if (header) header.classList.toggle('is-scrolled', window.scrollY > 16);
};
window.addEventListener('scroll', onScroll, { passive: true });
onScroll();

const revealItems = document.querySelectorAll('.reveal');
if ('IntersectionObserver' in window) {
  const observer = new IntersectionObserver(
    (entries, instance) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add('is-visible');
        instance.unobserve(entry.target);
      });
    },
    { threshold: 0.14 },
  );
  revealItems.forEach((item) => observer.observe(item));
} else {
  revealItems.forEach((item) => item.classList.add('is-visible'));
}

if (form && status) {
  form.addEventListener('submit', (event) => {
    event.preventDefault();
    const email = new FormData(form).get('email');
    if (!email) return;
    status.textContent = 'تم تسجيل اهتمامك على هذا الجهاز. سنضيف رابط الإطلاق عند اعتماد قناة الإشعارات.';
    form.reset();
  });
}
