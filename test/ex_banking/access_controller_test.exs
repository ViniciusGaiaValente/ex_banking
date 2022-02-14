defmodule ExBanking.AccessControllerTest do
  use ExUnit.Case

  alias ExBanking.AccessController

  test "allow only 10 simultaneous operations" do
    result =
      1..15
      |> Task.async_stream(fn _ ->
        case AccessController.start_operation("lock") do
          {:ok, _} ->
            :timer.sleep(1)
            AccessController.finish_operation("lock")
            :ok

          {:error, _} ->
            :error
        end
      end)
      |> Enum.map(fn {_, x} -> x end)

    assert 10 ==
             result
             |> Enum.count(fn x -> x == :ok end)

    assert 5 ==
             result
             |> Enum.count(fn x -> x == :error end)
  end
end
