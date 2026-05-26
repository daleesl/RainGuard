export function MetricCard({ accent, className = '', helper, icon: Icon, label, value }) {
  return (
    <article
      className={`metric-card ${className}`.trim()}
      style={{ '--metric-accent': accent }}
    >
      {Icon ? (
        <span className="dashboard-metric-icon">
          <Icon aria-hidden="true" size={16} />
        </span>
      ) : null}
      <p>{label}</p>
      <strong>{value}</strong>
      <span>{helper}</span>
    </article>
  )
}
