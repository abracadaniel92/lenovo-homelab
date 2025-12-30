// Hero page-load animation
window.addEventListener('load', function () {
  const items = document.querySelectorAll('.hero-item');
  items.forEach((el, index) => {
    el.style.transitionDelay = (0.12 * index) + 's';
  });
  document.body.classList.add('page-loaded');
});

// Counter animations
document.addEventListener('DOMContentLoaded', () => {
  const counters = document.querySelectorAll('.stat-number[data-count-target]');
  if (!counters.length) return;

  const animateCount = (el) => {
    const target = parseFloat(el.dataset.countTarget);
    if (isNaN(target)) return;

    const duration = 1500; // ms
    const startTime = performance.now();

    const step = (now) => {
      const progress = Math.min((now - startTime) / duration, 1);
      const value = Math.floor(progress * target);
      el.textContent = value.toString();

      if (progress < 1) {
        requestAnimationFrame(step);
      } else {
        el.textContent = target.toString(); // snap to final
      }
    };

    requestAnimationFrame(step);
  };

  let hasRun = false;
  const aboutSection = document.getElementById('about');

  if (!aboutSection) {
    // fallback: just run immediately
    counters.forEach(animateCount);
    return;
  }

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting && !hasRun) {
        hasRun = true;
        counters.forEach(animateCount);
        observer.disconnect();
      }
    });
  }, { threshold: 0.3 });

  observer.observe(aboutSection);
});

