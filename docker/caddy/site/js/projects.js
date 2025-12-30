// Accordion functionality
document.querySelectorAll(".accordion-btn").forEach((button) => {
  const icon = button.querySelector(".accordion-icon");
  const targetSelector = button.dataset.accordionTarget;
  const target = targetSelector ? document.querySelector(targetSelector) : null;
  if (!target) return; // safety

  button.addEventListener("click", (event) => {
    event.preventDefault();

    const isOpen = !target.classList.contains("hidden");

    // Close all accordions (projects & case studies)
    document.querySelectorAll(".accordion-btn").forEach((b) => {
      const sel = b.dataset.accordionTarget;
      if (!sel) return;
      const panel = document.querySelector(sel);
      const ic = b.querySelector(".accordion-icon");
      if (panel) {
        panel.classList.add("hidden");
        panel.style.maxHeight = null; // clear any inline styles
      }
      b.classList.remove("active");
      if (ic) ic.textContent = "+";
    });

    // If the clicked one was closed, open it
    if (!isOpen) {
      target.classList.remove("hidden");
      target.style.maxHeight = ""; // let CSS / grid handle height
      button.classList.add("active");
      if (icon) icon.textContent = "−";

      // scroll so the company card is nicely in view
      const yOffset = -120;
      const rect = button.getBoundingClientRect();
      const y = rect.top + window.pageYOffset + yOffset;
      window.scrollTo({ top: y, behavior: "smooth" });
    }
  });
});

// Project links that open accordions
document.addEventListener('DOMContentLoaded', () => {
  const projectLinks = document.querySelectorAll('[data-open-accordion]');

  projectLinks.forEach(link => {
    link.addEventListener('click', (e) => {
      e.preventDefault();

      const targetSectionSelector = link.getAttribute('href');           // e.g. "#projects-arcadia"
      const accordionSelector = link.dataset.openAccordion;             // e.g. "#ananas-mk"

      const sectionEl = document.querySelector(targetSectionSelector);
      const accordionBtn = document.querySelector(
        `.accordion-btn[data-accordion-target="${accordionSelector}"]`
      );

      // Check if the target section is hidden (Ananas or Vox)
      const isHidden = sectionEl && sectionEl.classList.contains('projects-more-content') && !sectionEl.classList.contains('show');
      
      // If it's hidden, expand "View more" first
      if (isHidden) {
        const viewMoreBtn = document.getElementById('projectsViewMore');
        const moreContent = document.querySelectorAll('.projects-more-content');
        
        if (viewMoreBtn && moreContent.length > 0) {
          // Expand all hidden content
          moreContent.forEach(item => {
            item.classList.add('show');
          });
          
          // Show dividers and spacers
          document.querySelectorAll('.projects-more-content-divider, .projects-more-content-spacer').forEach(el => {
            el.classList.add('show');
          });
          
          // Hide "View more" button
          viewMoreBtn.classList.add('hidden');
          
          // Wait for expansion, then scroll and open accordion
          setTimeout(() => {
            // Smooth scroll to the projects row
            if (sectionEl) {
              const yOffset = -120;
              const y = sectionEl.getBoundingClientRect().top + window.pageYOffset + yOffset;
              window.scrollTo({ top: y, behavior: 'smooth' });
            }

            // Open the matching accordion after scroll
            if (accordionBtn) {
              setTimeout(() => {
                accordionBtn.click(); // uses your existing accordion logic
              }, 300);
            }
          }, 100);
        }
      } else {
        // Section is already visible, just scroll and open accordion
        // Smooth scroll to the projects row
        if (sectionEl) {
          const yOffset = -120; // tweak if needed
          const y = sectionEl.getBoundingClientRect().top + window.pageYOffset + yOffset;
          window.scrollTo({ top: y, behavior: 'smooth' });
        }

        // Open the matching accordion after a short delay
        if (accordionBtn) {
          setTimeout(() => {
            accordionBtn.click(); // uses your existing accordion logic
          }, 300);
        }
      }
    });
  });

  // "View experience" buttons in projects section
  const expViewButtons = document.querySelectorAll('a[data-company][href="#experience"]');
  
  expViewButtons.forEach(button => {
    button.addEventListener('click', (e) => {
      e.preventDefault();
      
      const company = button.dataset.company; // e.g. "arcadia", "tsd", "ananas", "vox"
      const experienceSection = document.getElementById('experience');
      
      if (!experienceSection || !company) return;
      
      // Scroll to experience section
      const yOffset = -120;
      const y = experienceSection.getBoundingClientRect().top + window.pageYOffset + yOffset;
      window.scrollTo({ top: y, behavior: 'smooth' });
      
      // Activate the correct company tab after scroll
      setTimeout(() => {
        // Use the tab click to ensure all styling is applied
        const tab = document.querySelector(`.exp-tab[data-company="${company}"]`);
        if (tab) {
          tab.click();
        } else if (typeof activateCompany === 'function') {
          // Fallback to function if tab not found
          activateCompany(company);
        }
      }, 300);
    });
  });
});

// View More/Less functionality for projects
document.addEventListener('DOMContentLoaded', () => {
  const viewMoreBtn = document.getElementById('projectsViewMore');
  const viewLessBtn = document.getElementById('projectsViewLess');
  const moreContent = document.querySelectorAll('.projects-more-content');
  
  // View More button - only functionality, no view less
  if (viewMoreBtn && moreContent.length > 0) {
    viewMoreBtn.addEventListener('click', () => {
      moreContent.forEach(item => {
        item.classList.add('show');
      });
      
      // Show dividers and spacers
      document.querySelectorAll('.projects-more-content-divider, .projects-more-content-spacer').forEach(el => {
        el.classList.add('show');
      });
      
      // Transform the divider into a regular line when clicked
      viewMoreBtn.classList.add('hidden');
    });
  }
  
  // View More functionality for personal projects
  const personalViewMoreBtn = document.getElementById('personalProjectsViewMore');
  const personalMoreContent = document.querySelectorAll('.personal-project-more-content');
  
  if (personalViewMoreBtn && personalMoreContent.length > 0) {
    personalViewMoreBtn.addEventListener('click', () => {
      personalMoreContent.forEach(item => {
        item.classList.add('show');
      });
      
      // Hide the button after showing content
      personalViewMoreBtn.classList.add('hidden');
    });
  }
});

