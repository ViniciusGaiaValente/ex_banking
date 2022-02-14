defmodule ExBanking.RepoTest do
  use ExUnit.Case

  alias ExBanking.Repo

  setup do
    Repo.clear_db()
    {:ok, []}
  end

  test "save and retrieve data correctly" do
    Repo.put_data("foo", "bar")
    assert Repo.get_data("foo") == [{"foo", "bar"}]
  end

  test "get_data/1 returns an empty list for unexistent data" do
    assert Repo.get_data("baz") == []
  end
end
