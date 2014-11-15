defmodule Phenotype.Neuron do 
	defstruct id: nil, layer: 0, cortex_pid: nil, activation_function: nil, input_pids: [], output_pids: []
	use GenServer

	def start_link(opts) do 
		GenServer.start_link(__MODULE__, opts, [])
	end

	def init([neuron, cortex_pid]) do 
		IO.puts "Initilizing #{__MODULE__}"
		state = %Phenotype.Neuron{id: neuron.id.id, layer: neuron.layer, cortex_pid: cortex_pid, activation_function: String.to_atom(neuron.activation_function)}
		{:ok, state}
	end

	def update(pid, inputs, outputs) do 
		GenServer.cast(pid, {:update, inputs, outputs})
	end

	def handle_cast({:update, inputs, outputs}, state) do 
		{:noreply, %Phenotype.Neuron{state| input_pids: inputs, output_pids: outputs}}
	end
end
