export default function SectionTab({ file, comment, dotColor = 'var(--accent-color)' }) {
  return (
    <div className="file-tab" style={{ '--dot-color': dotColor }}>
      <span className="dot" aria-hidden="true"></span>
      <span className="file-tab-path">~/portfolio/</span>
      <span className="file-tab-name">{file}</span>
      {comment ? <span className="file-tab-comment">{comment}</span> : null}
    </div>
  )
}
