defmodule ExBanking.Wallet do
  @moduledoc """
  This module defines the behavior with interfaces to handle wallet creation,
  balance access, and money transactions.
  """

  @callback create_wallet(user :: String.t()) :: :ok | {:error, :user_already_exists}
  def create_wallet(user) do
    implementation().create_wallet(user)
  end

  @callback handle_deposit(user :: String.t(), amount :: number(), currency :: String.t()) ::
              {:error, :user_does_not_exist} | {:ok, float}
  @spec handle_deposit(user :: String.t(), amount :: number(), currency :: String.t()) ::
          {:error, :user_does_not_exist} | {:ok, float}
  def handle_deposit(user, amount, currency) do
    implementation().handle_deposit(user, amount, currency)
  end

  @callback handle_withdraw(user :: String.t(), amount :: number(), currency :: String.t()) ::
              {:error, :not_enough_money | :user_does_not_exist} | {:ok, float}
  @spec handle_withdraw(user :: String.t(), amount :: number(), currency :: String.t()) ::
          {:error, :not_enough_money | :user_does_not_exist} | {:ok, float}
  def handle_withdraw(user, amount, currency) do
    implementation().handle_withdraw(user, amount, currency)
  end

  @callback handle_get_balance(user :: String.t(), currency :: String.t()) ::
              {:error, :user_does_not_exist} | {:ok, float}
  @spec handle_get_balance(user :: String.t(), currency :: String.t()) ::
          {:error, :user_does_not_exist} | {:ok, float}
  def handle_get_balance(user, currency) do
    implementation().handle_get_balance(user, currency)
  end

  @callback handle_send(
              from_user :: String.t(),
              from_user :: String.t(),
              amount :: number(),
              currency :: String.t()
            ) ::
              {:error, :not_enough_money | :receiver_does_not_exist | :sender_does_not_exist}
              | {:ok, float, float}
  @spec handle_send(
          from_user :: String.t(),
          from_user :: String.t(),
          amount :: number(),
          currency :: String.t()
        ) ::
          {:error, :not_enough_money | :receiver_does_not_exist | :sender_does_not_exist}
          | {:ok, float, float}
  def handle_send(from_user, to_user, amount, currency) do
    implementation().handle_send(from_user, to_user, amount, currency)
  end

  defp implementation do
    Application.get_env(:ex_banking, ExBanking.Wallet)[:implementation]
  end
end
