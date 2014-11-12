defmodule Genotype.Cortex do 
	defstruct id: nil, sensor_ids: [], actuator_ids: [], neuron_ids: []

	def create do
		%Genotype.Cortex{id: %{type: :cortex, id: Genotype.generate_id}}
	end

end