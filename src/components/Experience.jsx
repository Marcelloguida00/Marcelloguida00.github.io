import './Experience.css'

export default function Experience() {
  const experiences = [
    {
      title: 'Apple Developer Academy',
      company: 'Federico II University × Apple',
      location: 'Naples, Italy',
      period: 'Sep 2025 – Jun 2026',
      description:
        'Selective program focused on iOS development, product design, and entrepreneurial thinking. Building and shipping iOS apps with Swift and Xcode inside Agile-style team sprints.',
      highlights: ['iOS Development', 'Product Design', 'Swift', 'Xcode', 'Team Collaboration'],
      current: true,
    },
  ]

  return (
    <section id="experience" className="experience-wow reveal">
      <div className="container">
        <div className="file-tab" style={{ '--dot-color': 'var(--accent-green)' }}>
          <span className="dot"></span> Experience.log
        </div>

        <div className="timeline-wow">
          {experiences.map((exp, idx) => (
            <div key={idx} className={`timeline-item-wow ${exp.current ? 'current' : ''}`}>
              <div className="timeline-marker-glass">
                {exp.current && <span className="marker-pulse"></span>}
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
                  {exp.highlights.map((tag, tagIdx) => (
                    <span key={tagIdx} className="glass-tag">{tag}</span>
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
