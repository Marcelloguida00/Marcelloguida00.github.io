import './About.css'

const FACTS = [
  { label: 'Based in', value: 'Naples, Italy' },
  { label: 'Studying', value: 'Computer Science · Fisciano (UNISA)' },
  { label: 'Academy', value: 'Apple Developer Academy · Federico II' },
  { label: 'Award', value: 'Swift Student Challenge 2026' },
]

export default function About() {
  return (
    <section id="about" className="about-wow reveal">
      <div className="container">
        <div className="file-tab" style={{ '--dot-color': 'var(--accent-secondary)' }}>
          <span className="dot"></span> About.swift
        </div>

        <div className="about-grid-wow">
          <div className="about-main">
            <h2 className="about-greeting">
              Hi, I'm Marcello —<br />I build software that respects people.
            </h2>
            <p className="about-text">
              I'm a Computer Science student at the University of Salerno (Fisciano)
              and an iOS developer currently sharpening my craft at the Apple
              Developer Academy, a joint program with Federico II University in
              Naples. I design and build responsive, native iOS applications from
              first sketch to shipped product.
            </p>
            <p className="about-text">
              What keeps me at the keyboard is the gap between an idea and a working
              app: I like closing it carefully, with attention to performance,
              accessibility, and the small interactions most people never notice —
              but always feel.
            </p>
          </div>

          <div className="about-facts">
            {FACTS.map((fact) => (
              <div className="fact-row" key={fact.label}>
                <span className="fact-label">{fact.label}</span>
                <span className="fact-value">{fact.value}</span>
              </div>
            ))}
            <div className="fact-highlight">
              <span className="fact-highlight-icon">🏆</span>
              <span>Swift Student Challenge 2026 Winner</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
