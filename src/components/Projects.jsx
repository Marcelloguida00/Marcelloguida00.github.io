import { useEffect, useRef, useState } from 'react'
import SectionTab from './SectionTab'
import { useLanguage } from '../i18n/useLanguage'
import './Projects.css'

export default function Projects() {
  const { t, lang } = useLanguage()
  const p = t.projects
  const [active, setActive] = useState(0)
  const [cursor, setCursor] = useState({ x: 0, y: 0, visible: false })
  const listRef = useRef(null)

  useEffect(() => {
    const list = listRef.current
    if (!list) return undefined

    const onMove = (e) => {
      if (!window.matchMedia('(hover: hover) and (pointer: fine)').matches) return
      const rect = list.getBoundingClientRect()
      setCursor({
        x: e.clientX - rect.left,
        y: e.clientY - rect.top,
        visible: true,
      })
    }
    const onLeave = () => setCursor((c) => ({ ...c, visible: false }))

    list.addEventListener('pointermove', onMove)
    list.addEventListener('pointerleave', onLeave)
    return () => {
      list.removeEventListener('pointermove', onMove)
      list.removeEventListener('pointerleave', onLeave)
    }
  }, [])

  const current = p.items[active]

  return (
    <section id="projects" className="projects-signal">
      <div className="container">
        <div className="section-header-wow" data-reveal="up">
          <SectionTab
            file="Work.swift"
            comment={p.comment}
            dotColor="var(--accent-color)"
          />
          <a
            href="https://github.com/Marcelloguida00"
            target="_blank"
            rel="noopener noreferrer"
            className="view-all-btn"
          >
            {p.viewGithub} <span aria-hidden="true">↗</span>
          </a>
        </div>

        <div className="projects-stage" ref={listRef}>
          <ul className="projects-index" role="list">
            {p.items.map((project, index) => {
              const isActive = index === active
              return (
                <li key={project.title} data-reveal="up" data-delay={(index * 0.05).toFixed(2)}>
                  <a
                    href={project.link}
                    className={`project-row ${isActive ? 'is-active' : ''}`}
                    onPointerEnter={() => setActive(index)}
                    onFocus={() => setActive(index)}
                    data-cursor={lang === 'it' ? 'Apri' : 'Open'}
                  >
                    <span className="project-row-index" aria-hidden="true">
                      {String(index + 1).padStart(2, '0')}
                    </span>
                    <span className="project-row-copy">
                      <span className="project-row-title">{project.title}</span>
                      <span className="project-row-sub">{project.subtitle}</span>
                    </span>
                    <span className="project-row-tags">
                      {project.tags.slice(0, 2).join(' · ')}
                    </span>
                    <span className="project-row-arrow" aria-hidden="true">
                      ↗
                    </span>
                    <span className="project-row-voice" aria-hidden="true" />
                  </a>
                </li>
              )
            })}
          </ul>

          <aside
            className={`project-preview ${cursor.visible ? 'is-on' : ''}`}
            style={{
              transform: `translate3d(${cursor.x}px, ${cursor.y}px, 0)`,
            }}
            aria-hidden="true"
          >
            <div className="project-preview-inner">
              <img src={current.cover} alt="" />
            </div>
          </aside>
        </div>

        <p className="project-caption" data-reveal="fade" aria-live="polite">
          <span className="project-caption-label">
            {lang === 'it' ? 'intento' : 'intent'}
          </span>
          <span className="project-caption-text">{current.description}</span>
        </p>
      </div>
    </section>
  )
}
