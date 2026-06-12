import './About.css'

export default function About() {
  return (
    <section id="about" className="about-wow">
      <div className="container">
        <h2 className="section-title">About Me</h2>

        <div className="about-grid-wow">
          <div className="about-glass-card">
            <h3 className="about-greeting">Hello, I'm Marcello</h3>
            <p className="about-text">
              I'm an engineering student at Università Guglielmo Marconi and Apple Developer Academy at Federico II University. 
              I develop responsive and beautiful iOS applications from scratch and raise them into modern user-friendly experiences.
            </p>
            <p className="about-text">
              I am very passionate about improving my coding skills & developing applications. 
              I always strive to learn about the newest technologies and frameworks.
            </p>
            
            <div className="about-highlights">
              <div className="highlight-item">
                <span className="highlight-icon">🏆</span>
                <span>Swift Student Challenge 2026 Winner</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
