import { useEffect, useState } from 'react'
import './App.css'
import './engine/engine.css'
import Hero from './components/Hero'
import About from './components/About'
import Skills from './components/Skills'
import Experience from './components/Experience'
import Projects from './components/Projects'
import Pricing from './components/Pricing'
import Contact from './components/Contact'
import Navigation from './components/Navigation'
import SeoHead from './components/SeoHead'
import { LanguageProvider } from './i18n/LanguageContext'
import { useLanguage } from './i18n/useLanguage'
import { boot, teardown } from './engine'

function AppShell() {
  const [scrolled, setScrolled] = useState(false)
  const { t, lang } = useLanguage()

  useEffect(() => {
    let alive = true
    boot().catch(() => {
      document.documentElement.classList.add('is-loaded')
    })
    const onScroll = () => {
      if (!alive) return
      setScrolled(window.scrollY > 40)
    }
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => {
      alive = false
      window.removeEventListener('scroll', onScroll)
      teardown()
    }
  }, [])

  return (
    <div className="app">
      <a className="skip-link" href="#main">
        {lang === 'it' ? 'Vai al contenuto' : 'Skip to content'}
      </a>

      <div id="loader" role="status" aria-label={lang === 'it' ? 'Caricamento' : 'Loading'}>
        <div className="loader-brand">Marcello Guida</div>
        <div className="loader-meta">
          <span data-loader-out>{lang === 'it' ? 'segnale' : 'signal'}</span>
          <span data-loader-out data-loader-count>
            000
          </span>
        </div>
        <div className="loader-track" aria-hidden="true">
          <span data-loader-bar className="loader-bar" />
        </div>
      </div>

      <SeoHead />
      <Navigation scrolled={scrolled} />
      <main id="main" tabIndex={-1}>
        <Hero />
        <About />
        <Experience />
        <Skills />
        <Projects />
        <Pricing />
        <Contact />
      </main>
      <footer className="footer">
        <div className="footer-content">
          <p data-reveal="up">{t.footer.copy}</p>
          <p className="footer-coords" data-reveal="fade">
            40.8518° N · 14.2681° E · Napoli
          </p>
          <div className="footer-links">
            <a href={lang === 'it' ? '/servizi/' : '/services/'}>
              {lang === 'it' ? 'Servizi' : 'Services'}
            </a>
            <a
              href="https://github.com/Marcelloguida00"
              target="_blank"
              rel="noopener noreferrer"
            >
              GitHub
            </a>
            <a
              href="https://linkedin.com/in/marcelloguida00"
              target="_blank"
              rel="noopener noreferrer"
            >
              LinkedIn
            </a>
            <a href="mailto:mguida2604@gmail.com">Email</a>
          </div>
        </div>
      </footer>
    </div>
  )
}

function App() {
  return (
    <LanguageProvider>
      <AppShell />
    </LanguageProvider>
  )
}

export default App
