import { useEffect, useState } from 'react'
import { useLanguage } from '../i18n/useLanguage'
import './Navigation.css'

function LangSwitch({ className = '', lang, setLang, label }) {
  return (
    <div className={`lang-switch ${className}`.trim()} role="group" aria-label={label}>
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
  )
}

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
          Marcello <span>Guida</span>
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

          <LangSwitch lang={lang} setLang={setLang} label={t.nav.langLabel} />

          <a href="#contact" className="nav-cta">
            {t.nav.cta}
          </a>
        </nav>

        <div className="nav-mobile-tools">
          <LangSwitch
            className="compact"
            lang={lang}
            setLang={setLang}
            label={t.nav.langLabel}
          />
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
      </div>

      <nav className={`nav-mobile ${open ? 'open' : ''}`}>
        {LINKS.map((link) => (
          <a key={link.href} href={link.href} onClick={() => setOpen(false)}>
            {link.label}
          </a>
        ))}
        <a href="#contact" className="nav-cta" onClick={() => setOpen(false)}>
          {t.nav.cta}
        </a>
      </nav>
    </header>
  )
}
