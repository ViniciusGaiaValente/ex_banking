defmodule ExBanking.SingleBalanceWalletTest do
  use ExUnit.Case

  alias ExBanking.Repo
  alias ExBanking.SingleBalanceWallet

  @user_a "user_a"
  @user_b "user_b"

  setup do
    Repo.clear_db()
    {:ok, []}
  end

  describe "create_user/2" do
    test "create new users with 0 balance" do
      assert :ok == SingleBalanceWallet.create_wallet(@user_a)
      assert [{@user_a, value_a}] = Repo.get_data(@user_a)
      assert Decimal.eq?(value_a, 0)
    end

    test "returns the correct error when trying to create a user that already exists" do
      assert :ok == SingleBalanceWallet.create_wallet(@user_a)
      assert {:error, :user_already_exists} == SingleBalanceWallet.create_wallet(@user_a)
    end
  end

  describe "deposit/2" do
    test "puts the right amount of money in the wallet" do
      SingleBalanceWallet.create_wallet(@user_a)
      SingleBalanceWallet.handle_deposit(@user_a, 100, "USD")
      assert [{@user_a, value}] = Repo.get_data(@user_a)
      assert Decimal.eq?(value, 100)
    end

    test "puts the right amount of money in the wallet considering currency" do
      SingleBalanceWallet.create_wallet(@user_a)
      SingleBalanceWallet.handle_deposit(@user_a, 100, "EUR")
      assert [{@user_a, value}] = Repo.get_data(@user_a)
      assert Decimal.eq?(value, 120)
    end

    test "puts the right amount of money in the wallet considering decimal places" do
      SingleBalanceWallet.create_wallet(@user_a)
      SingleBalanceWallet.handle_deposit(@user_a, 0.000000001, "USD")
      assert [{@user_a, value}] = Repo.get_data(@user_a)

      {:ok, expected_value} = Decimal.cast(0.000000001)
      assert Decimal.eq?(value, expected_value)
    end
  end

  describe "withdraw/2" do
    test "takes the right amount of money from the wallet" do
      SingleBalanceWallet.create_wallet(@user_a)
      SingleBalanceWallet.handle_deposit(@user_a, 100, "USD")
      SingleBalanceWallet.handle_withdraw(@user_a, 80, "USD")
      assert [{@user_a, value}] = Repo.get_data(@user_a)
      assert Decimal.eq?(value, 20)
    end

    test "takes the right amount of money from the wallet considering currency" do
      SingleBalanceWallet.create_wallet(@user_a)
      SingleBalanceWallet.handle_deposit(@user_a, 100, "USD")
      SingleBalanceWallet.handle_withdraw(@user_a, 100, "CAD")
      assert [{@user_a, value}] = Repo.get_data(@user_a)
      assert Decimal.eq?(value, 20)
    end

    test "takes the right amount of money from the wallet considering decimal places" do
      SingleBalanceWallet.create_wallet(@user_a)
      SingleBalanceWallet.handle_deposit(@user_a, 100, "USD")
      SingleBalanceWallet.handle_withdraw(@user_a, 99.99, "USD")
      assert [{@user_a, value}] = Repo.get_data(@user_a)

      {:ok, expected_value} = Decimal.cast(0.01)
      assert Decimal.eq?(value, expected_value)
    end

    test "returns the correct error when trying to withdraw more money them the balance in the wallet" do
      SingleBalanceWallet.create_wallet(@user_a)
      SingleBalanceWallet.handle_deposit(@user_a, 100, "USD")
      assert {:error, :not_enough_money} == SingleBalanceWallet.handle_withdraw(@user_a, 101, "USD")

      assert [{@user_a, value}] = Repo.get_data(@user_a)
      assert Decimal.eq?(value, 100)
    end
  end

  describe "get_balance/2" do
    test "returns the same amount of money present in the wallet" do
      SingleBalanceWallet.create_wallet(@user_a)
      SingleBalanceWallet.handle_deposit(@user_a, 100, "USD")

      {:ok, value} = SingleBalanceWallet.handle_get_balance(@user_a, "USD")
      {:ok, value} = Decimal.cast(value)
      assert Decimal.eq?(value, 100)
    end

    test "returns the same amount of money present in the wallet on the correct currency" do
      SingleBalanceWallet.create_wallet(@user_a)
      SingleBalanceWallet.handle_deposit(@user_a, 100, "CAD")

      {:ok, value} = SingleBalanceWallet.handle_get_balance(@user_a, "USD")
      {:ok, value} = Decimal.cast(value)
      assert Decimal.eq?(value, 80)
    end

    test "returns the same amount of money present in the wallet with 2 decimal places rounded floor" do
      SingleBalanceWallet.create_wallet(@user_a)
      SingleBalanceWallet.handle_deposit(@user_a, 0.019, "USD")

      {:ok, value} = SingleBalanceWallet.handle_get_balance(@user_a, "USD")
      {:ok, value} = Decimal.cast(value)
      {:ok, expected_value} = Decimal.cast(0.01)
      assert Decimal.eq?(value, expected_value)
    end
  end

  describe "send/2" do
    test "sends the correct amount of money from one wallet to another" do
      SingleBalanceWallet.create_wallet(@user_a)
      SingleBalanceWallet.create_wallet(@user_b)

      SingleBalanceWallet.handle_deposit(@user_a, 100, "USD")
      SingleBalanceWallet.handle_send(@user_a, @user_b, 50, "USD")

      {:ok, value} = SingleBalanceWallet.handle_get_balance(@user_a, "USD")
      {:ok, value} = Decimal.cast(value)
      assert Decimal.eq?(value, 50)

      {:ok, value} = SingleBalanceWallet.handle_get_balance(@user_b, "USD")
      {:ok, value} = Decimal.cast(value)
      assert Decimal.eq?(value, 50)
    end

    test "sends the correct amount of money from one wallet to another considering currency" do
      SingleBalanceWallet.create_wallet(@user_a)
      SingleBalanceWallet.create_wallet(@user_b)

      SingleBalanceWallet.handle_deposit(@user_a, 100, "USD")
      SingleBalanceWallet.handle_send(@user_a, @user_b, 100, "AUD")

      {:ok, value} = SingleBalanceWallet.handle_get_balance(@user_a, "USD")
      {:ok, value} = Decimal.cast(value)
      assert Decimal.eq?(value, 30)

      {:ok, value} = SingleBalanceWallet.handle_get_balance(@user_b, "USD")
      {:ok, value} = Decimal.cast(value)
      assert Decimal.eq?(value, 70)
    end

    test "sends the correct amount of money from one wallet to another considering decimal places" do
      SingleBalanceWallet.create_wallet(@user_a)
      SingleBalanceWallet.create_wallet(@user_b)

      SingleBalanceWallet.handle_deposit(@user_a, 22.22, "USD")
      SingleBalanceWallet.handle_send(@user_a, @user_b, 11.11, "USD")

      {:ok, value} = SingleBalanceWallet.handle_get_balance(@user_a, "USD")
      {:ok, value} = Decimal.cast(value)
      {:ok, expected_value} = Decimal.cast(11.11)
      assert Decimal.eq?(value, expected_value)

      {:ok, value} = SingleBalanceWallet.handle_get_balance(@user_b, "USD")
      {:ok, value} = Decimal.cast(value)
      {:ok, expected_value} = Decimal.cast(11.11)
      assert Decimal.eq?(value, expected_value)
    end

    test "returns the correct error when trying to send more money them the balance in the sender wallet considering currency" do
      SingleBalanceWallet.create_wallet(@user_a)
      SingleBalanceWallet.create_wallet(@user_b)

      SingleBalanceWallet.handle_deposit(@user_a, 100, "USD")
      {:error, :not_enough_money} = SingleBalanceWallet.handle_send(@user_a, @user_b, 101, "USD")

      {:ok, value} = SingleBalanceWallet.handle_get_balance(@user_a, "USD")
      {:ok, value} = Decimal.cast(value)
      assert Decimal.eq?(value, 100)

      {:ok, value} = SingleBalanceWallet.handle_get_balance(@user_b, "USD")
      {:ok, value} = Decimal.cast(value)
      assert Decimal.eq?(value, 0)
    end
  end

  describe "other_tests" do
    test "create currencies dynamically with a random value between 0.01 dollars and 2 dollars" do
      SingleBalanceWallet.create_wallet(@user_a)
      SingleBalanceWallet.create_wallet(@user_b)

      assert SingleBalanceWallet.handle_deposit(@user_a, 100, "my_currency") == SingleBalanceWallet.handle_deposit(@user_b, 100, "my_currency")
      assert SingleBalanceWallet.handle_deposit(@user_a, 100, "my_other_currency") == SingleBalanceWallet.handle_deposit(@user_b, 100, "my_other_currency")

      [{"my_currency", _}] = :ets.lookup(:currencies, "my_currency")
      [{"my_other_currency", _}] = :ets.lookup(:currencies, "my_other_currency")
    end
  end
end
