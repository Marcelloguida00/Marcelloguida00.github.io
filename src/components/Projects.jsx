import './Projects.css'

export default function Projects() {
  const projects = [
    {
      title: 'World of Fables',
      subtitle: 'Lumi',
      description:
        'An immersive iPad experience that turns classic fables into interactive games, built to teach logical sequencing to children with a deep focus on accessibility — removing barriers so every young mind can play.',
      tags: ['Swift', 'iPadOS', 'Accessibility', 'Game Design'],
      link: '/world-of-fables/index.html',
      status: 'Swift Student Challenge 2026',
    },
  ]

  return (
    <section id="projects" className="projects-wow reveal">
      <div className="container">
        <div className="section-header-wow">
          <div className="file-tab" style={{ '--dot-color': 'var(--accent-color)', marginBottom: 0 }}>
            <span className="dot"></span> Projects.swift
          </div>
          <a
            href="https://github.com/Marcelloguida00"
            target="_blank"
            rel="noopener noreferrer"
            className="view-all-btn"
          >
            View GitHub <span>→</span>
          </a>
        </div>

        <div className="projects-grid-wow">
          {projects.map((project, idx) => (
            <a href={project.link} className="project-card-wow" key={idx}>
              <div className="project-card-top">
                <div className="project-window">
                  <div className="editor-dots small">
                    <span className="dot red"></span>
                    <span className="dot yellow"></span>
                    <span className="dot green"></span>
                  </div>
                  <span className="project-status">{project.status}</span>
                </div>
                <div className="project-mark">{project.title.charAt(0)}</div>
              </div>

              <div className="project-content-wow">
                <div className="project-tags-wow">
                  {project.tags.map((tag, tagIdx) => (
                    <span key={tagIdx} className="project-tag-glass">{tag}</span>
                  ))}
                </div>
                <h3 className="project-title-wow">
                  {project.title}
                  <span className="project-subtitle"> · {project.subtitle}</span>
                </h3>
                <p className="project-description-wow">{project.description}</p>
                <span className="project-link-wow">
                  Explore project <span className="arrow">↗</span>
                </span>
              </div>
            </a>
          ))}
        </div>
      </div>
    </section>
  )
}
