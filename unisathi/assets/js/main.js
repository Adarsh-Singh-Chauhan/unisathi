document.addEventListener('DOMContentLoaded', () => {
  const header = document.querySelector('.site-header');
  const toggle = document.querySelector('.menu-toggle');
  const nav = document.querySelector('#primary-nav');
  const links = [...document.querySelectorAll('#primary-nav a[href^="#"]')];
  const sections = links.map(link => document.querySelector(link.getAttribute('href'))).filter(Boolean);
  const updateHeader = () => header.classList.toggle('scrolled', window.scrollY > 14);
  updateHeader(); window.addEventListener('scroll', updateHeader, {passive:true});
  toggle?.addEventListener('click', () => { const open = nav.classList.toggle('open'); toggle.setAttribute('aria-expanded', open); });
  links.forEach(link => link.addEventListener('click', () => { nav.classList.remove('open'); toggle?.setAttribute('aria-expanded', 'false'); }));
  const observer = new IntersectionObserver(entries => entries.forEach(entry => { if (entry.isIntersecting) { links.forEach(link => link.classList.toggle('active', link.getAttribute('href') === '#' + entry.target.id)); } }), {rootMargin:'-40% 0px -52%'});
  sections.forEach(section => observer.observe(section));
  const reveal = new IntersectionObserver(entries => entries.forEach(entry => { if(entry.isIntersecting) { entry.target.classList.add('visible'); reveal.unobserve(entry.target); } }), {threshold:.12});
  document.querySelectorAll('.role-card,.challenge-card,.feature-card,.timeline-item,.benefit-grid article').forEach(element => { element.classList.add('reveal'); reveal.observe(element); });
});

