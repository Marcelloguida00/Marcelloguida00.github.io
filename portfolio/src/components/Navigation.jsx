import './Navigation.css'

export default function Navigation({ scrolled }) {
  return (
    <nav className={`navbar ${scrolled ? 'scrolled' : ''}`}>
      <div className="nav-container">
        <div className="nav-logo">
          <a href="#hero">MG</a>
        </div>
        <ul className="nav-menu">
          <li><a href="#about">About</a></li>
          <li><a href="#experience">Experience</a></li>
          <li><a href="#skills">Skills</a></li>
          <li><a href="#projects">Projects</a></li>
          <li><a href="#contact" className="nav-cta">Contact</a></li>
        </ul>
      </div>
    </nav>
  )
}
