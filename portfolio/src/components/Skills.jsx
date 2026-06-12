import './Skills.css'

export default function Skills() {
  const skillCategories = [
    {
      category: 'Languages',
      skills: ['Swift', 'Python', 'JavaScript', 'C']
    },
    {
      category: 'Concepts',
      skills: ['OOP', 'Algorithms & Data Structures', 'Databases', 'OS & Networks']
    },
    {
      category: 'Tools',
      skills: ['Xcode', 'Git', 'Linux Shell', 'Arduino', 'Office Suite']
    },
    {
      category: 'Exploring',
      skills: ['Machine Learning', 'REST APIs', 'Data Pipelines', 'scikit-learn', 'pandas']
    },
    {
      category: 'Soft Skills',
      skills: ['Team Collaboration', 'Public Speaking', 'Time Management', 'Mentoring']
    }
  ]

  return (
    <section id="skills" className="skills">
      <div className="container">
        <h2 className="section-title">Skills & Technologies</h2>

        <div className="skills-grid">
          {skillCategories.map((category, idx) => (
            <div key={idx} className="skill-card">
              <h3 className="skill-category">{category.category}</h3>
              <div className="skill-list">
                {category.skills.map((skill, i) => (
                  <span key={i} className="skill-tag">{skill}</span>
                ))}
              </div>
            </div>
          ))}
        </div>

        <div className="skills-note">
          <p>Always learning. Currently exploring iOS optimization, ML systems, and data pipelines.</p>
        </div>
      </div>
    </section>
  )
}
