defmodule ElixirFBP.Subscription do
  @moduledoc """
  A Subscription serves as a conduit through which requests for data from
  Publishers (Components) are delivered to Subscribers (Components). No more
  responses are delivered than have been asked for.
  A subscriber can ask for an infinite number of values via a {:pull, :infinity}
  message, effectively becoming a push flow without any back pressure.
  """
  require Logger

  defstruct [
    publisher_pids: [], publisher_port: nil,
    subscriber_pids: {}, subscriber_pids_length: 0, subscriber_port: nil
  ]

  def new(publisher_pids, publisher_port, subscriber_pids, subscriber_port) do
    %ElixirFBP.Subscription{
      publisher_pids: publisher_pids,
      publisher_port: publisher_port,
      subscriber_pids: List.to_tuple(subscriber_pids),
      subscriber_pids_length: length(subscriber_pids),
      subscriber_port: subscriber_port
    }
  end

  def start(%ElixirFBP.Subscription{} = subscription) do
    spawn(fn -> loop(subscription,  0) end)
  end
  @doc """
  This function serves as the main computational loop, dealing with requests
  for data from Subscribers and responses from Publishers. The subscriber_index
  points to the next subscriber that is to receive data.
  """
  def loop(%ElixirFBP.Subscription{
              publisher_pids: publisher_pids,
              publisher_port: publisher_port,
              subscriber_pids: subscriber_pids,
              subscriber_pids_length: subscriber_pids_length,
              subscriber_port: subscriber_port} = subscription,
              subscriber_index) do
    receive do
      {:pull, :infinity} ->
        # A request for data from the subscriber but with no bounds;
        # Have the publishers send as much as they can to all the subscribers -
        # via this subscription.
        Enum.each(publisher_pids, fn(publisher_pid) ->
          send(publisher_pid, {publisher_port, self()})
        end)
        loop(subscription, subscriber_index)
      {:pull, n}  when n > 0 ->
        # A request for data from the subscriber, but no more than n occurrences
        # Ask all the publishers for a data value
        Stream.cycle(publisher_pids)
          |> Stream.take(n)
          |> Enum.each(fn(publisher_pid) ->
            send(publisher_pid, {publisher_port, self()})
          end)
        loop(subscription, subscriber_index)
      {^publisher_port, value} ->
        # Publisher has sent data - pass it on to the next subscriber
        send(elem(subscriber_pids, subscriber_index), {subscriber_port, value})
        loop(subscription, rem(subscriber_index + 1, subscriber_pids_length))
      message ->
        Logger.info("Received unknown message: #{inspect message}")
        loop(subscription, subscriber_index)
    end
  end
end