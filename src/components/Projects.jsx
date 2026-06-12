import './Projects.css'

export default function Projects() {
  const projects = [
    {
      title: 'World of Fables (Lumi)',
      description: 'An immersive iPad experience that transforms classic fables into interactive games. Designed to teach logical sequencing to children with a deep focus on accessibility, removing barriers to stimulate young minds.',
      tags: ['Swift', 'iPadOS', 'Accessibility', 'Game Design'],
      link: '/world-of-fables/index.html'
    }
  ]

  return (
    <section id="projects" className="projects-wow">
      <div className="container">
        <div className="section-header-wow">
          <h2 className="section-title">Selected Work</h2>
          <a href="https://github.com/Marcelloguida00" target="_blank" rel="noopener noreferrer" className="view-all-btn">
            View GitHub <span>→</span>
          </a>
        </div>

        <div className="projects-grid-wow">
          {projects.map((project, idx) => (
            <div key={idx} className="project-card-wow">
              <div className="project-image-glass">
                <span className="project-image-text">{project.title.charAt(0)}</span>
              </div>
              <div className="project-content-wow">
                <div className="project-tags-wow">
                  {project.tags.map((tag, tagIdx) => (
                    <span key={tagIdx} className="project-tag-glass">{tag}</span>
                  ))}
                </div>
                <h3 className="project-title-wow">{project.title}</h3>
                <p className="project-description-wow">{project.description}</p>
                <a href={project.link} className="project-link-wow">
                  Explore Project <span>↗</span>
                </a>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
