defmodule ExBanking do
  @moduledoc """
  Public interface and behaviour for `ExBanking` operations.
  """

  @doc """
    Creates new user in the system, new user has zero balance of any currency
  """
  @callback create_user(user :: String.t()) ::
              :ok | {:error, :wrong_arguments | :user_already_exists}
  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    implementation().create_user(user)
  end

  @doc """
    Increases user’s balance in given `currency` by `amount` value, returns `new_balance` of the user in given format
  """
  @callback deposit(user :: String.t(), amount :: Decimal.t(), currency :: String.t()) ::
              {:ok, new_balance :: number}
              | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  @spec deposit(user :: String.t(), amount :: Decimal.t(), currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency) do
    implementation().deposit(user, amount, currency)
  end

  @doc """
    Decreases user’s balance in given `currency` by `amount` value, returns `new_balance` of the user in given format
  """
  @callback withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
              {:ok, new_balance :: number}
              | {:error,
                 :wrong_arguments
                 | :user_does_not_exist
                 | :not_enough_money
                 | :too_many_requests_to_user}
  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency) do
    implementation().withdraw(user, amount, currency)
  end

  @doc """
    Returns `balance` of the user in given format
  """
  @callback get_balance(user :: String.t(), currency :: String.t()) ::
              {:ok, balance :: number}
              | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) do
    implementation().get_balance(user, currency)
  end

  @doc """
    Decreases `from_user`’s balance in given `currency` by `amount` value
    Increases `to_user`’s balance in given `currency` by `amount` value
    Returns new balance of `from_user` and `to_user` in given format
  """
  @callback send(
              from_user :: String.t(),
              to_user :: String.t(),
              amount :: number,
              currency :: String.t()
            ) ::
              {:ok, from_user_balance :: number, to_user_balance :: number}
              | {:error,
                 :wrong_arguments
                 | :not_enough_money
                 | :sender_does_not_exist
                 | :receiver_does_not_exist
                 | :too_many_requests_to_sender
                 | :too_many_requests_to_receiver}
  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}
  def send(from_user, to_user, amount, currency) do
    implementation().send(from_user, to_user, amount, currency)
  end

  defp implementation do
    Application.get_env(:ex_banking, ExBanking)[:implementation]
  end
end
