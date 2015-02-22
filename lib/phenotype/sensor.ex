defmodule Phenotype.Sensor do 
	defstruct id: nil, cortex_pid: nil, name: nil, vector_length: 0, fanout_pids: []
	use GenServer

	def start_link(sensor, cortex_pid) do 
		GenServer.start_link(__MODULE__,[sensor, cortex_pid], [])
	end

	def init([sensor, cortex_pid]) do 
		state = %Phenotype.Sensor{id: sensor.id, cortex_pid: cortex_pid, name: String.to_atom(sensor.name), vector_length: sensor.vector_length}
		IO.puts "Initilizing #{__MODULE__} #{state.id} #{inspect self()}"
		{:ok, state}
	end

	def update(pid, fanouts) do 
		GenServer.cast(pid, {:update, fanouts})
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

	def handle_cast({:update, fanouts}, state) do 
		{:noreply, %Phenotype.Sensor{state|fanout_pids: fanouts}}
	end

  def handle_cast(:sense, state) do 
    for pid <- state.fanout_pids do 
      # as we don't know where it will go to ( it could very well directly go to an actuator ... )
      # But as Elixir is somewhat open ...
      # Ah, also note that we dynamically call a function with apply :)
      # Although there is only one function thus callable so far :) 
      
      Phenotype.Neuron.forward(pid, apply(__MODULE__, state.name,[state.vector_length]) , self())
      # Be it an actuator or a neuron it will work, as both will receive the same message.
    end
    {:noreply, state}
  end


  # Create a vector of given length with random number inside.
  def rng(vector_length) do
    rng(vector_length, [])
  end

  def rng(0, acc) do
    acc
  end
  
  def rng(v, acc) do
    rng(v-1, [:random.uniform() | acc])
  end

end
