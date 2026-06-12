import './Navigation.css'

export default function Navigation({ scrolled }) {
  return (
    <nav className={`navbar ${scrolled ? 'scrolled' : ''}`}>
      <div className="nav-container">
        <div className="nav-logo">
          <a href="#hero">Marcello</a>
        </div>
        <ul className="nav-menu">
          <li><a href="#hero">#home</a></li>
          <li><a href="#projects">#projects</a></li>
          <li><a href="#skills">#skills</a></li>
          <li><a href="#about">#about-me</a></li>
          <li><a href="#contact">#contact-me</a></li>
        </ul>
      </div>
    </nav>
  )
}
