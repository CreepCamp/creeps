defmodule Genotype.Actuator do 
	defstruct id: nil, cortex_id: nil, name: nil, vector_length: 0, fanin_ids: []

		def create(name) do 
		case name do 
			:pts ->
				%Genotype.Actuator{id: %{type: :actuator, id: Genotype.generate_id()}, name: name, vector_length: 1}
			_ ->
				exit "System doesn't support that kind of Actuator named #{name}"
		end	
	end
end