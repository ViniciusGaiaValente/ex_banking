defmodule ExBanking.SigleBalanceWallet do
  @moduledoc """
  This module implements the sigle-balance approach to the "ExBanking.Wallet"
  behavior.

  In this approach, each user has a single balance, stored in "USD". Every other
  currency has its value stored in the system (based on "USD"). Some currencies
  were added with approximated values ("USD", "EUR", "JPY", "GBP", "AUD" and
  "CAD"). Any other currency requested will be created with a random value
  between 0.01 "USD" and 2.00 "USD".

  Examples:

  - each user has only one balance and any operation having a specific user as a
    target will always affect the same and only balance for that user;
  - if a user has "10" of balance in "USD" and he deposits more "10" in "EUR";
    this user ends up with a "22.00" balance in "USD";
  - if the user requests his money in another currency, the "USD" balance will
    be translated and rounded down with two decimal places of precision.
  """

  alias ExBanking.Repo

  @behaviour ExBanking.Wallet

  @table_name :currencies

  def start_db do
    :ets.new(@table_name, [
      :set,
      :public,
      :named_table,
      read_concurrency: false,
      write_concurrency: false
    ])

    {:ok, dollars} = Decimal.cast(1.00)
    {:ok, euros} = Decimal.cast(1.20)
    {:ok, yens} = Decimal.cast(0.01)
    {:ok, punds} = Decimal.cast(1.40)
    {:ok, australian_dollars} = Decimal.cast(0.70)
    {:ok, canadian_dollars} = Decimal.cast(0.80)

    :ets.insert(@table_name, {"USD", dollars})
    :ets.insert(@table_name, {"EUR", euros})
    :ets.insert(@table_name, {"JPY", yens})
    :ets.insert(@table_name, {"GBP", punds})
    :ets.insert(@table_name, {"AUD", australian_dollars})
    :ets.insert(@table_name, {"CAD", canadian_dollars})

    :ok
  end

  @impl true
  def create_wallet(user) do
    case Repo.get_data(user) do
      [] ->
        {:ok, value} = Decimal.cast(0)
        Repo.put_data(user, value)
        :ok

      _ ->
        {:error, :user_already_exists}
    end
  end

  @impl true
  def handle_deposit(user, amount, currency) do
    case Repo.get_data(user) do
      [] ->
        {:error, :user_does_not_exist}

      [{^user, old_balance}] ->
        {:ok, amount} = Decimal.cast(amount)
        currency_value = get_currency(currency)
        amount = Decimal.mult(amount, currency_value)
        new_balance = Decimal.add(old_balance, amount)
        Repo.put_data(user, new_balance)

        {
          :ok,
          new_balance
          |> Decimal.div(currency_value)
          |> Decimal.round(2, :floor)
          |> Decimal.to_float()
        }
    end
  end

  @impl true
  def handle_withdraw(user, amount, currency) do
    case Repo.get_data(user) do
      [] ->
        {:error, :user_does_not_exist}

      [{^user, old_balance}] ->
        {:ok, amount} = Decimal.cast(amount)
        currency_value = get_currency(currency)
        amount = Decimal.mult(amount, currency_value)
        new_balance = Decimal.sub(old_balance, amount)

        if Decimal.compare(new_balance, 0) != :lt do
          Repo.put_data(user, new_balance)

          {
            :ok,
            new_balance
            |> Decimal.div(currency_value)
            |> Decimal.round(2, :floor)
            |> Decimal.to_float()
          }
        else
          {:error, :not_enough_money}
        end
    end
  end

  @impl true
  def handle_get_balance(user, currency) do
    case Repo.get_data(user) do
      [] ->
        {:error, :user_does_not_exist}

      [{^user, balance}] ->
        currency_value = get_currency(currency)

        {
          :ok,
          balance
          |> Decimal.div(currency_value)
          |> Decimal.round(2, :floor)
          |> Decimal.to_float()
        }
    end
  end

  @impl true
  def handle_send(from_user, to_user, amount, currency) do
    case {Repo.get_data(from_user), Repo.get_data(to_user)} do
      {[], _} ->
        {:error, :sender_does_not_exist}

      {_, []} ->
        {:error, :receiver_does_not_exist}

      {[{^from_user, from_user_old_balance}], [{^to_user, to_user_old_balance}]} ->
        {:ok, amount} = Decimal.cast(amount)
        currency_value = get_currency(currency)
        amount = Decimal.mult(amount, currency_value)
        from_user_new_balance = Decimal.sub(from_user_old_balance, amount)

        if Decimal.compare(from_user_new_balance, 0) != :lt do
          to_user_new_balance = Decimal.add(to_user_old_balance, amount)
          Repo.put_data(from_user, from_user_new_balance)
          Repo.put_data(to_user, to_user_new_balance)

          {
            :ok,
            from_user_new_balance
            |> Decimal.div(currency_value)
            |> Decimal.round(2, :floor)
            |> Decimal.to_float(),
            to_user_new_balance
            |> Decimal.div(currency_value)
            |> Decimal.round(2, :floor)
            |> Decimal.to_float()
          }
        else
          {:error, :not_enough_money}
        end
    end
  end

  defp get_currency(key) do
    case :ets.lookup(@table_name, key) do
      [] ->
        value = Decimal.div(Enum.random(1..200), 100)
        :ets.insert(@table_name, {key, value})
        value

      [{^key, value}] ->
        value
    end
  end
end
