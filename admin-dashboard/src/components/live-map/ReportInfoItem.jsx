export function ReportInfoItem({ label, stacked = false, value }) {
  return (
    <div className={`modal-info-item ${stacked ? 'is-stacked' : ''}`}>
      <span>{label}</span>
      {stacked && typeof value === 'object' ? (
        <strong>
          <em>{value.primary}</em>
          <em>{value.secondary}</em>
        </strong>
      ) : (
        <strong>{value}</strong>
      )}
    </div>
  )
}
