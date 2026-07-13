import SectionTab from './SectionTab'
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
      marker: 'work',
      current: true,
    },
    {
      title: 'Swift Student Challenge 2026',
      company: 'Apple · WWDC26',
      location: 'Remote',
      period: 'Feb 2026',
      description:
        'Selected as a winner with an interactive Swift playground built around accessibility and playful learning — shipped as a polished, App-Store-ready experience.',
      highlights: ['Swift Playgrounds', 'Accessibility', 'SwiftUI', 'Winner'],
      marker: 'award',
      current: false,
    },
    {
      title: 'B.Sc. Computer Science',
      company: 'University of Salerno (UNISA)',
      location: 'Fisciano, Italy',
      period: '2023 – Present',
      description:
        'Studying algorithms, software engineering, and machine learning while applying what I learn directly to native iOS projects and product design.',
      highlights: ['Algorithms', 'Software Engineering', 'Machine Learning', 'Databases'],
      marker: 'education',
      current: false,
    },
  ]

  return (
    <section id="experience" className="experience-wow reveal">
      <div className="container">
        <SectionTab
          file="Timeline.md"
          comment="// where I've been"
          dotColor="var(--accent-green)"
        />

        <div className="timeline-wow">
          {experiences.map((exp, idx) => (
            <div
              key={idx}
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
