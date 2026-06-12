import './Hero.css'

export default function Hero() {
  return (
    <section id="hero" className="hero">
      <div className="hero-content">
        <h1 className="hero-title">Marcello Guida</h1>
        <p className="hero-subtitle">iOS Developer · Swift Student Challenge 2026 Winner</p>
        <p className="hero-description">
          Building beautiful, performant iOS apps. Apple Developer Academy student exploring data-driven systems.
        </p>
        <div className="hero-cta">
          <a href="#contact" className="btn btn-primary">Get in Touch</a>
          <a href="#projects" className="btn btn-secondary">View Work</a>
        </div>
        <div className="hero-badges">
          <span className="badge">Swift</span>
          <span className="badge">iOS Development</span>
          <span className="badge">Xcode</span>
        </div>
      </div>
      <div className="hero-accent"></div>
    </section>
  )
}
