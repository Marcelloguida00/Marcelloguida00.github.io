import './Experience.css'

export default function Experience() {
  const experiences = [
    {
      title: 'Apple Developer Academy',
      company: 'Federico II University × Apple',
      location: 'Napoli',
      period: 'Sep 2025 – Jun 2026',
      description: 'Selective program focused on iOS development, product design, and entrepreneurial thinking. Built and shipped iOS apps using Swift and Xcode in Agile-style team sprints.',
      highlights: ['iOS Development', 'Product Design', 'Swift', 'Xcode', 'Team Collaboration']
    }
  ]

  return (
    <section id="experience" className="experience-wow">
      <div className="container">
        <h2 className="section-title">Experience</h2>

        <div className="timeline-wow">
          {experiences.map((exp, idx) => (
            <div key={idx} className="timeline-item-wow">
              <div className="timeline-marker-glass"></div>
              <div className="timeline-content-glass">
                <div className="timeline-header-wow">
                  <div>
                    <h3 className="timeline-title-wow">{exp.title}</h3>
                    <p className="timeline-company-wow">{exp.company} • {exp.location}</p>
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
