import './About.css'

export default function About() {
  return (
    <section id="about" className="about">
      <div className="container">
        <h2 className="section-title">About Me</h2>

        <div className="about-grid">
          <div className="about-content">
            <p className="about-text">
              I'm an engineering student at Università Guglielmo Marconi and Apple Developer Academy at Federico II University, passionate about building real products with growing interest in data-driven and ML systems.
            </p>

            <div className="about-highlights">
              <div className="highlight-item">
                <h3>Swift Student Challenge 2026 Winner</h3>
                <p>One of ~350 developers selected globally by Apple from thousands of applicants</p>
              </div>

              <div className="highlight-item">
                <h3>Apple Developer Academy</h3>
                <p>Selective program with ~150 admitted students. Built and shipped iOS apps using Swift and Xcode</p>
              </div>

              <div className="highlight-item">
                <h3>Teaching Experience</h3>
                <p>Freelance STEM tutor explaining complex technical concepts to secondary school students</p>
              </div>
            </div>
          </div>

          <div className="about-stats">
            <div className="stat">
              <span className="stat-number">350+</span>
              <p>Global winners (2026)</p>
            </div>
            <div className="stat">
              <span className="stat-number">150</span>
              <p>Academy cohort</p>
            </div>
            <div className="stat">
              <span className="stat-number">4</span>
              <p>Core languages</p>
            </div>
            <div className="stat">
              <span className="stat-number">9+</span>
              <p>Years of music</p>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
