defmodule Phenotype.Cortex do 
	defstruct id: nil, sensor_ids: [], actuator_ids: [], neuron_ids: []
	use GenServer

	def start_link(phenotype_pid, id) do 
		GenServer.start_link(__MODULE__, [phenotype_pid, id], [name: String.to_atom("#{__MODULE__}_#{id}")])
	end

	def init([phenotype_pid, id] = opts) do 
		IO.puts "Initilizing #{__MODULE__}"
		Phenotype.init_cortex(phenotype_pid, self(), id)
		{:ok, opts}
	end	
end