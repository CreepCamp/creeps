defmodule Genotype do 
	def construct() do 
		construct([:rng], [:pts], [1,3])
	end

  def construct(filename) do 
    construct(filename, [:rng], [:pts], [1,3])
  end

	def construct(sensors, actuators, hidden_layer_densities) do
		construct(:ffnn, sensors, actuators, hidden_layer_densities)
	end

	def construct(filename, sensors, actuators, hidden_layer_densities) do 
		sensors = for s <- sensors, do: Genotype.Sensor.create s
		actuators = for a <- actuators, do: Genotype.Actuator.create a
		
		{_, output_vector_length} = Enum.map_reduce(actuators, 0, fn(actuator, acc) -> {0, acc + actuator.vector_length} end)
		layer_densities = Enum.concat(hidden_layer_densities, [output_vector_length])
		cortex = Genotype.Cortex.create

		neurons = Genotype.Neuron.create_neurolayers(cortex.id, sensors,actuators,layer_densities)
		[input_layer | _] = neurons
		output_layer = List.last(neurons) 
		input_layer_neuron_ids = for n <- input_layer, do: n.id
		output_layer_neuron_ids = for n <- output_layer, do: n.id
		neuron_ids = for n <- List.flatten(neurons), do: n.id 
		sensors = for s <- sensors, do: %Genotype.Sensor{s| cortex_id: cortex.id, fanout_ids: input_layer_neuron_ids}
		actuators = for a <- actuators, do: %Genotype.Actuator{a| cortex_id: cortex.id, fanin_ids: output_layer_neuron_ids}
		cortex = %Genotype.Cortex{cortex| sensor_ids: (for s <- sensors, do: s.id ), actuator_ids: (for a <- actuators, do: a.id ), neuron_ids: neuron_ids}

		
		save(filename, %{cortex: cortex, sensors: sensors, actuators: actuators, neurons: List.flatten(neurons)} )
	end

	def generate_id do 
		UUID.uuid4()
	end

	def generate_ids(0,acc) do 
		acc
	end

	def generate_ids(index,acc) do 
		id = generate_id()
		generate_ids(index-1,[id|acc])
	end

  def save(name, genotype) do 
    load(name)
    # Genotype is a Map %{neurons: [], cortex:%, sensors: [], actuators: []
    for n <- genotype.neurons, do: :ets.insert(name, {n.id,:neuron, n})
    for a <- genotype.actuators, do: :ets.insert(name, {a.id,:actuator,a })
    for s <- genotype.sensors, do: :ets.insert(name, {s.id,:sensor, s})
    :ets.insert(name, {genotype.cortex.id,:cortex, genotype.cortex})
    to_file(name)
  end

  def load(name) do 
    if :ets.info(name) == :undefined do
      if  File.exists?(name_to_filename(name)) do
        {:ok,pid} = :ets.file2tab(name)
      else
        :ets.new(name, [:named_table, :public,:set])
        to_file(name)
      end
    end
  end

  def to_file(name) do 
    :ets.tab2file(name,name_to_filename(name))
  end

  def fetch(name, id) do
    [value|_] = :ets.lookup(name,id) 
    value
  end

  # This one is a new one for me ;)
  # What it actually means is, search for type element in my :ets
  # and give them back.
  def fetch_all(name, type) do 
    List.flatten( :ets.match(name, {:'_', type, :'$1'}))
  end

  def insert(name, id, type ,value) do 
    :ets.insert(name, {id, type, value})
  end

  def clean(name) do 
   if :ets.info(name) != :undefined, do: :ets.delete(name)
   File.rm(name_to_filename(name))
  end

  def name_to_filename(name) do 
    if not File.exists?("priv/genotypes/"), do: File.mkdir_p("/priv/genotypes")
    "priv/genotypes/#{name}.ets"
  end

  def to_dot(name) do 

    Genotype.Dot.create(name, self())
  end

end

# at page 186
