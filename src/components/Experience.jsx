import SectionTab from './SectionTab'
import { useLanguage } from '../i18n/useLanguage'
import './Experience.css'

export default function Experience() {
  const { t } = useLanguage()
  const experiences = t.experience.items

  return (
    <section id="experience" className="experience-wow reveal">
      <div className="container">
        <SectionTab
          file="Timeline.md"
          comment={t.experience.comment}
          dotColor="var(--accent-green)"
        />

        <div className="timeline-wow">
          {experiences.map((exp, idx) => (
            <div
              key={`${exp.title}-${idx}`}
              className={`timeline-item-wow ${exp.current ? 'current' : ''}`}
            >
              <div
                className={`timeline-marker-glass marker-${exp.marker}`}
                aria-hidden="true"
              >
                {exp.current && <span className="marker-pulse"></span>}
                {!exp.current && exp.marker === 'award' && (
                  <span className="marker-icon">★</span>
                )}
                {!exp.current && exp.marker === 'education' && (
                  <span className="marker-icon">⌁</span>
                )}
              </div>
              <div className="timeline-content-glass">
                <div className="timeline-header-wow">
                  <div>
                    <h3 className="timeline-title-wow">{exp.title}</h3>
                    <p className="timeline-company-wow">
                      {exp.company} · {exp.location}
                    </p>
                  </div>
                  <span className="timeline-period-wow">{exp.period}</span>
                </div>
                <p className="timeline-description-wow">{exp.description}</p>
                <div className="timeline-tags-wow">
                  {exp.highlights.map((tag) => (
                    <span key={tag} className="glass-tag">
                      {tag}
                    </span>
                  ))}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
