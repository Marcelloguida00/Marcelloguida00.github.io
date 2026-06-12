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
    },
    {
      title: 'Private STEM Tutor',
      company: 'Freelance',
      location: 'Remote',
      period: '2019 – 2023',
      description: 'Delivered 1-on-1 lessons in Mathematics, Physics, Computer Science, and Latin. Designed personalized study plans and consistently improved student grades.',
      highlights: ['Teaching', 'Python', 'Mathematics', 'Physics', 'Communication']
    },
    {
      title: 'Museum Guide',
      company: 'Museo Calatia',
      location: 'Maddaloni',
      period: 'Sep 2017 – Jun 2019',
      description: 'Led guided tours for school groups and general public, communicating historical content clearly and engagingly. Supported educational workshops.',
      highlights: ['Public Speaking', 'Communication', 'Leadership']
    }
  ]

  return (
    <section id="experience" className="experience">
      <div className="container">
        <h2 className="section-title">experience</h2>

        <div className="timeline">
          {experiences.map((exp, idx) => (
            <div key={idx} className="timeline-item">
              <div className="timeline-marker"></div>
              <div className="timeline-content">
                <div className="timeline-header">
                  <div>
                    <h3 className="timeline-title">{exp.title}</h3>
                    <p className="timeline-company">{exp.company} • {exp.location}</p>
                  </div>
                  <span className="timeline-period">[{exp.period}]</span>
                </div>
                <p className="timeline-description">{exp.description}</p>
                <div className="timeline-tags">
                  {exp.highlights.join('  ')}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
