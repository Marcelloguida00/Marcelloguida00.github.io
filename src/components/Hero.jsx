import './Hero.css'

export default function Hero() {
  return (
    <section id="hero" className="hero-wow">
      
      {/* Dynamic Background Elements */}
      <div className="hero-glow-orb"></div>
      
      <div className="hero-content-wow">
        <div className="hero-badge">
          <span className="live-dot"></span>
          Available for New Projects
        </div>
        
        <h1 className="hero-title-wow">
          Crafting <span className="text-gradient">Digital</span><br/>
          Experiences
        </h1>
        
        <p className="hero-subtitle-wow">
          Hi, I'm Marcello. An iOS developer & designer passionate about building bold, intuitive, and highly functional applications that leave a lasting impression.
        </p>
        
        <div className="hero-actions">
          <a href="#projects" className="btn btn-primary">View My Work</a>
          <a href="#contact" className="btn btn-secondary">Get in Touch</a>
        </div>
      </div>

    </section>
  )
}
