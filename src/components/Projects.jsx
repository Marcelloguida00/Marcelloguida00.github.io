import SectionTab from './SectionTab'
import './Projects.css'

export default function Projects() {
  const projects = [
    {
      title: 'Echoes',
      subtitle: 'Swift Student Challenge',
      description:
        'Interactive story about exclusion, silence, and the courage to speak up — Winner of the Apple Swift Student Challenge 2026. Built with Swift Playgrounds for WWDC26.',
      tags: ['Swift', 'SwiftUI', 'Playgrounds', 'WWDC26'],
      link: '/echoes/index.html',
      cover: '/projects/echoes-cover.jpg',
    },
    {
      title: 'Polly',
      subtitle: 'Digital Eco-Companion',
      description:
        'A digital eco-companion that helps you understand and reduce Data Pollution: clean your photo library, learn the facts, and chat with on-device Apple Intelligence — all in private.',
      tags: ['Swift', 'iOS', 'Apple Intelligence', 'Sustainability'],
      link: '/marcelloguida-polly/indexPolly.html',
      cover: '/projects/marcelloguida-polly-cover.jpg',
    },
    {
      title: 'SyncPoint',
      subtitle: 'Tennis & Padel',
      description:
        'A Tennis and Padel scorekeeper for Apple Watch and iPhone: scoring on your wrist, live scoreboard, stats, Apple Health, and matches shared with opponents.',
      tags: ['Swift', 'watchOS', 'iOS', 'HealthKit'],
      link: '/syncpoint/syncpoint.html',
      cover: '/projects/syncpoint-cover.jpg',
    },
    {
      title: 'World of Fables',
      subtitle: 'Lumi',
      description:
        'An immersive iPad experience that turns classic fables into interactive games, built to teach logical sequencing to children with a deep focus on accessibility — removing barriers so every young mind can play.',
      tags: ['Swift', 'iPadOS', 'Accessibility', 'Game Design'],
      link: '/world-of-fables/index.html',
      cover: '/projects/world-of-fables-cover.jpg',
    },
  ]

  return (
    <section id="projects" className="projects-wow reveal">
      <div className="container">
        <div className="section-header-wow">
          <SectionTab
            file="Projects.swift"
            comment="// shipped work"
            dotColor="var(--accent-color)"
          />
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
                <img src={project.cover} alt={`${project.title} preview`} className="project-cover-img" />
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
