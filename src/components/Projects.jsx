import SectionTab from './SectionTab'
import { useLanguage } from '../i18n/useLanguage'
import './Projects.css'

export default function Projects() {
  const { t } = useLanguage()
  const p = t.projects

  return (
    <section id="projects" className="projects-wow reveal">
      <div className="container">
        <div className="section-header-wow">
          <SectionTab
            file="Projects.swift"
            comment={p.comment}
            dotColor="var(--accent-color)"
          />
          <a
            href="https://github.com/Marcelloguida00"
            target="_blank"
            rel="noopener noreferrer"
            className="view-all-btn"
          >
            {p.viewGithub} <span>→</span>
          </a>
        </div>

        <div className="projects-grid-wow">
          {p.items.map((project) => (
            <a href={project.link} className="project-card-wow" key={project.title}>
              <div className="project-card-top">
                <img
                  src={project.cover}
                  alt={`${project.title} preview`}
                  className="project-cover-img"
                />
                <div className="project-cover-scrim"></div>
                <div className="project-window">
                  <div className="editor-dots small">
                    <span className="dot red"></span>
                    <span className="dot yellow"></span>
                    <span className="dot green"></span>
                  </div>
                </div>
              </div>

              <div className="project-content-wow">
                <div className="project-tags-wow">
                  {project.tags.map((tag) => (
                    <span key={tag} className="project-tag-glass">
                      {tag}
                    </span>
                  ))}
                </div>
                <h3 className="project-title-wow">
                  {project.title}
                  <span className="project-subtitle"> · {project.subtitle}</span>
                </h3>
                <p className="project-description-wow">{project.description}</p>
                <span className="project-link-wow">
                  {p.explore} <span className="arrow">↗</span>
                </span>
              </div>
            </a>
          ))}
        </div>
      </div>
    </section>
  )
}
