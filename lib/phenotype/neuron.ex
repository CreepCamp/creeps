defmodule Phenotype.Neuron do 
	defstruct id: nil, layer: 0, cortex_id: nil, activation_function: nil, input_ids: [], output_ids: []
	use GenServer

	def start_link(opts) do 
		GenServer.start_link(__MODULE__, opts, [])
	end

	def init(opts) do 
		IO.puts "Initilizing #{__MODULE__}"
		{:ok, opts}
	end
end
