interface ErrorBoxProps {
  message: string;
  onRetry: () => void;
}

export function Loading({ what }: { what: string }) {
  return (
    <p role="status" className="state state-loading">
      Carregando {what}…
    </p>
  );
}

export function ErrorBox({ message, onRetry }: ErrorBoxProps) {
  return (
    <div role="alert" className="state state-error">
      <p>{message}</p>
      <button type="button" className="btn" onClick={onRetry}>
        Tentar de novo
      </button>
    </div>
  );
}

export function Empty({ title, hint }: { title: string; hint: string }) {
  return (
    <div className="state state-empty">
      <p className="state-title">{title}</p>
      <p>{hint}</p>
    </div>
  );
}
