defmodule Genotype.Neuron do 
	defstruct id: nil, layer: 0, cortex_id: nil, activation_function: nil, input_ids: [], output_ids: [], vector_length: 1

	def create_neurolayers(cortex_id,sensors,actuators,layer_densities) do
		sensor_inputs = for s <-sensors, do: %{id: s.id, vector_length: s.vector_length}
		layer_count = length(layer_densities)
		[head_neurons|next_layers] = layer_densities
		neurons = for id <- Genotype.generate_ids(head_neurons,[]), do: %Genotype.Neuron{id: id, layer: 0, cortex_id: cortex_id, activation_function: :tanh }
		create_neurolayers(cortex_id,actuators,1,layer_count,sensor_inputs,neurons,next_layers,[])
	end

	def create_neurolayers(cortex_id, actuators, layer_index, layer_count, inputs, neurons, [current_layer|next_layers], acc) do
		outputs = for id <- Genotype.generate_ids(current_layer,[]), do: %Genotype.Neuron{id: id, layer: layer_index, cortex_id: cortex_id, activation_function: :tanh } 
		neuron_layer = create_neurolayer(cortex_id,inputs,neurons,outputs,[])
		next_inputs = for n <- neuron_layer, do: %{id: n.id,vector_length: 1}
		create_neurolayers(cortex_id,actuators,layer_index+1,layer_count,next_inputs,outputs,next_layers,[neuron_layer|acc])
	end

# Special case: that's the last iteration of the create_neurolayers recursion.
	def create_neurolayers(cortex_id,actuators,layer_count,layer_count,inputs,neurons,[],acc) do 
		outputs = for a <- actuators, do: %{id: a.id, vector_length: a.vector_length}
		neuron_layer = create_neurolayer(cortex_id,inputs,neurons,outputs,[])
		Enum.reverse([neuron_layer|acc])
	end

# Ensure that neurons gets correctly bound to inputs and outputs.
	def create_neurolayer(cortex_id,inputs,[n|neurons],outputs,acc) do
    inputs_ids = for i <- inputs, do: %{id: i.id, weight: generate_weight(i.vector_length)}
    outputs_ids = for o <- outputs, do: o.id
    # Adding biais to neuron :)
    inputs_ids = [%{id: :biais,weight: (:random.uniform() - 0.5)} | inputs_ids]
		neuron = %Genotype.Neuron{n| input_ids: inputs_ids, output_ids: outputs_ids}
		create_neurolayer(cortex_id, inputs, neurons, outputs, [neuron|acc])
	end

	def create_neurolayer(_cortex_id, _inputs, [], _outputs, acc) do 
		acc
	end

	def generate_weight(vector_length) do 
	  generate_weight(vector_length, [])
  end

  def generate_weight(0, acc), do: acc

  def generate_weight(vl, acc) do
    generate_weight(vl-1,[:random.uniform() - 0.5| acc])
  end
end

