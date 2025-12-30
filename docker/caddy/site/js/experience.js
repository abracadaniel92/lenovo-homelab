// Experience tabs functionality
document.addEventListener('DOMContentLoaded', () => {
  const tabs = document.querySelectorAll('.exp-tab');
  const panels = document.querySelectorAll('.exp-panel');

  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      const company = tab.getAttribute('data-company');

      // reset all tabs & panels
      tabs.forEach(t => {
        t.classList.remove(
          'active',
          'text-[#64ffda]',
          'bg-[#112240]',
          'md:border-l-[#64ffda]'
        );
      });
      panels.forEach(p => {
        p.classList.add('hidden');
        p.classList.remove('active');
      });

      // activate clicked tab
      tab.classList.add(
        'active',
        'text-[#64ffda]',
        'bg-[#112240]',
        'md:border-l-[#64ffda]'
      );

      const activePanel = document.getElementById(`panel-${company}`);
      if (activePanel) {
        activePanel.classList.remove('hidden');
        activePanel.classList.add('active');
      }
    });
  });

  // default active tab on load
  const defaultTab = document.querySelector('.exp-tab[data-company="intertec"]');
  if (defaultTab) {
    defaultTab.classList.add(
      'active',
      'text-[#64ffda]',
      'bg-[#112240]',
      'md:border-l-[#64ffda]'
    );
  }
});

// Experience navigation (prev/next)
function activateCompany(slug) {
  const tab = document.querySelector('.exp-tab[data-company="' + slug + '"]');
  const panel = document.getElementById('panel-' + slug);

  if (!tab || !panel) return;

  // switch active tab - remove all active states
  document.querySelectorAll('.exp-tab').forEach(t => {
    t.classList.remove(
      'active',
      'text-[#64ffda]',
      'bg-[#112240]',
      'md:border-l-[#64ffda]'
    );
  });
  
  // add active state to selected tab
  tab.classList.add(
    'active',
    'text-[#64ffda]',
    'bg-[#112240]',
    'md:border-l-[#64ffda]'
  );

  // switch active panel
  document.querySelectorAll('.exp-panel').forEach(p => {
    p.classList.remove('active');
    p.classList.add('hidden');
  });
  panel.classList.add('active');
  panel.classList.remove('hidden');

  // On mobile, jump back to the top of Experience
  if (window.innerWidth < 768) {
    const expSection = document.getElementById('experience');
    if (expSection) {
      expSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  }
}

document.addEventListener('DOMContentLoaded', function () {
  document.querySelectorAll('.exp-nav-btn').forEach(btn => {
    btn.addEventListener('click', function () {
      const next = this.dataset.next;
      const prev = this.dataset.prev;

      if (next) activateCompany(next);
      if (prev) activateCompany(prev);
    });
  });
});

