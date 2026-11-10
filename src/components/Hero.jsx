import { useLanguage } from '../i18n/useLanguage'
import './Hero.css'

export default function Hero() {
  const { t, lang } = useLanguage()
  const h = t.hero

  return (
    <section id="hero" className="hero-signal">
      <div className="hero-plane" aria-hidden="true">
        <img
          src="/profile/marcello-guida.jpg"
          alt=""
          className="hero-plane-img"
          width={1600}
          height={2000}
          decoding="async"
        />
        <div className="hero-plane-scrim" />
        <div className="voice-field" />
      </div>

      <div className="hero-frame">
        <p className="hero-availability" data-intro data-delay="0">
          <span className="hero-availability-dot" aria-hidden="true" />
          {h.badge}
        </p>

        <h1 className="hero-brand" data-intro data-delay="0.05">
          Marcello
          <br />
          Guida
        </h1>

        <p className="hero-line" data-intro data-delay="0.12">
          {h.subtitle}
        </p>

        <div className="hero-actions" data-intro data-delay="0.18">
          <a href="#projects" className="btn-signal">
            <span className="btn-signal__fill" aria-hidden="true" />
            <span className="btn-signal__label">{h.viewWork}</span>
          </a>
          <a href="#pricing" className="btn-signal is-ghost">
            <span className="btn-signal__fill" aria-hidden="true" />
            <span className="btn-signal__label">{h.viewPricing}</span>
          </a>
        </div>

        <div className="hero-corner" data-intro data-delay="0.22">
          <div className="signal-meter" aria-hidden="true">
            <span>{lang === 'it' ? 'segnale' : 'signal'}</span>
            <span className="signal-meter__bar">
              <span className="signal-meter__fill" />
            </span>
          </div>
          <p className="hero-role">{h.codeRole}</p>
        </div>
      </div>
    </section>
  )
}
