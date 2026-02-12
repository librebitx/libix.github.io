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
  // Hero Section - Click Anywhere to Scroll
  // ========================================
  const hero = document.getElementById('hero');

  if (hero) {
    hero.addEventListener('click', function () {
      window.scrollTo({
        top: window.innerHeight,
        behavior: 'smooth'
      });
    });
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
  // Tag Filter
  // ========================================
  const tagFilter = document.getElementById('tag-filter');

  if (tagFilter) {
    const tagBtns = tagFilter.querySelectorAll('.tag-btn');
    const postItems = document.querySelectorAll('.post-item[data-tags]');

    tagBtns.forEach(function (btn) {
      btn.addEventListener('click', function () {
        // Update active state
        tagBtns.forEach(function (b) { b.classList.remove('active'); });
        btn.classList.add('active');

        const selectedTag = btn.dataset.tag;

        postItems.forEach(function (item) {
          if (selectedTag === 'all') {
            item.style.display = '';
          } else {
            const tags = (item.dataset.tags || '').split(',');
            item.style.display = tags.indexOf(selectedTag) !== -1 ? '' : 'none';
          }
        });
      });
    });
  }

  // ========================================
  // Back to Top Button
  // ========================================
  const backToTop = document.getElementById('back-to-top');

  if (backToTop) {
    window.addEventListener('scroll', function () {
      if (window.scrollY > 300) {
        backToTop.classList.add('visible');
      } else {
        backToTop.classList.remove('visible');
      }
    }, { passive: true });

    backToTop.addEventListener('click', function () {
      window.scrollTo({
        top: 0,
        behavior: 'smooth'
      });
    });
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
  // Handle #posts anchor - scroll past hero
  // ========================================
  if (window.location.hash === '#posts') {
    setTimeout(function () {
      window.scrollTo({
        top: window.innerHeight,
        behavior: 'smooth'
      });
    }, 100);
  }

  // ========================================
  // Sticky Post Header
  // ========================================
  const stickyHeader = document.querySelector('.sticky-post-header');
  if (stickyHeader && (document.querySelector('.post') || document.body.classList.contains('is-article-page'))) {
    window.addEventListener('scroll', function () {
      if (window.scrollY > 200) {
        stickyHeader.classList.add('visible');
      } else {
        stickyHeader.classList.remove('visible');
      }
    }, { passive: true });
  }

  // ========================================
  // Homepage Header Scroll Visibility
  // ========================================
  const header = document.querySelector('.header');
  if (header && document.body.classList.contains('is-home')) {
    window.addEventListener('scroll', function () {
      // Show header after scrolling past hero (~100vh)
      if (window.scrollY > window.innerHeight - 100) {
        header.classList.add('header-visible');
        document.body.classList.add('header-is-visible');
      } else {
        header.classList.remove('header-visible');
        document.body.classList.remove('header-is-visible');
      }
    }, { passive: true });
  }

  // ========================================
  // Image Lightbox
  // ========================================
  const lightbox = document.getElementById('lightbox');
  const lightboxImg = document.getElementById('lightbox-img');
  const lightboxCaption = document.getElementById('lightbox-caption');
  const postImages = document.querySelectorAll('.post-content img');

  if (lightbox && lightboxImg) {
    postImages.forEach(img => {
      img.addEventListener('click', function () {
        lightbox.style.display = 'block';
        lightboxImg.src = this.src;
        if (lightboxCaption) {
          lightboxCaption.textContent = this.alt || '';
        }
        document.body.style.overflow = 'hidden'; // Prevent scrolling
      });
    });

    const closeLightbox = function () {
      lightbox.style.display = 'none';
      document.body.style.overflow = ''; // Restore scrolling
    };

    const closeBtn = document.querySelector('.lightbox-close');
    if (closeBtn) {
      closeBtn.addEventListener('click', closeLightbox);
    }

    lightbox.addEventListener('click', function (e) {
      if (e.target === lightbox || e.target.className === 'lightbox-close') {
        closeLightbox();
      }
    });

    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && lightbox.style.display === 'block') {
        closeLightbox();
      }
    });
  }

})();
