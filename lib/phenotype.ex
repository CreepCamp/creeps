defmodule Phenotype do
	use GenServer

	def start_link(opts) do 
		GenServer.start_link(__MODULE__, opts, [])
	end

	def init(opts) do 
		IO.puts "Initilizing #{__MODULE__}"

		GenServer.cast(self(),{:init, opts.filename})
		{:ok, opts}
	end

	def init_cortex(pid, cortex_pid, id) do 
		GenServer.cast(pid, {:init_cortex, cortex_pid, id})
	end

	def handle_cast({:init, id}, state) do 
		Phenotype.Supervisor.start_link(self(), id)
		{:noreply, state}
	end

	def handle_cast({:init_cortex, cortex_pid, id}, state) do 
		asup = Process.whereis(String.to_atom("Elixir.Phenotype.Actuator.Supervisor_#{id}"))
		ssup = Process.whereis(String.to_atom("Elixir.Phenotype.Sensor.Supervisor_#{id}"))
		nsup = Process.whereis(String.to_atom("Elixir.Phenotype.Neuron.Supervisor_#{id}"))
		IO.puts "Cortex fired, #{inspect asup} #{inspect ssup} #{inspect nsup}"
		{:noreply, state}
	end
end