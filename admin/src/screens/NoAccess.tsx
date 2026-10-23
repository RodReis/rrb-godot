export function NoAccess() {
  return (
    <section className="state state-empty no-access">
      <h2>Sem acesso</h2>
      <p>
        Esta conta entrou, mas não tem o papel de administrador. Peça para incluir o e-mail dela em{' '}
        <code>ADMIN_EMAILS</code> e reiniciar o backend.
      </p>
    </section>
  );
}
