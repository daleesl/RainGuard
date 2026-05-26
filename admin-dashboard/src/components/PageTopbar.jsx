import { SearchField } from './SearchField'

export function PageTopbar({
  action,
  description,
  search,
  title,
}) {
  return (
    <header className="admin-topbar">
      <div>
        <h2>{title}</h2>
        <p>{description}</p>
      </div>

      {(search || action) ? (
        <div className="topbar-actions">
          {search ? <SearchField {...search} /> : null}
          {action}
        </div>
      ) : null}
    </header>
  )
}
