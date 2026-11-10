import SectionTab from './SectionTab'
import { useLanguage } from '../i18n/useLanguage'
import './Skills.css'

const GROUPS = [
  {
    key: 'languages',
    label: '"languages"',
    items: ['Swift', 'Python', 'JavaScript', 'PHP'],
  },
  {
    key: 'apple_platforms',
    label: '"apple_platforms"',
    items: ['SwiftUI', 'UIKit', 'Xcode', 'iPadOS'],
  },
  {
    key: 'web_platforms',
    label: '"web_platforms"',
    items: ['WordPress', 'Shopify'],
  },
  {
    key: 'craft',
    label: '"craft"',
    items: ['UI/UX Design', 'Accessibility', 'Product Thinking', 'SEO', 'GEO'],
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
  const { t } = useLanguage()

  return (
    <section id="skills" className="skills-wow reveal">
      <div className="container">
        <SectionTab
          file="Skills.json"
          comment={t.skills.comment}
          dotColor="#f1c453"
        />

        <div className="skills-json-card">
          <span className="json-brace">{'{'}</span>
          <div className="skills-groups">
            {GROUPS.map((group, gIdx) => (
              <div className="skills-group" key={group.key}>
                <div className="skills-group-key">
                  {group.label}
                  <span className="json-colon">:</span>
                  <span className="json-bracket">[</span>
                </div>
                <div className="skills-chips">
                  {group.items.map((item) => (
                    <span className="skill-chip" key={item}>
                      {item}
                    </span>
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
