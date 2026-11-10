export default function SectionTab({ file, comment, dotColor = 'var(--accent-color)' }) {
  return (
    <div className="file-tab" style={{ '--dot-color': dotColor }}>
      <span className="dot" aria-hidden="true" />
      <span className="file-tab-name">{file.replace(/\.swift$/i, '')}</span>
      {comment ? <span className="file-tab-comment">{comment}</span> : null}
    </div>
  )
}
