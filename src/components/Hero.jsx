import { useLanguage } from '../i18n/useLanguage'
import './Hero.css'

export default function Hero() {
  const { t } = useLanguage()
  const h = t.hero

  const CODE_LINES = [
    { indent: 0, text: 'struct Marcello: Developer {' },
    { indent: 1, text: `var role = "${h.codeRole}"` },
    { indent: 1, text: 'var focus = ["Swift", "UIKit", "Accessibility"]' },
    { indent: 1, text: 'var status: Availability = .openToWork' },
    { indent: 0, text: '}' },
  ]

  const SECTION_MARKERS = [
    { href: '#about', label: h.markers.about },
    { href: '#experience', label: h.markers.experience },
    { href: '#skills', label: h.markers.skills },
    { href: '#projects', label: h.markers.work },
    { href: '#pricing', label: h.markers.pricing },
    { href: '#contact', label: h.markers.contact },
  ]

  return (
    <section id="hero" className="hero-wow">
      <div className="hero-glow-orb"></div>
      <div className="hero-grid-fade"></div>

      <div className="hero-content-wow">
        <div className="hero-copy">
          <div className="hero-badge">
            <span className="live-dot"></span>
            {h.badge}
          </div>

          <h1 className="hero-title-wow">
            {h.titleBefore} <span className="text-accent">{h.titleAccent}</span>
            <br />
            {h.titleAfter}
          </h1>

          <p className="hero-subtitle-wow">{h.subtitle}</p>

          <div className="hero-actions">
            <a href="#projects" className="btn btn-primary">{h.viewWork}</a>
            <a href="#contact" className="btn btn-secondary">{h.getInTouch}</a>
          </div>

          <nav className="hero-markers" aria-label="Jump to section">
            {SECTION_MARKERS.map((item) => (
              <a key={item.href} href={item.href} className="hero-marker">
                <span className="hero-marker-dot" aria-hidden="true"></span>
                {item.label}
              </a>
            ))}
          </nav>
        </div>

        <div className="hero-visual">
          <div className="hero-photo-wrap">
            <img
              src="/profile/marcello-guida.jpg"
              alt={h.photoAlt}
              className="hero-photo"
              width={420}
              height={560}
              loading="eager"
              decoding="async"
            />
          </div>

          <div className="hero-editor">
            <div className="editor-titlebar">
              <div className="editor-dots">
                <span className="dot red"></span>
                <span className="dot yellow"></span>
                <span className="dot green"></span>
              </div>
              <span className="editor-filename">Marcello.swift</span>
            </div>
            <div className="editor-body">
              {CODE_LINES.map((lineObj, idx) => {
                const isLast = idx === CODE_LINES.length - 1
                return (
                  <div
                    className="editor-line"
                    key={`${lineObj.text}-${idx}`}
                    style={{ animationDelay: `${idx * 120}ms` }}
                  >
                    <span className="line-number">{idx + 1}</span>
                    <span
                      className="line-code"
                      style={{ paddingLeft: `${lineObj.indent * 20}px` }}
                    >
                      {lineObj.text}
                      {isLast && <span className="type-cursor" aria-hidden="true"></span>}
                    </span>
                  </div>
                )
              })}
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
