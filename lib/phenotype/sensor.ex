defmodule Phenotype.Sensor do 
	defstruct id: nil, cortex_pid: nil, name: nil, vector_length: 0, fanout_pids: [], sim_pid: nil
	use GenServer

	def start_link(sensor, cortex_pid) do 
		GenServer.start_link(__MODULE__,[sensor, cortex_pid], [])
	end

	def init([sensor, cortex_pid]) do 
		state = %Phenotype.Sensor{id: sensor.id, cortex_pid: cortex_pid, name: (sensor.name), vector_length: sensor.vector_length}
    # IO.puts "Initilizing #{__MODULE__} #{state.id} #{inspect self()}"
		{:ok, state}
	end

	def update(pid, fanouts, sim_pid) do 
		GenServer.cast(pid, {:update, fanouts, sim_pid})
	end

  def sense(pid) do 
    GenServer.cast(pid,:sense)
  end

  def terminate(pid) do 
    GenServer.cast(pid, :terminate)
  end

  def handle_cast(:terminate, state) do
    IO.puts "#{__MODULE__} #{state.id} Imposed termination"
    {:stop, :normal, state}
  end

	def handle_cast({:update, fanouts, sim_pid}, state) do 
		{:noreply, %Phenotype.Sensor{state|fanout_pids: fanouts, sim_pid: sim_pid}}
	end

  def handle_cast(:sense, state) do 
  # IO.puts "Sensor got a call from cortex ! pushing to #{length state.fanout_pids} neurons"
    for pid <- state.fanout_pids do 
      # as we don't know where it will go to ( it could very well directly go to an actuator ... )
      # But as Elixir is somewhat open ...
      
      # Scape ensure that we have someone over there :) 
      {:percept, data} = GenServer.call(state.sim_pid, :sense)
      Phenotype.Neuron.forward(pid, data , self())
      # Be it an actuator or a neuron it will work, as both will receive the same message.
    end
    {:noreply, state}
  end
end
