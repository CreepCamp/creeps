defmodule Genotype do 
	def construct() do 
		construct([:rng], [:pts], [1,3])
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

		
		genotype = Poison.encode! %{cortex: cortex, sensors: sensors, actuators: actuators, neurons: neurons}
		File.write("#{filename}.json", genotype)
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
end

# at page 186