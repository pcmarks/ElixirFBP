defmodule ElixirFBP.Subscription do
  @moduledoc """
  A Subscription serves as a conduit through which requests for data from
  Publishers (Components) are delivered to Subscribers (Components). A Subscriber
  must specify how many IPs it is willing to receive via a {:request, n} message
  where n is some number or the atom :infinity. The Subscription will not send
  any more IPs than have been asked for.

  When a subscriber asks for an infinite number of values via a {:request, :infinity}
  message, the Subscription effectively becoming a push flow without any back pressure.

  A Subscription is able to deal with multiple Publisher and/or Subscriber
  Component processes. Multiple Subscriber processes are handled in a round-robin
  manner.

  The design of this module is based largely on the work of the Reactive Stream
  project:  http://www.reactive-streams.org/
  """
  require Logger

  defstruct [
    publisher_pids: [], publisher_port: nil,
    subscriber_pids: {}, subscriber_pids_length: 0, subscriber_port: nil
  ]
  @doc """
  The new function doesn't do much except initialize a Subscription structure
  with values for the names of the publisher and subscriber ports that this
  subscription will connect to and manage. Also see the start() function below.
  """
  def new(publisher_port, subscriber_port) do
    %ElixirFBP.Subscription{
      publisher_pids: [],
      publisher_port: publisher_port,
      subscriber_pids: {},
      subscriber_pids_length: 0,
      subscriber_port: subscriber_port
    }
  end

  @doc """
  The start function does nothing more than spawn a Subscription process. The other
  values in the Subscription structure are initialized after the Components that
  are connected to this subscription have been started. See Component.start()
  """
  def start(inport, outport) do
    subscription = ElixirFBP.Subscription.new(inport, outport)
    spawn(fn -> loop(subscription,  0) end)
  end

  @doc """
  This function serves as a Subscriptions's main computational loop, dealing
  with requests for data from Subscribers and responses from Publishers. The
  subscriber_index points to the next subscriber that is to receive data.

  The subscriber and publisher processes are started with Component.start. after
  starting a component's process(es), the function sends lists of process pids
  as messages to this subscription process.
  """
  def loop(%ElixirFBP.Subscription{
              publisher_pids: publisher_pids,
              publisher_port: publisher_port,
              subscriber_pids: subscriber_pids,
              subscriber_pids_length: subscriber_pids_length,
              subscriber_port: subscriber_port} = subscription,
              subscriber_index) do
    receive do
      # The next two messages serve to update the processor pids for
      # the publisher and subscriber components. Notice that the publisher pids
      # are in a List while the subscriber pids are in a tuple. We use a tuple
      # so that we can efficiently send a value to nth subscriber process
      {:publisher_pids, publisher_pids} ->
        new_subscription = %{subscription | :publisher_pids => publisher_pids}
        loop(new_subscription, subscriber_index)
      {:subscriber_pids, subscriber_pids} ->
        new_subscription = %{subscription | :subscriber_pids => subscriber_pids,
                                            :subscriber_pids_length => tuple_size(subscriber_pids)}
        loop(new_subscription, subscriber_index)
      # A request for data from the subscriber but with no bounds;
      # Have the publishers send as much as they can to all the subscribers -
      # via this subscription.
      {:request, :infinity} ->
        Enum.each(publisher_pids, fn(publisher_pid) ->
          send(publisher_pid, publisher_port)
        end)
        loop(subscription, subscriber_index)
      # A request for data from the subscriber, but no more than n occurrences
      # Ask all the publishers for a data value
      {:request, n}  when n > 0 ->
        Stream.cycle(publisher_pids)
          |> Stream.take(n)
          |> Enum.each(fn(publisher_pid) ->
            send(publisher_pid, publisher_port)
          end)
        loop(subscription, subscriber_index)
      # Publisher has sent data - pass it on to the next subscriber
      {^publisher_port, value} ->
        send(elem(subscriber_pids, subscriber_index), {subscriber_port, value})
        loop(subscription, rem(subscriber_index + 1, subscriber_pids_length))
      message ->
        Logger.info("Received unknown message: #{inspect message}")
        loop(subscription, subscriber_index)
    end
  end
end
