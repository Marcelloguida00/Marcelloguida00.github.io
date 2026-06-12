import './Projects.css'

export default function Projects() {
  const projects = [
    {
      title: 'World of Fables (Lumi)',
      description: 'An interactive iPad app landing page showcasing Lumi, a journey through fables that teaches logical sequencing to children.',
      tags: 'HTML CSS JavaScript Web Design',
      link: '/world-of-fables/index.html'
    },
    {
      title: 'Swift Student Challenge',
      description: 'Selected as one of ~350 winners globally. Developed an innovative iOS application showcasing Swift expertise.',
      tags: 'Swift iOS Xcode Award-Winning',
      link: '#'
    },
    {
      title: 'iOS Apps (Apple Academy)',
      description: 'Built and shipped multiple iOS applications during the Apple Developer Academy program. Focused on UX.',
      tags: 'Swift iOS UIKit Product Design',
      link: '#'
    },
    {
      title: 'Algorithms & Data Structures',
      description: 'Core implementations of fundamental algorithms and data structures in Python. Optimized solutions.',
      tags: 'Python Algorithms Data Structures',
      link: '#'
    }
  ]

  return (
    <section id="projects" className="projects">
      <div className="container">
        <div className="section-header-row">
          <h2 className="section-title">projects</h2>
          <a href="https://github.com/Marcelloguida00" className="view-all-link">View all ↔</a>
        </div>

        <div className="projects-grid">
          {projects.map((project, idx) => (
            <div key={idx} className="project-card">
              <div className="project-image-placeholder">
                <div className="project-image-inner">
                  <span>Image Placeholder</span>
                </div>
              </div>
              <div className="project-tags">
                {project.tags}
              </div>
              <div className="project-content">
                <h3 className="project-title">{project.title}</h3>
                <p className="project-description">{project.description}</p>
                <a href={project.link} className="btn btn-secondary project-link">
                  Live ↔
                </a>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
