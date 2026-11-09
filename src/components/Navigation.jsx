import { useEffect, useState } from 'react'
import { useLanguage } from '../i18n/useLanguage'
import './Navigation.css'

export default function Navigation({ scrolled }) {
  const { t, lang, setLang } = useLanguage()
  const [active, setActive] = useState('hero')
  const [open, setOpen] = useState(false)

  const LINKS = [
    { href: '#hero', label: t.nav.home },
    { href: '#about', label: t.nav.about },
    { href: '#experience', label: t.nav.experience },
    { href: '#skills', label: t.nav.skills },
    { href: '#projects', label: t.nav.work },
    { href: '#pricing', label: t.nav.pricing },
    { href: '#contact', label: t.nav.contact },
  ]

  useEffect(() => {
    const sections = document.querySelectorAll('section[id]')
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) setActive(entry.target.id)
        })
      },
      { rootMargin: '-40% 0px -50% 0px', threshold: 0 }
    )
    sections.forEach((s) => observer.observe(s))
    return () => observer.disconnect()
  }, [])

  return (
    <header className={`navbar ${scrolled ? 'scrolled' : ''}`}>
      <div className="nav-container">
        <a href="#hero" className="nav-logo">
          <span className="prompt-glyph">&gt;_</span>
          marcello<span className="cursor-blink">|</span>
        </a>

        <nav className="nav-menu">
          {LINKS.map((link) => (
            <a
              key={link.href}
              href={link.href}
              className={active === link.href.slice(1) ? 'active' : ''}
            >
              {link.label}
            </a>
          ))}

          <div className="lang-switch" role="group" aria-label={t.nav.langLabel}>
            <button
              type="button"
              className={`lang-btn ${lang === 'it' ? 'is-active' : ''}`}
              onClick={() => setLang('it')}
              aria-pressed={lang === 'it'}
            >
              IT
            </button>
            <button
              type="button"
              className={`lang-btn ${lang === 'en' ? 'is-active' : ''}`}
              onClick={() => setLang('en')}
              aria-pressed={lang === 'en'}
            >
              EN
            </button>
          </div>

          <a href="#contact" className="nav-cta">
            {t.nav.cta}
          </a>
        </nav>

        <button
          className={`nav-toggle ${open ? 'open' : ''}`}
          aria-label={t.nav.toggleMenu}
          aria-expanded={open}
          onClick={() => setOpen((o) => !o)}
        >
          <span></span>
          <span></span>
          <span></span>
        </button>
      </div>

      <nav className={`nav-mobile ${open ? 'open' : ''}`}>
        {LINKS.map((link) => (
          <a key={link.href} href={link.href} onClick={() => setOpen(false)}>
            {link.label}
          </a>
        ))}
        <div className="lang-switch mobile" role="group" aria-label={t.nav.langLabel}>
          <button
            type="button"
            className={`lang-btn ${lang === 'it' ? 'is-active' : ''}`}
            onClick={() => setLang('it')}
            aria-pressed={lang === 'it'}
          >
            IT
          </button>
          <button
            type="button"
            className={`lang-btn ${lang === 'en' ? 'is-active' : ''}`}
            onClick={() => setLang('en')}
            aria-pressed={lang === 'en'}
          >
            EN
          </button>
        </div>
        <a href="#contact" className="nav-cta" onClick={() => setOpen(false)}>
          {t.nav.cta}
        </a>
      </nav>
    </header>
  )
}
