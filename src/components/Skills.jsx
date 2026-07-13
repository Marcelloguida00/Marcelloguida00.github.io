import SectionTab from './SectionTab'
import './Skills.css'

const GROUPS = [
  {
    key: 'languages',
    label: '"languages"',
    items: ['Swift', 'Python', 'JavaScript'],
  },
  {
    key: 'apple_platforms',
    label: '"apple_platforms"',
    items: ['SwiftUI', 'UIKit', 'Xcode', 'iPadOS'],
  },
  {
    key: 'craft',
    label: '"craft"',
    items: ['UI/UX Design', 'Accessibility', 'Product Thinking'],
  },
  {
    key: 'shipped_apps',
    label: '"shipped_apps"',
    items: ['Polly', 'SyncPoint', 'World of Fables'],
  },
  {
    key: 'foundations',
    label: '"foundations"',
    items: ['Machine Learning', 'Algorithms', 'Databases', 'Git'],
  },
]

export default function Skills() {
  return (
    <section id="skills" className="skills-wow reveal">
      <div className="container">
        <SectionTab
          file="Skills.json"
          comment="// what I use"
          dotColor="#f1c453"
        />

        <div className="skills-json-card">
          <span className="json-brace">{'{'}</span>
          <div className="skills-groups">
            {GROUPS.map((group, gIdx) => (
              <div className="skills-group" key={group.key}>
                <div className="skills-group-key">
                  {group.label}<span className="json-colon">:</span>
                  <span className="json-bracket">[</span>
                </div>
                <div className="skills-chips">
                  {group.items.map((item) => (
                    <span className="skill-chip" key={item}>{item}</span>
                  ))}
                </div>
                <div className="skills-group-close">
                  <span className="json-bracket">]</span>
                  {gIdx < GROUPS.length - 1 && <span className="json-comma">,</span>}
                </div>
              </div>
            ))}
          </div>
          <span className="json-brace">{'}'}</span>
        </div>
      </div>
    </section>
  )
}
