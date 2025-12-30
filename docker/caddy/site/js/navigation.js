// Mobile menu toggle
document.addEventListener("DOMContentLoaded", () => {
  const menuBtn = document.getElementById("menuBtn");
  const mobileMenu = document.getElementById("mobileMenu");

  if (!menuBtn || !mobileMenu) return;

  // Toggle menu when clicking the burger
  menuBtn.addEventListener("click", (e) => {
    e.stopPropagation();
    mobileMenu.classList.toggle("hidden");
  });

  // Close menu when clicking a link inside it
  mobileMenu.querySelectorAll("a").forEach(link => {
    link.addEventListener("click", () => {
      mobileMenu.classList.add("hidden");
    });
  });

  // Close menu when clicking anywhere outside
  document.addEventListener("click", (e) => {
    if (mobileMenu.classList.contains("hidden")) return;

    const clickedInsideMenu = mobileMenu.contains(e.target);
    const clickedToggle = menuBtn.contains(e.target);

    if (!clickedInsideMenu && !clickedToggle) {
      mobileMenu.classList.add("hidden");
    }
  });
});

// Scroll indicator
document.addEventListener('DOMContentLoaded', () => {
  const scrollIndicator = document.getElementById('scrollIndicator');
  const aboutSection = document.getElementById('about');

  if (!scrollIndicator || !aboutSection) return;

  // Click → scroll to About
  scrollIndicator.addEventListener('click', () => {
    aboutSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
  });

  // Hide as soon as the user scrolls slightly
  const hideAfterFirstScroll = () => {
    if (window.scrollY > 40) {
      scrollIndicator.classList.add('scroll-chevrons--hidden');
    } else {
      scrollIndicator.classList.remove('scroll-chevrons--hidden');
    }
  };

  window.addEventListener('scroll', hideAfterFirstScroll);
  hideAfterFirstScroll(); // run on load
});

