import './Hero.css'

const CODE_LINES = [
  { indent: 0, text: 'struct Marcello: Developer {' },
  { indent: 1, text: 'var role = "iOS Developer & Designer"' },
  { indent: 1, text: 'var focus = ["Swift", "UIKit", "Accessibility"]' },
  { indent: 1, text: 'var status: Availability = .openToWork' },
  { indent: 0, text: '}' },
]

export default function Hero() {
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
            I'm Marcello, an iOS developer and designer. Computer Science student
            at Fisciano, Apple Developer Academy alumnus, and Swift Student
            Challenge 2026 winner — building apps that are as considered under the
            hood as they are on screen.
          </p>

          <div className="hero-actions">
            <a href="#projects" className="btn btn-primary">View my work</a>
            <a href="#contact" className="btn btn-secondary">Get in touch</a>
          </div>
        </div>

        <div className="hero-visual">
          <div className="hero-photo-wrap">
            <img
              src="/profile/marcello-guida.jpg"
              alt="Marcello Guida, iOS developer"
              className="hero-photo"
              width={420}
              height={560}
              loading="eager"
              decoding="async"
            />
          </div>

          <div className="hero-editor">
            <div className="editor-titlebar">
            <div className="editor-dots">
              <span className="dot red"></span>
              <span className="dot yellow"></span>
              <span className="dot green"></span>
            </div>
            <span className="editor-filename">Marcello.swift</span>
            </div>
            <div className="editor-body">
            {CODE_LINES.map((lineObj, idx) => {
              const isLast = idx === CODE_LINES.length - 1
              return (
                <div
                  className="editor-line"
                  key={lineObj.text}
                  style={{ animationDelay: `${idx * 120}ms` }}
                >
                  <span className="line-number">{idx + 1}</span>
                  <span
                    className="line-code"
                    style={{ paddingLeft: `${lineObj.indent * 20}px` }}
                  >
                    {lineObj.text}
                    {isLast && <span className="type-cursor" aria-hidden="true"></span>}
                  </span>
                </div>
              )
            })}
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
