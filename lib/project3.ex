defmodule Project3 do
  use GenServer

  def start_link(nodeCount, requestCount, nodesStarted, requestsCompleted, maxHops) do
    GenServer.start_link(Project3, [nodeCount, requestCount, nodesStarted, requestsCompleted, maxHops])
  end

  def init([nodeCount, requestCount, nodesStarted, requestsCompleted, maxHops]) do
    {:ok, {nodeCount, [], requestCount, nodesStarted, requestsCompleted, maxHops}}
  end

  def genNodeList(nodeCount) do
    list = Enum.reduce(1..nodeCount,[], fn x,acc ->
      nodeId = :crypto.hash(:sha, "#{x}") |> Base.encode16 |> String.slice(0..7)
      acc = [nodeId|acc]
    end)

  end

  def handle_cast(:startNodes, state) do
    {nodeCount, _, requestCount, nodesStarted, requestsCompleted, maxHops} = state
    nodeList = genNodeList nodeCount

    pidList = for nodeID <- nodeList do
      {_, pid} = TapestryNode.startLink(nodeID, nodeCount)
      pid
    end

    for pid <- pidList do
      GenServer.cast(pid, {:initializeNode, nodeList})
    end
    {:noreply, {nodeCount, nodeList, requestCount, nodesStarted, requestsCompleted, maxHops}}
  end

  def handle_cast(:completeInitialization, state) do
    {nodeCount, nodeList, requestCount, nodesStarted, requestsCompleted, maxHops} = state
    nodesStarted = nodesStarted + 1

    if(nodesStarted >= nodeCount) do
      for node <- nodeList do
          GenServer.cast(String.to_atom("Node"<>node), {:startHopping, requestCount, nodeList})
      end
    end

    {:noreply, {nodeCount, nodeList, requestCount, nodesStarted, requestsCompleted, maxHops}}
  end

  def handle_cast({:countMax, hops}, state) do
    {nodeCount, nodeList, requestCount, nodesStarted, requestsCompleted, maxHops} = state
    requestsCompleted = requestsCompleted + 1
    maxHops = if (hops > maxHops) do
                hops
              else
                maxHops
              end
    #IO.puts "hops: #{hops} maxHops: #{maxHops} Requests received: #{requestsCompleted} requestCount: #{requestCount} nodeCount: #{nodeCount}"
    if (requestsCompleted >= requestCount * nodeCount) do
      IO.puts "#{maxHops}"
      System.halt()
    end
    {:noreply, {nodeCount, nodeList, requestCount, nodesStarted, requestsCompleted, maxHops}}
  end

  def main(nodeCount, requestCount) do
    #[nodeCount, requestCount] = args
    nodeCount = String.to_integer(nodeCount)
    requestCount = String.to_integer(requestCount)
    {:ok, pid} = start_link(nodeCount, requestCount, 0, 0, 0)
    :global.register_name(:root, pid)
    GenServer.cast(:global.whereis_name(:root), :startNodes)
     :timer.sleep(:infinity)
  end
end
