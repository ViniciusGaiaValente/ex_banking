defmodule ExBanking.MultiCurrencyBalanceWallet do
  @moduledoc """
  This module implements the multi-currency approach to the "ExBanking.Wallet"
  behavior.


  In this approach, the user has an independent balance for every currency, and
  these different balances don`t communicate with each other

  Examples:

  - an operation using one currency could not add or subtract from another
    currency's balance;
  - the user has "10" of balance in "currency a", and he deposits more "10" in
    "currency b"; this user ends up with "10" balance in "currency a" and "10"
    balance in "currency b";
  - if the user tries to withdraw "11" in "currency a" he receives the
    ":not_enough_money error".
  """

  alias ExBanking.Repo

  @behaviour ExBanking.Wallet

  @impl true
  def create_wallet(user) do
    case Repo.get_data(user) do
      [] ->
        Repo.put_data(user, %{})
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

      [{^user, currencies}] ->
        {:ok, amount} = Decimal.cast(amount)

        {:ok, old_balance} =
          currencies
          |> Map.get(currency, 0)
          |> Decimal.cast()

        new_balance = Decimal.add(amount, old_balance)
        Repo.put_data(user, Map.put(currencies, currency, new_balance))

        {
          :ok,
          new_balance
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

      [{^user, currencies}] ->
        {:ok, amount} = Decimal.cast(amount)

        {:ok, old_balance} =
          currencies
          |> Map.get(currency, 0)
          |> Decimal.cast()

        new_balance = Decimal.sub(old_balance, amount)

        if Decimal.compare(new_balance, 0) != :lt do
          Repo.put_data(user, Map.put(currencies, currency, new_balance))

          {
            :ok,
            new_balance
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

      [{^user, currencies}] ->
        {
          :ok,
          Map.get(currencies, currency, 0)
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

      {[{^from_user, from_user_currencies}], [{^to_user, to_user_currencies}]} ->
        {:ok, amount} = Decimal.cast(amount)

        {:ok, from_user_old_balance} =
          from_user_currencies
          |> Map.get(currency, 0)
          |> Decimal.cast()

        {:ok, to_user_old_balance} =
          to_user_currencies
          |> Map.get(currency, 0)
          |> Decimal.cast()

        from_user_new_balance = Decimal.sub(from_user_old_balance, amount)

        if Decimal.compare(from_user_new_balance, 0) != :lt do
          to_user_new_balance = Decimal.add(to_user_old_balance, amount)

          Repo.put_data(
            from_user,
            Map.put(from_user_currencies, currency, from_user_new_balance)
          )

          Repo.put_data(
            to_user,
            Map.put(to_user_currencies, currency, to_user_new_balance)
          )

          {
            :ok,
            from_user_new_balance
            |> Decimal.round(2, :floor)
            |> Decimal.to_float(),
            to_user_new_balance
            |> Decimal.round(2, :floor)
            |> Decimal.to_float()
          }
        else
          {:error, :not_enough_money}
        end
    end
  end
end
