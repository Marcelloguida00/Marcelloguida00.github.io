import './Navigation.css'

export default function Navigation({ scrolled }) {
  return (
    <header className={`navbar ${scrolled ? 'scrolled' : ''}`}>
      <div className="nav-container">
        <div className="nav-logo">
          <a href="#hero">
            <span className="logo-icon"></span>
            Marcello
          </a>
        </div>
        <nav className="nav-menu">
          <a href="#hero">Home</a>
          <a href="#projects">Work</a>
          <a href="#skills">Expertise</a>
          <a href="#about">About</a>
          <a href="#contact" className="nav-cta">Let's Talk</a>
        </nav>
      </div>
    </header>
  )
}
