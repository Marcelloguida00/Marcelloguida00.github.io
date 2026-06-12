import './About.css'

export default function About() {
  return (
    <section id="about" className="about">
      <div className="container">
        <h2 className="section-title">about-me</h2>

        <div className="about-grid">
          <div className="about-content">
            <p className="about-greeting">Hello, I'm Marcello!</p>
            <p className="about-text">
              I'm an engineering student at Università Guglielmo Marconi and Apple Developer Academy at Federico II University. 
              I develop responsive and beautiful iOS applications from scratch and raise them into modern user-friendly experiences.
            </p>
            <p className="about-text">
              I am very passionate about improving my coding skills & developing applications. 
              I always strive to learn about the newest technologies and frameworks. Swift Student Challenge 2026 Winner.
            </p>
            
            <a href="#" className="btn btn-secondary resume-btn">
              Resume <span className="download-icon">📥</span>
            </a>
          </div>

          <div className="about-illustration-container">
            <div className="about-illustration">
              <div className="programmer-avatar-placeholder">
                <div className="screen">
                  <span className="code-symbol">{`</>`}</span>
                </div>
                <div className="user-icon">👤</div>
              </div>
              
              {/* Decorative dots to match the design */}
              <div className="decorative-dots left-dots"></div>
              <div className="decorative-dots right-dots"></div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
