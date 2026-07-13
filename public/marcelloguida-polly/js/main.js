// ============================================================
// Polly — shared front-end behaviour (no build step, vanilla JS)
// ============================================================

document.addEventListener('DOMContentLoaded', () => {

  /* ---------- Mobile nav toggle ---------- */
  const navToggle = document.querySelector('.nav-toggle');
  const mobileMenu = document.querySelector('.mobile-menu');
  if (navToggle && mobileMenu) {
    navToggle.addEventListener('click', () => {
      mobileMenu.classList.toggle('open');
      const isOpen = mobileMenu.classList.contains('open');
      navToggle.setAttribute('aria-expanded', String(isOpen));
    });
    mobileMenu.querySelectorAll('a').forEach(a =>
      a.addEventListener('click', () => mobileMenu.classList.remove('open'))
    );
  }

  /* ---------- Scroll reveal ---------- */
  const revealEls = document.querySelectorAll('.reveal');
  if ('IntersectionObserver' in window && revealEls.length) {
    const io = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('in');
          io.unobserve(entry.target);
        }
      });
    }, { threshold: 0.15 });
    revealEls.forEach(el => io.observe(el));
  } else {
    revealEls.forEach(el => el.classList.add('in'));
  }

  /* ---------- FAQ accordion ---------- */
  document.querySelectorAll('.faq-item').forEach(item => {
    const q = item.querySelector('.faq-q');
    const a = item.querySelector('.faq-a');
    if (!q || !a) return;
    q.setAttribute('aria-expanded', 'false');
    q.addEventListener('click', () => {
      const isOpen = item.classList.contains('open');
      // Close siblings within the same faq list for a tidy accordion
      const list = item.parentElement;
      if (list) {
        list.querySelectorAll('.faq-item.open').forEach(openItem => {
          if (openItem !== item) {
            openItem.classList.remove('open');
            openItem.querySelector('.faq-a').style.maxHeight = null;
            openItem.querySelector('.faq-q').setAttribute('aria-expanded', 'false');
          }
        });
      }
      item.classList.toggle('open', !isOpen);
      q.setAttribute('aria-expanded', String(!isOpen));
      a.style.maxHeight = !isOpen ? a.scrollHeight + 'px' : null;
    });
  });

  /* ---------- Animated stat meters (home page signature element) ---------- */
  const meters = document.querySelectorAll('.meter-fill');
  if (meters.length) {
    if ('IntersectionObserver' in window) {
      const mio = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            const target = entry.target.dataset.value || '0';
            entry.target.style.width = target + '%';
            mio.unobserve(entry.target);
          }
        });
      }, { threshold: 0.4 });
      meters.forEach(m => mio.observe(m));
    } else {
      meters.forEach(m => { m.style.width = (m.dataset.value || '0') + '%'; });
    }
  }

  /* ---------- Support contact form (opens email client) ---------- */
  const supportForm = document.getElementById('support-form');
  if (supportForm) {
    supportForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const data = new FormData(supportForm);
      const name = data.get('name') || '';
      const email = data.get('email') || '';
      const topic = data.get('topic') || 'other';
      const message = data.get('message') || '';
      const subject = encodeURIComponent(`Polly Support — ${topic}`);
      const body = encodeURIComponent(
        `Name: ${name}\nReply-to: ${email}\nTopic: ${topic}\n\n${message}`
      );
      window.location.href = `mailto:mguida2604@gmail.com?subject=${subject}&body=${body}`;
    });
  }

  /* ---------- Data management actions (email requests) ---------- */
  const mailAction = (buttonId, subject) => {
    const btn = document.getElementById(buttonId);
    if (!btn) return;
    btn.addEventListener('click', () => {
      window.location.href = `mailto:mguida2604@gmail.com?subject=${encodeURIComponent(subject)}`;
    });
  };

  mailAction('btn-export', 'Polly — Data export request');
  mailAction('btn-edit', 'Polly — Data edit request');
  mailAction('btn-consent', 'Polly — Consent management request');

  /* ---------- Delete account confirmation modal ---------- */
  const deleteBtn = document.getElementById('btn-delete');
  const modal = document.getElementById('delete-modal');
  const modalCancel = document.getElementById('delete-cancel');
  const modalConfirm = document.getElementById('delete-confirm');
  if (deleteBtn && modal) {
    deleteBtn.addEventListener('click', () => modal.classList.add('open'));
    modalCancel && modalCancel.addEventListener('click', () => modal.classList.remove('open'));
    modal.addEventListener('click', (e) => { if (e.target === modal) modal.classList.remove('open'); });
    modalConfirm && modalConfirm.addEventListener('click', () => {
      modal.classList.remove('open');
      window.location.href = 'mailto:mguida2604@gmail.com?subject=' + encodeURIComponent('Polly — Account deletion request');
    });
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') modal.classList.remove('open');
    });
  }

  /* ---------- Footer year ---------- */
  document.querySelectorAll('.js-year').forEach(el => {
    el.textContent = new Date().getFullYear();
  });

});
