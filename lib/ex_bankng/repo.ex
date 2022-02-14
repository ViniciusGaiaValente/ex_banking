defmodule ExBanking.Repo do
  @moduledoc """
  This module implements the application repository. It uses the ":ets" Erlang's
  module as an in-memory solution to store data.
  """

  @table_name :users

  @spec start_db() :: atom()
  def start_db() do
    :ets.new(@table_name, [
      :set,
      :public,
      :named_table,
      read_concurrency: false,
      write_concurrency: false
    ])
  end

  @spec get_data(any) :: [tuple]
  def get_data(key) do
    :ets.lookup(@table_name, key)
  end

  @spec put_data(any, any) :: true
  def put_data(key, value) do
    :ets.insert(@table_name, {key, value})
  end

  @spec clear_db :: true
  def clear_db do
    :ets.delete_all_objects(:users)
  end
end
