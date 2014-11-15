defmodule Phenotype.Actuator do 
	defstruct id: nil, cortex_pid: nil, name: nil, vector_length: 0, fanin_pids: []
	use GenServer

	def start_link(opts) do 
		GenServer.start_link(__MODULE__, opts, [])
	end

	def init([actuator, cortex_pid]) do 
		IO.puts "Initilizing #{__MODULE__}"
		state = %Phenotype.Actuator{id: actuator.id.id, cortex_pid: cortex_pid, name: actuator.name, vector_length: actuator.vector_length }
		{:ok, state}
	end

	def update(pid, fanins) do 
		GenServer.cast(pid, {:update, fanins})
	end

	def handle_cast({:update, fanins}, state) do 
		{:noreply, %Phenotype.Actuator{state| fanin_pids: fanins}}
	end
end