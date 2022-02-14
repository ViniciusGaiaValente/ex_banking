defmodule ExBanking.ExBankingImplementation do
  @moduledoc """
  Implementation for `ExBanking` behaviour.
  """

  alias ExBanking.AccessController
  alias ExBanking.Wallet

  @behaviour ExBanking

  require Logger

  @impl true
  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    if is_bitstring(user) do
      lock = Mutex.await(UserLock, user)
      result = Wallet.create_wallet(user)
      Mutex.release(UserLock, lock)
      result
    else
      {:error, :wrong_arguments}
    end
  end

  @impl true
  @spec deposit(user :: String.t(), amount :: Decimal.t(), currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency) do
    if is_bitstring(user) and is_number(amount) and is_bitstring(currency) do
      case AccessController.start_operation(user) do
        {:ok, _} ->
          lock = Mutex.await(UserLock, user)
          result = Wallet.handle_deposit(user, amount, currency)
          Mutex.release(UserLock, lock)
          AccessController.finish_operation(user)
          result

        {:error, _} ->
          {:error, :too_many_requests_to_user}
      end
    else
      {:error, :wrong_arguments}
    end
  end

  @impl true
  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency) do
    if is_bitstring(user) and is_number(amount) and is_bitstring(currency) do
      case AccessController.start_operation(user) do
        {:ok, _} ->
          lock = Mutex.await(UserLock, user)
          result = Wallet.handle_withdraw(user, amount, currency)
          Mutex.release(UserLock, lock)
          AccessController.finish_operation(user)
          result

        {:error, _} ->
          {:error, :too_many_requests_to_user}
      end
    else
      {:error, :wrong_arguments}
    end
  end

  @impl true
  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) do
    if is_bitstring(user) and is_bitstring(currency) do
      case AccessController.start_operation(user) do
        {:ok, _} ->
          result = Wallet.handle_get_balance(user, currency)
          AccessController.finish_operation(user)
          result

        {:error, _} ->
          {:error, :too_many_requests_to_user}
      end
    else
      {:error, :wrong_arguments}
    end
  end

  @impl true
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
    if is_bitstring(from_user) and is_bitstring(to_user) and is_number(amount) and
         is_bitstring(currency) do
      case {AccessController.start_operation(from_user),
            AccessController.start_operation(to_user)} do
        {{:error, _}, _} ->
          {:error, :too_many_requests_to_sender}

        {_, {:error, _}} ->
          {:error, :too_many_requests_to_receiver}

        {{:ok, _}, {:ok, _}} ->
          lock = Mutex.await_all(UserLock, [from_user, to_user])
          result = Wallet.handle_send(from_user, to_user, amount, currency)
          Mutex.release(UserLock, lock)
          AccessController.finish_operation(to_user)
          AccessController.finish_operation(from_user)
          result
      end
    else
      {:error, :wrong_arguments}
    end
  end
end
