defmodule ExBanking.AccessController do
  @moduledoc """
  This module implements the access control solution to the system. It limits
  the number of simultaneous operations for each user by 10.
  """

  use GenServer

  @server_name :access_control
  @max_counter 10

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: @server_name)
  end

  def start_operation(user) do
    GenServer.call(@server_name, {:start_operation, user}, 1000)
  end

  def finish_operation(user) do
    GenServer.call(@server_name, {:finish_operation, user}, 1000)
  end

  @impl true
  def init(stack) do
    {:ok, stack}
  end

  @impl true
  def handle_call({:start_operation, user}, _from, state) do
    old_counter = Map.get(state, user, 0)
    new_counter = old_counter + 1

    if old_counter >= @max_counter do
      {:reply, {:error, old_counter}, state}
    else
      {:reply, {:ok, new_counter}, Map.put(state, user, new_counter)}
    end
  end

  @impl true
  def handle_call({:finish_operation, user}, _from, state) do
    old_counter = Map.get(state, user)
    new_counter = old_counter - 1

    if old_counter > 0 do
      {:reply, {:ok, new_counter}, Map.put(state, user, new_counter)}
    else
      {:reply, {:ok, 0}, Map.put(state, user, 0)}
    end
  end
end
