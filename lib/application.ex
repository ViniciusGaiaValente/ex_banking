defmodule ExBanking.Application do
  use Application

  def start(_type, _args) do
    children = [
      %{
        id: ExBanking.AccessController,
        start: {ExBanking.AccessController, :start_link, [[]]}
      },
      {Mutex, name: UserLock}
    ]

    ExBanking.Repo.start_db()
    ExBanking.SingleBalanceWallet.start_db()

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
