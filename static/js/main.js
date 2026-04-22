/**
 * Pure Theme - Minimal Style JavaScript
 */

(function () {
  'use strict';

  // ========================================
  // Theme Toggle (SVG icons)
  // ========================================
  const themeToggle = document.getElementById('theme-toggle');

  function updateThemeIcon() {
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    if (themeToggle) {
      const sun = themeToggle.querySelector('.icon-sun');
      const moon = themeToggle.querySelector('.icon-moon');
      if (sun && moon) {
        sun.style.display = isDark ? 'block' : 'none';
        moon.style.display = isDark ? 'none' : 'block';
      }
    }
  }

  function toggleTheme() {
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    document.documentElement.setAttribute('data-theme', isDark ? 'light' : 'dark');
    localStorage.setItem('theme', isDark ? 'light' : 'dark');
    updateThemeIcon();
  }

  if (themeToggle) {
    updateThemeIcon();
    themeToggle.addEventListener('click', toggleTheme);
  }



  // ========================================
  // TOC Active Highlight on Scroll
  // ========================================
  const tocContent = document.getElementById('toc-content');

  if (tocContent) {
    const tocLinks = tocContent.querySelectorAll('a');
    const headings = [];

    tocLinks.forEach(function (link) {
      const id = link.getAttribute('href');
      if (id && id.startsWith('#')) {
        const heading = document.querySelector(id);
        if (heading) {
          headings.push({ link: link, el: heading });
        }
      }
    });

    function updateActiveLink() {
      const topOffset = 150; // Threshold for activating link
      let activeLink = null;

      headings.forEach(heading => {
        const rect = heading.el.getBoundingClientRect();
        if (rect.top <= topOffset) {
          activeLink = heading.link;
        }
      });


      tocLinks.forEach(function (link) {
        link.classList.remove('active');
      });

      if (activeLink) {
        activeLink.classList.add('active');
      }
    }

    window.addEventListener('scroll', updateActiveLink, { passive: true });
    updateActiveLink();
  }





  // ========================================
  // Reading Progress Bar
  // ========================================
  const progressBar = document.getElementById('reading-progress');

  if (progressBar && document.querySelector('.post')) {
    window.addEventListener('scroll', function () {
      const scrollTop = window.scrollY;
      const docHeight = document.documentElement.scrollHeight - window.innerHeight;
      const progress = docHeight > 0 ? (scrollTop / docHeight) * 100 : 0;
      progressBar.style.width = progress + '%';
    }, { passive: true });
  }



  // ========================================
  // Image Lightbox
  // ========================================
  const lightbox = document.getElementById('lightbox');
  const lightboxImg = document.getElementById('lightbox-img');
  const lightboxCaption = document.getElementById('lightbox-caption');
  // Include grid images in selector
  const postImages = document.querySelectorAll('.post-content img, .post-image-grid img');

  if (lightbox && lightboxImg) {
    postImages.forEach(img => {
      img.addEventListener('click', function () {
        lightbox.classList.add('active'); // Use class for fade transition
        lightbox.style.display = 'flex';
        // Wait slightly for display:flex to apply before adding opacity
        requestAnimationFrame(() => {
          lightbox.classList.add('active');
        });

        lightboxImg.src = this.src;
        if (lightboxCaption) {
          lightboxCaption.textContent = this.alt || '';
        }
        document.body.style.overflow = 'hidden'; // Prevent scrolling
      });
    });

    const closeLightbox = function () {
      lightbox.classList.remove('active');
      setTimeout(() => {
        lightbox.style.display = 'none';
      }, 300); // Match transition duration
      document.body.style.overflow = ''; // Restore scrolling
    };

    const closeBtn = document.querySelector('.lightbox-close');
    if (closeBtn) {
      closeBtn.addEventListener('click', closeLightbox);
    }

    lightbox.addEventListener('click', function (e) {
      if (e.target === lightbox || e.target.className === 'lightbox-close' || e.target === lightboxImg) {
        closeLightbox();
      }
    });

    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') {
        closeLightbox();
      }
    });
  }

})();
