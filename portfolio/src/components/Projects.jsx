import './Projects.css'

export default function Projects() {
  const projects = [
    {
      title: 'Swift Student Challenge Submission',
      description: 'Selected as one of ~350 winners globally. Developed an innovative iOS application showcasing Swift expertise and creative problem-solving.',
      tags: ['Swift', 'iOS', 'Xcode', 'Award-Winning'],
      link: '#'
    },
    {
      title: 'iOS Apps (Apple Developer Academy)',
      description: 'Built and shipped multiple iOS applications during the Apple Developer Academy program. Focused on user experience, performance, and elegant design.',
      tags: ['Swift', 'iOS', 'UIKit', 'Product Design'],
      link: '#'
    },
    {
      title: 'Algorithms & Data Structures Portfolio',
      description: 'Core implementations of fundamental algorithms and data structures in Python. Optimized solutions with focus on time/space complexity.',
      tags: ['Python', 'Algorithms', 'Data Structures'],
      link: '#'
    },
    {
      title: 'Database Design Project',
      description: 'Designed and implemented relational database schema with complex queries. Part of coursework at Università Guglielmo Marconi.',
      tags: ['Database', 'SQL', 'Design'],
      link: '#'
    }
  ]

  return (
    <section id="projects" className="projects">
      <div className="container">
        <h2 className="section-title">Featured Projects</h2>

        <div className="projects-grid">
          {projects.map((project, idx) => (
            <div key={idx} className="project-card">
              <div className="project-header">
                <h3 className="project-title">{project.title}</h3>
              </div>
              <p className="project-description">{project.description}</p>
              <div className="project-tags">
                {project.tags.map((tag, i) => (
                  <span key={i} className="project-tag">{tag}</span>
                ))}
              </div>
              <a href={project.link} className="project-link">
                Learn more →
              </a>
            </div>
          ))}
        </div>

        <div className="projects-cta">
          <p>Check out more projects on GitHub</p>
          <a href="https://github.com/Marcelloguida00" target="_blank" rel="noopener noreferrer" className="btn btn-secondary">
            Visit GitHub
          </a>
        </div>
      </div>
    </section>
  )
}
