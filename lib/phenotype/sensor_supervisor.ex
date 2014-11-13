defmodule Phenotype.Sensor.Supervisor do 
	use Supervisor

	def start_link(id) do 
		Supervisor.start_link(__MODULE__, :ok, [name: String.to_atom("#{__MODULE__}_#{id}")])
	end

	def init(:ok) do
		IO.puts "Initialized #{__MODULE__}"
		children = [
			worker(Phenotype.Sensor, [], restart: :transient)
		]

		supervise(children, strategy: :simple_one_for_one)
	end

	def start_child(pid, opts) do 
		Supervisor.start_child(pid, opts)
	end
end