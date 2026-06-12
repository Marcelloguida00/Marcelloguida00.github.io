import './Skills.css'

export default function Skills() {
  const skills = [
    'swift', 'python', 'javascript', 'c',
    'oop', 'algorithms', 'databases', 'os-networks',
    'xcode', 'git', 'linux', 'arduino',
    'machine-learning', 'rest-api', 'scikit', 'pandas'
  ]

  return (
    <section id="skills" className="skills">
      <div className="container">
        <h2 className="section-title">skills</h2>

        <div className="skills-grid">
          {skills.map((skill, idx) => (
            <div key={idx} className="skill-square">
              <div className="skill-icon-placeholder">
                {/* Simulated icon using first letter or bracket syntax */}
                <span className="skill-bracket">[</span>
                <span className="skill-letter">{skill.charAt(0)}</span>
                <span className="skill-bracket">]</span>
              </div>
              <span className="skill-name">{skill}</span>
            </div>
          ))}
        </div>

      </div>
    </section>
  )
}
