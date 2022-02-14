defmodule ExBankingTest do
  use ExUnit.Case

  alias ExBanking.Repo

  @user_a "user_a"
  @user_b "user_b"

  setup do
    Repo.clear_db()
    {:ok, []}
  end

  describe "create_user/2" do
    test "returns validation error" do
      assert {:error, :wrong_arguments} == ExBanking.create_user(0)
    end
  end

  describe "deposit/2" do
    test "returns validation error" do
      ExBanking.create_user(@user_a)
      assert {:error, :wrong_arguments} == ExBanking.deposit(0, 10, "UDS")
      assert {:error, :wrong_arguments} == ExBanking.deposit(@user_a, "10", "UDS")
      assert {:error, :wrong_arguments} == ExBanking.deposit(@user_a, 10, 10)
    end
  end

  describe "withdraw/2" do
    test "returns validation error" do
      ExBanking.create_user(@user_a)
      assert {:error, :wrong_arguments} == ExBanking.withdraw(0, 10, "UDS")
      assert {:error, :wrong_arguments} == ExBanking.withdraw(@user_a, "10", "UDS")
      assert {:error, :wrong_arguments} == ExBanking.withdraw(@user_a, 10, 10)
    end
  end

  describe "get_balance/2" do
    test "returns validation error" do
      ExBanking.create_user(@user_a)
      assert {:error, :wrong_arguments} == ExBanking.get_balance(0, "UDS")
      assert {:error, :wrong_arguments} == ExBanking.get_balance(@user_a, 0)
    end
  end

  describe "send/2" do
    test "returns validation error" do
      ExBanking.create_user(@user_a)
      ExBanking.create_user(@user_b)
      assert {:error, :wrong_arguments} == ExBanking.send(0, @user_b, 100, "USD")
      assert {:error, :wrong_arguments} == ExBanking.send(@user_a, 0, 100, "USD")
      assert {:error, :wrong_arguments} == ExBanking.send(@user_a, @user_b, "100", "USD")
      assert {:error, :wrong_arguments} == ExBanking.send(@user_a, @user_b, 100, 0)
    end
  end

  describe "other_tests" do
    test "create currencies dynamically with a random value between 0.01 dollars and 2 dollars" do
      ExBanking.create_user(@user_a)
      ExBanking.create_user(@user_b)

      assert ExBanking.deposit(@user_a, 100, "my_currency") == ExBanking.deposit(@user_b, 100, "my_currency")
      assert ExBanking.deposit(@user_a, 100, "my_other_currency") == ExBanking.deposit(@user_b, 100, "my_other_currency")

      [{"my_currency", _}] = :ets.lookup(:currencies, "my_currency")
      [{"my_other_currency", _}] = :ets.lookup(:currencies, "my_other_currency")
    end
  end
end
