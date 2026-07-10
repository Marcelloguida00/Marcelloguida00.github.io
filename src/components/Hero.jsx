import { useEffect, useRef, useState } from 'react'
import './Hero.css'

const CODE_LINES = [
  { indent: 0, text: 'struct Marcello: Developer {' },
  { indent: 1, text: 'var role = "iOS Developer & Designer"' },
  { indent: 1, text: 'var focus = ["Swift", "UIKit", "Accessibility"]' },
  { indent: 1, text: 'var status: Availability = .openToWork' },
  { indent: 0, text: '}' },
]

export default function Hero() {
  const [visibleLines, setVisibleLines] = useState(0)
  const [charCount, setCharCount] = useState(0)
  const hasRun = useRef(false)

  useEffect(() => {
    if (hasRun.current) return
    hasRun.current = true

    const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    if (prefersReduced) {
      setVisibleLines(CODE_LINES.length)
      setCharCount(CODE_LINES[CODE_LINES.length - 1].text.length)
      return
    }

    let line = 0
    let char = 0
    let timeoutId

    const typeNext = () => {
      if (line >= CODE_LINES.length) return
      const current = CODE_LINES[line]
      if (char <= current.text.length) {
        setVisibleLines(line + 1)
        setCharCount(char)
        char += 1
        timeoutId = setTimeout(typeNext, 14 + Math.random() * 22)
      } else {
        line += 1
        char = 0
        timeoutId = setTimeout(typeNext, 160)
      }
    }

    timeoutId = setTimeout(typeNext, 500)
    return () => clearTimeout(timeoutId)
  }, [])

  return (
    <section id="hero" className="hero-wow">
      <div className="hero-glow-orb"></div>
      <div className="hero-grid-fade"></div>

      <div className="hero-content-wow">
        <div className="hero-copy">
          <div className="hero-badge">
            <span className="live-dot"></span>
            Available for new projects
          </div>

          <h1 className="hero-title-wow">
            Crafting <span className="text-accent">native</span><br />
            iOS experiences.
          </h1>

          <p className="hero-subtitle-wow">
            I'm Marcello, an iOS developer and designer. Engineering student, Apple
            Developer Academy alumnus, and Swift Student Challenge 2026 winner —
            building apps that are as considered under the hood as they are on screen.
          </p>

          <div className="hero-actions">
            <a href="#projects" className="btn btn-primary">View my work</a>
            <a href="#contact" className="btn btn-secondary">Get in touch</a>
          </div>
        </div>

        <div className="hero-editor" aria-hidden="true">
          <div className="editor-titlebar">
            <div className="editor-dots">
              <span className="dot red"></span>
              <span className="dot yellow"></span>
              <span className="dot green"></span>
            </div>
            <span className="editor-filename">Marcello.swift</span>
          </div>
          <div className="editor-body">
            {CODE_LINES.slice(0, visibleLines).map((lineObj, idx) => {
              const isCurrent = idx === visibleLines - 1
              const text = isCurrent ? lineObj.text.slice(0, charCount) : lineObj.text
              return (
                <div className="editor-line" key={idx}>
                  <span className="line-number">{idx + 1}</span>
                  <span
                    className="line-code"
                    style={{ paddingLeft: `${lineObj.indent * 20}px` }}
                  >
                    {text}
                    {isCurrent && <span className="type-cursor"></span>}
                  </span>
                </div>
              )
            })}
          </div>
        </div>
      </div>
    </section>
  )
}
