import SectionTab from './SectionTab'
import { useLanguage } from '../i18n/useLanguage'
import './About.css'

export default function About() {
  const { t } = useLanguage()
  const a = t.about

  return (
    <section id="about" className="about-wow reveal">
      <div className="container">
        <SectionTab
          file="About.swift"
          comment={a.comment}
          dotColor="var(--accent-secondary)"
        />

        <div className="about-grid-wow">
          <div className="about-main">
            <h2 className="about-greeting">
              {a.greeting.split('\n').map((line, i) => (
                <span key={i}>
                  {i > 0 && <br />}
                  {line}
                </span>
              ))}
            </h2>
            <p className="about-text">{a.p1}</p>
            <p className="about-text">{a.p2}</p>
          </div>

          <div className="about-facts">
            {a.facts.map((fact) => (
              <div className="fact-row" key={fact.label}>
                <span className="fact-label">{fact.label}</span>
                <span className="fact-value">{fact.value}</span>
              </div>
            ))}
            <div className="fact-highlight">
              <span className="fact-highlight-icon" aria-hidden="true">
                ★
              </span>
              <span>{a.awardHighlight}</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
