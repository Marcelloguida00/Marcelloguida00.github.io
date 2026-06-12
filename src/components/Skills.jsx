import './Skills.css'

export default function Skills() {
  const skills = [
    { name: 'Swift', icon: '⚡' },
    { name: 'Python', icon: '🐍' },
    { name: 'JavaScript', icon: '🚀' },
    { name: 'UI/UX Design', icon: '✨' },
    { name: 'Machine Learning', icon: '🧠' },
    { name: 'Databases', icon: '💾' },
    { name: 'Algorithms', icon: '⚙️' },
    { name: 'Git', icon: '🐙' }
  ]

  return (
    <section id="skills" className="skills-wow">
      <div className="container">
        <h2 className="section-title">My Expertise</h2>

        <div className="skills-grid-wow">
          {skills.map((skill, idx) => (
            skill.url ? (
              <a href={skill.url} target="_blank" rel="noopener noreferrer" key={idx} className={`skill-card ${skill.featured ? 'featured' : ''}`}>
                <div className="skill-icon">{skill.icon}</div>
                <span className="skill-name">{skill.name}</span>
              </a>
            ) : (
              <div key={idx} className={`skill-card ${skill.featured ? 'featured' : ''}`}>
                <div className="skill-icon">{skill.icon}</div>
                <span className="skill-name">{skill.name}</span>
              </div>
            )
          ))}
        </div>
      </div>
    </section>
  )
}
