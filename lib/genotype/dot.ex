defmodule Genotype.Dot do 
  # Will create a dot file in priv/dots/name.dot
  # With given items.
 def create(name, caller, opts \\ %{}) do 
    spawn_link(fn -> 
      dotdata = generate(name, opts)
      fname = name_to_filename(name, opts)
      File.write!(fname , dotdata)
      System.cmd("dot",["-Tpng", "-O", fname])
      send caller, :finished
    end)
 end

 def generate(name, opts) do 
 # generating header :) 
    {:ok, pid} = StringIO.open("")

    IO.write(pid, "digraph NN { \n")
    IO.write(pid, "subgraph ns {  label= \"Neurons\"; \n  ")
    neurons = for n <- Genotype.fetch_all(name, :neuron), do: generate_item(pid, {n.id, :neuron, n}, opts)
    IO.write(pid, " \n } \n subgraph ss {   label= \"Sensors\"; \n  ")
    sensors = for n <- Genotype.fetch_all(name, :sensor), do: generate_item(pid, {n.id, :sensor, n}, opts)
    IO.write(pid, " \n } \n subgraph as {   label= \"Actuators\"; \n ")
    actuators = for n <- Genotype.fetch_all(name, :actuator), do: generate_item(pid, {n.id, :actuator, n}, opts)
    IO.write(pid, " \n } \n ")
    #    for n <- Genotype.fetch_all(name, :cortex), do: generate_header(pid, n, opts)
    # reprocess neuron output to enforce layer display. [{ layer, id }|] = neurons
    layers = Enum.sort(Map.to_list(prepare_layers(neurons, %{})), fn({layer_1, _}, {layer_2,_}) ->
        layer_1 < layer_2
    end)

    # Write relationship between layers.
    [first_id | _ ]  = for {layer, _} <- layers do 
      IO.write(pid, "#{layer} -> ")
      layer
    end
    
    # Write relationship between last layer and actuators
    IO.write(pid, " Actuators; \n ")
    # Write relationship between first layer and sensors
    IO.write(pid, " Sensors -> #{first_id}; \n ")

    # Mark as same layer ...
    IO.write(pid, "{ \n rank=same; Sensors; ")
    for s <- sensors, do: IO.write(pid, " #{s}; ")
    IO.write(pid, " \n } \n { \n rank=same; Actuators; ")
    for a <- actuators, do: IO.write(pid, "#{a}; ")
    IO.write(pid, " \n } \n ")

    for {layer, ids} <- layers do 
      IO.write(pid, "{ \n rank=same; #{layer};")
        for i <- ids, do: IO.write(pid, "#{i}; ")
      IO.write(pid, " \n } \n")
    end

    IO.write(pid, " \n } \n ")
    {_, out} = StringIO.contents(pid)
    out
 end

 # this function will analyze neurons and sort them by layer
 # -> graph will display a ruler with layer indicated on it
 def prepare_layers([{layer, neuron_id} | rest], acc) do 
   acc = Map.put_new(acc, layer, [])
   prepare_layers(rest, Map.put(acc, layer, [neuron_id |acc[layer]])) 
 end

 def prepare_layers([], acc), do: acc

 def generate_item(pid, {id, :neuron, %Genotype.Neuron{ input_ids: inputs, activation_function: function, layer: layer} }  , _opts) do
  biais = for %{id: iid, weight: weight} <- inputs do
    if iid != :biais do
      IO.write(pid, "#{short_id(iid)} -> #{short_id(id)} [taillabel=\"#{inspect weight}\"]; \n")
      nil
    else
       weight 
    end
  end
  
  [biais] = Enum.reject(biais, fn(x) -> x == nil end)

  IO.write(pid, "#{short_id(id)} [label=\"#{short_id(id)} \n biais : #{biais} \n Function: #{function}\"]; \n")
  #  for oid <- outputs, do: IO.write(pid, "#{short_id(id)} -> #{short_id(oid)}; \n") 
  {layer, short_id(id)}
 end

 # sensor's
 # defstruct id: nil, cortex_id: nil, name: nil, vector_length: 0, fanout_ids: []
 def generate_item(pid, {id, :sensor, %Genotype.Sensor{ name: function} }  , _opts) do
  IO.write(pid, "#{short_id(id)} [label=\"sensor_#{short_id(id)}\n#{function}\", shape=box]; \n")
  short_id(id)
 end

 def generate_item(pid, {id, :actuator, %Genotype.Actuator{ fanin_ids: inputs} } , _opts) do
  IO.write(pid, "#{short_id(id)} [label=\"actuator_#{short_id(id)}\", shape=box]; \n")
  for i <- inputs, do: IO.write(pid, " #{short_id(i)} -> #{short_id(id)}; \n")
  short_id(id)
 end

 def short_id(id) do 
    "N#{String.slice(id, 0, 8)}"
 end


 defp name_to_filename(name, opts) do
   if not File.exists?("priv/dots/"), do: File.mkdir_p("priv/dots")
   if Map.size(opts) > 0 do 
     "priv/dots/#{name}.#{opts.generation}.#{opts.specie}"
   else
     "priv/dots/#{name}"
   end
 end
end
