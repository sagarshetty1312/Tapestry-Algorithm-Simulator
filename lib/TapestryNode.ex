defmodule TapestryNode do
  use GenServer

  def startLink(node_id, nodeCount) do
    GenServer.start_link(TapestryNode, [node_id, nodeCount], name: String.to_atom("Node"<>node_id))
  end

  def init([node_id, nodeCount]) do
    routingTableMap = Enum.reduce(1..8, %{}, fn (x,acc) -> acc = Map.put(acc,x,[]) end)
    {:ok, {node_id, nodeCount, routingTableMap}}
  end

  def handle_cast({:initializeNode, nodeList}, state) do
    {currNodeId, nodeCount, routingTableMap} = state
    routingTableMap = addTableEntries(currNodeId, nodeList, routingTableMap)
    GenServer.cast(:global.whereis_name(:root), :completeInitialization)
    {:noreply, {currNodeId, nodeCount, routingTableMap}}
  end

  def handle_cast({:startHopping, requestCount, nodeList}, state) do
    {currNodeId, nodeCount, routingTableMap} = state
    for _i <- 1..requestCount do
      sourceNode = Enum.random(List.delete(nodeList,currNodeId))
      GenServer.cast(String.to_atom("Node"<>currNodeId), {:completeRequest, sourceNode, currNodeId})
    end
    {:noreply, {currNodeId, nodeCount, routingTableMap}}
  end

  def handle_cast({:completeRequest, sourceNode, destNode}, state) do
    {currNodeId, nodeCount, routingTableMap} = state
    level = noOfDigitsMatching(sourceNode, destNode, 1)
    hops = countHops(destNode, routingTableMap, level, 0) - 1
      GenServer.cast(:global.whereis_name(:root), {:countMax, hops+1})
    {:noreply, {currNodeId, nodeCount, routingTableMap}}
  end

  def noOfDigitsMatching(n1, n2, bit_pos) do
    if String.first(n1) != String.first(n2) do
      bit_pos
    else
      noOfDigitsMatching(String.slice(n1, 1..(String.length(n1)-1)), String.slice(n2, 1..(String.length(n2)-1)), bit_pos+1)
    end
  end

  def addTableEntries(currNodeId, nodeList, routingTableMap) do
    listLength = length nodeList
    if listLength == 0 do
      routingTableMap
    else
      nodeList = List.delete(nodeList,currNodeId)
      level = noOfDigitsMatching currNodeId, List.first(nodeList), 1
      list = Map.get(routingTableMap,level)
      newMap = Map.put(routingTableMap, level, [List.first(nodeList)|list])
      addTableEntries(currNodeId,List.delete_at(nodeList,0),newMap)
    end
  end

  def countHops(destNode, routingTableMap, level, hops) do
    if(level > 8) do
      hops
    else
      hops = hops + 1
      level = getNextLevel(level, routingTableMap)
      if(level == 9) do
        hops
      else
        #listInLevel = Map.get(routingTableMap, level)
        #nextNode = Enum.random(listInLevel)
        countHops(destNode, routingTableMap, level+1, hops)
      end
    end
  end

  def getNextLevel(level, routingTableMap) do
    if level <= 8 do
      elemInLevel = Map.get(routingTableMap, level) |> length
      if elemInLevel == 0 do
        getNextLevel(level+1, routingTableMap)
      else
        level
      end
    else
      9
    end
  end
end
