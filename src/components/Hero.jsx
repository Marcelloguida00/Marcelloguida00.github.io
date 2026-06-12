import './Hero.css'

export default function Hero() {
  return (
    <section id="hero" className="hero">
      <div className="hero-container">
        
        <div className="hero-content">
          <h1 className="hero-title">
            Hi, I'm an <span className="highlight">iOS developer</span> and <br/>
            <span className="highlight">Apple Academy student</span>
          </h1>
          <p className="hero-description">
            I'm currently building beautiful, performant iOS apps and exploring data-driven systems. Swift Student Challenge 2026 Winner.
          </p>
          <div className="hero-cta">
            <a href="#projects" className="btn btn-secondary">Scroll Down ↓</a>
          </div>
        </div>

        <div className="hero-image-container">
          <div className="hero-image-box">
            <div className="abstract-border top-left"></div>
            <div className="abstract-border bottom-right"></div>
            {/* Placeholder for actual image */}
            <div className="image-placeholder">
              <img src="https://avatars.githubusercontent.com/u/108918231?v=4" alt="Marcello Guida" />
            </div>
            <div className="status-box">
              <span className="status-dot"></span> Currently working on <b>Portfolio</b>
            </div>
          </div>
        </div>

      </div>

      <div className="hero-quote-container">
        <div className="quote-box">
          <span className="quote-icon-top">“</span>
          <p className="quote-text">
            Control can sometimes be an illusion. <br/>
            But sometimes you need illusion to gain control.
          </p>
          <span className="quote-icon-bottom">”</span>
          <p className="quote-author">- Mr. Robot</p>
        </div>
      </div>

    </section>
  )
}
