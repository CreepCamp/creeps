defmodule Genotype do 
	def construct(sensor_name, actuator_name, hidden_layer_densities) do
		construct(:ffnn, sensor_name, actuator_name, hidden_layer_densities)
	end

	def construct(filename, sensor_name, actuator_name, hidden_layer_densities) do 
		s = Genotype.Sensor.create sensor_name
		a = Genotype.Actuator.create actuator_name
		output_vector_length = a.vector_length
		layer_densities = List.append(hidden_layer_densities, [output_vector_length])
		cortex = Genotype.Cortex.create

		neurons = Genotype.Neuron.create_layers(cortex_id, s,a,layer_densities)
		[input_layer | _] = neurons
		output_layer = List.last(neurons) 
		input_layer_neuron_ids = for n <- input_layer, do: n.id
		output_layer_neuron_ids = for n <- output_layer, do: n.id
		neuron_ids = for n <- List.flatten(neurons), do: n.id 
		%Genotype.Sensor{s| cortex_id: cortex_id, fanout_ids: input_layer_neuron_ids}
		%Genotype.Actuator{a| cortex: id, fanin_ids: output_layer_neuron_ids}
		%Genotype.Cortex{cortex| sensor_ids: [s.id], actuator_ids: [a.id], neuron_ids: neuron_ids}

		{:ok, file} = File.open(filename, :write)
		genotype = List.flatten [cortex, s, a | neurons]
		for item <- genotype do 
			File.write "#{inspect item}"
		end
		File.close(file)
	end
end

# at page 186