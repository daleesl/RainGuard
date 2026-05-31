import { SearchField } from './SearchField'

export function PageTopbar({
  action,
  description,
  search,
  title,
}) {
  return (
    <header className="flex h-[76px] items-center justify-between gap-6 border-b border-[#d9e7ef] bg-white pl-[clamp(24px,3vw,44px)] pr-[clamp(26px,3.3vw,56px)] max-[1360px]:gap-[18px] max-[760px]:h-auto max-[760px]:flex-col max-[760px]:items-stretch max-[760px]:px-5 max-[760px]:py-4">
      <div className="min-w-0">
        <h2 className="m-0 text-[22px] font-extrabold leading-tight text-[#102033] max-[1360px]:text-xl">
          {title}
        </h2>
        <p className="mt-0.5 mb-0 max-w-[640px] text-[10px] text-[#697b8c] max-[1360px]:max-w-[460px]">
          {description}
        </p>
      </div>

      {(search || action) ? (
        <div className="flex min-w-0 items-center gap-[26px] max-[1360px]:gap-3.5 max-[760px]:w-full max-[760px]:flex-col max-[760px]:items-stretch">
          {search ? <SearchField {...search} /> : null}
          {action}
        </div>
      ) : null}
    </header>
  )
}
