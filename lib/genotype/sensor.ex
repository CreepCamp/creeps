defmodule Genotype.Sensor do 
	defstruct id: nil, cortex_id: nil, name: nil, vector_length: 0, fanout_ids: []

	def create(name) do 
		case name do 
			:rng ->
				%Genotype.Sensor{id: %{type: :sensor, id: Genotype.generate_id()}, name: name, vector_length: 2}
			_ ->
				exit "System doesn't support that kind of Sensor named #{name}"
		end	
	end
end
